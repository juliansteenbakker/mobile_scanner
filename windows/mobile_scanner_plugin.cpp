#include "mobile_scanner_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/event_stream_handler_functions.h>
#include <flutter/standard_method_codec.h>
#include <mfapi.h>

#include <algorithm>
#include <cstring>
#include <utility>

#include "image_utils.h"

namespace mobile_scanner {

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

constexpr char kMethodChannelName[] =
    "dev.steenbakker.mobile_scanner/scanner/method";
constexpr char kEventChannelName[] =
    "dev.steenbakker.mobile_scanner/scanner/event";
constexpr char kDeviceOrientationChannelName[] =
    "dev.steenbakker.mobile_scanner/scanner/deviceOrientation";

// Error codes, kept in sync with MobileScannerErrorCodes.swift / .kt and
// MobileScannerErrorCode.fromPlatformException in Dart.
constexpr char kAlreadyStartedError[] = "MOBILE_SCANNER_ALREADY_STARTED_ERROR";
constexpr char kBarcodeError[] = "MOBILE_SCANNER_BARCODE_ERROR";
constexpr char kCameraError[] = "MOBILE_SCANNER_CAMERA_ERROR";
constexpr char kGenericError[] = "MOBILE_SCANNER_GENERIC_ERROR";
constexpr char kNoCameraError[] = "MOBILE_SCANNER_NO_CAMERA_ERROR";
constexpr char kPermissionDeniedError[] =
    "MOBILE_SCANNER_CAMERA_PERMISSION_DENIED";
constexpr char kUnsupportedOperationError[] =
    "MOBILE_SCANNER_UNSUPPORTED_OPERATION";

// `MobileScannerAuthorizationState.authorized`. Windows has no runtime camera
// permission prompt; access is controlled by the system privacy settings and
// surfaces as E_ACCESSDENIED when opening the camera.
constexpr int32_t kAuthorizationStateAuthorized = 1;

// `DetectionSpeed.rawValue` values.
constexpr int kDetectionSpeedNoDuplicates = 0;
constexpr int kDetectionSpeedNormal = 1;

// Camera frames are scanned many times per second, so a 1D barcode must be
// found on more scan lines than zxing-cpp's default of 2 before it is
// accepted. Otherwise noise and textures (like wood grain) occasionally
// produce spurious results. Real barcodes span many lines, so this does not
// make them harder to scan.
constexpr int kLiveMinLineCount = 3;

// `CameraLensType.normal`.
constexpr int32_t kCameraLensTypeNormal = 0;

// `TorchState.unavailable`.
constexpr int32_t kTorchStateUnavailable = -1;

const EncodableValue* GetArg(const EncodableMap* args, const char* key) {
  if (args == nullptr) {
    return nullptr;
  }
  auto it = args->find(EncodableValue(key));
  if (it == args->end() || it->second.IsNull()) {
    return nullptr;
  }
  return &it->second;
}

std::optional<int64_t> GetIntArg(const EncodableMap* args, const char* key) {
  const EncodableValue* value = GetArg(args, key);
  if (value == nullptr || !(std::holds_alternative<int32_t>(*value) ||
                            std::holds_alternative<int64_t>(*value))) {
    return std::nullopt;
  }
  return value->LongValue();
}

std::vector<int32_t> GetFormatsArg(const EncodableMap* args) {
  std::vector<int32_t> formats;
  const EncodableValue* value = GetArg(args, "formats");
  if (value == nullptr) {
    return formats;
  }
  if (const auto* list = std::get_if<EncodableList>(value)) {
    for (const EncodableValue& format : *list) {
      if (std::holds_alternative<int32_t>(format) ||
          std::holds_alternative<int64_t>(format)) {
        formats.push_back(static_cast<int32_t>(format.LongValue()));
      }
    }
  }
  return formats;
}

std::wstring Utf8ToWide(const std::string& utf8) {
  if (utf8.empty()) {
    return std::wstring();
  }
  const int length = MultiByteToWideChar(CP_UTF8, 0, utf8.data(),
                                         static_cast<int>(utf8.size()),
                                         nullptr, 0);
  std::wstring wide(length, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, utf8.data(), static_cast<int>(utf8.size()),
                      wide.data(), length);
  return wide;
}

// Mirrors the corners of the given barcodes horizontally, to match a mirrored
// preview.
void MirrorBarcodes(EncodableList& barcodes, int image_width) {
  for (EncodableValue& barcode : barcodes) {
    auto& map = std::get<EncodableMap>(barcode);
    auto& corners = std::get<EncodableList>(map[EncodableValue("corners")]);
    for (EncodableValue& corner : corners) {
      auto& x = std::get<double>(
          std::get<EncodableMap>(corner)[EncodableValue("x")]);
      x = image_width - x;
    }
    // Mirroring swaps left and right, so reorder the corners to keep them
    // clockwise from the top-left corner in screen space. The overlay relies
    // on corners[0] -> corners[1] pointing left to right.
    if (corners.size() == 4) {
      std::swap(corners[0], corners[1]);
      std::swap(corners[2], corners[3]);
    }
  }
}

}  // namespace

// static
void MobileScannerPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  registrar->AddPlugin(std::make_unique<MobileScannerPlugin>(registrar));
}

MobileScannerPlugin::MobileScannerPlugin(
    flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar),
      texture_registrar_(registrar->texture_registrar()) {
  MFStartup(MF_VERSION);

  scan_worker_ = std::make_unique<WorkerThread>();
  analyze_worker_ = std::make_unique<WorkerThread>();

  task_message_ = RegisterWindowMessage(L"MobileScannerPluginTask");
  window_proc_delegate_id_ = registrar_->RegisterTopLevelWindowProcDelegate(
      [this](HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
        return HandleWindowProc(hwnd, message, wparam, lparam);
      });

  const auto& codec = flutter::StandardMethodCodec::GetInstance();

  method_channel_ =
      std::make_unique<flutter::MethodChannel<EncodableValue>>(
          registrar->messenger(), kMethodChannelName, &codec);
  method_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        HandleMethodCall(call, std::move(result));
      });

  event_channel_ = std::make_unique<flutter::EventChannel<EncodableValue>>(
      registrar->messenger(), kEventChannelName, &codec);
  event_channel_->SetStreamHandler(
      std::make_unique<flutter::StreamHandlerFunctions<EncodableValue>>(
          [this](const EncodableValue*,
                 std::unique_ptr<flutter::EventSink<EncodableValue>>&& events)
              -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> {
            event_sink_ = std::move(events);
            return nullptr;
          },
          [this](const EncodableValue*)
              -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> {
            event_sink_ = nullptr;
            return nullptr;
          }));

  // Desktop windows do not rotate, so this stream never emits. It is still
  // registered so that listening to it does not fail.
  device_orientation_channel_ =
      std::make_unique<flutter::EventChannel<EncodableValue>>(
          registrar->messenger(), kDeviceOrientationChannelName, &codec);
  device_orientation_channel_->SetStreamHandler(
      std::make_unique<flutter::StreamHandlerFunctions<EncodableValue>>(
          [](const EncodableValue*,
             std::unique_ptr<flutter::EventSink<EncodableValue>>&&)
              -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> {
            return nullptr;
          },
          [](const EncodableValue*)
              -> std::unique_ptr<flutter::StreamHandlerError<EncodableValue>> {
            return nullptr;
          }));
}

MobileScannerPlugin::~MobileScannerPlugin() {
  // Stop the threads that call back into the plugin before tearing down.
  StopCapture();
  scan_worker_ = nullptr;
  analyze_worker_ = nullptr;
  UnregisterTexture();
  registrar_->UnregisterTopLevelWindowProcDelegate(window_proc_delegate_id_);
  MFShutdown();
}

void MobileScannerPlugin::HandleMethodCall(
    const flutter::MethodCall<EncodableValue>& method_call,
    MethodResult result) {
  const std::string& method = method_call.method_name();
  const auto* args = std::get_if<EncodableMap>(method_call.arguments());

  if (method == "state") {
    result->Success(EncodableValue(kAuthorizationStateAuthorized));
  } else if (method == "request") {
    result->Success(EncodableValue(true));
  } else if (method == "start") {
    Start(args, std::move(result));
  } else if (method == "stop") {
    Stop(std::move(result));
  } else if (method == "pause") {
    Pause(std::move(result));
  } else if (method == "toggleTorch") {
    // Webcams have no torch; `start` reports the torch as unavailable.
    result->Success();
  } else if (method == "setScale" || method == "resetScale") {
    // TODO: Support zoom through IAMCameraControl (CameraControl_Zoom) on
    // cameras that expose it.
    result->Error(kUnsupportedOperationError,
                  "Zooming is not supported on Windows.");
  } else if (method == "updateScanWindow") {
    UpdateScanWindow(args, std::move(result));
  } else if (method == "analyzeImage") {
    AnalyzeImage(args, std::move(result));
  } else if (method == "getSupportedLenses" ||
             method == "getBestCloseRangeScanningLens") {
    // Like on macOS, webcams have no lens types and the facing filter is
    // ignored: every camera is reported as a normal lens.
    const bool has_camera = !EnumerateCameras().empty();
    if (method == "getSupportedLenses") {
      result->Success(EncodableValue(
          has_camera ? EncodableList{EncodableValue(kCameraLensTypeNormal)}
                     : EncodableList()));
    } else if (has_camera) {
      result->Success(EncodableValue(kCameraLensTypeNormal));
    } else {
      result->Success();
    }
  } else {
    // Includes `setFocus`, which the Dart side does not call on Windows.
    result->NotImplemented();
  }
}

void MobileScannerPlugin::Start(const EncodableMap* args,
                                MethodResult result) {
  // While paused, the capture is stopped but the texture is kept, so starting
  // again resumes into the same texture.
  if (capture_) {
    result->Error(kAlreadyStartedError, "The scanner was already started.");
    return;
  }

  {
    std::lock_guard<std::mutex> lock(scan_mutex_);
    decoder_.SetFormats(GetFormatsArg(args));
    decoder_.SetMinLineCount(kLiveMinLineCount);
    detection_speed_ = static_cast<int>(
        GetIntArg(args, "speed").value_or(kDetectionSpeedNormal));
    detection_timeout_ms_ =
        static_cast<int>(GetIntArg(args, "timeout").value_or(250));
    const EncodableValue* return_image = GetArg(args, "returnImage");
    return_image_ = return_image != nullptr &&
                    std::holds_alternative<bool>(*return_image) &&
                    std::get<bool>(*return_image);
    paused_ = false;
    last_scanned_values_.clear();
    last_scan_time_ = {};
  }

  const std::vector<CameraDevice> cameras = EnumerateCameras();
  if (cameras.empty()) {
    result->Error(kNoCameraError, "No cameras available.");
    return;
  }

  // Use the first camera with the requested facing. Most desktops only have
  // a front facing or external camera, so fall back to the first camera
  // rather than failing when the default (back) is requested.
  const int requested_facing =
      static_cast<int>(GetIntArg(args, "facing").value_or(kCameraFacingBack));
  const auto camera =
      std::find_if(cameras.begin(), cameras.end(), [&](const auto& device) {
        return device.facing == requested_facing;
      });
  const CameraDevice& device = camera != cameras.end() ? *camera : cameras[0];
  mirror_ = device.facing == kCameraFacingFront;

  std::optional<std::pair<int, int>> resolution;
  if (const EncodableValue* value = GetArg(args, "cameraResolution")) {
    if (const auto* size = std::get_if<EncodableList>(value);
        size != nullptr && size->size() == 2) {
      resolution = std::make_pair(static_cast<int>((*size)[0].LongValue()),
                                  static_cast<int>((*size)[1].LongValue()));
    }
  }

  // The result is completed from OnCaptureStarted. std::function requires a
  // copyable callable, so it is shared rather than moved into the callback.
  std::shared_ptr<flutter::MethodResult<EncodableValue>> shared_result =
      std::move(result);
  const int generation = ++start_generation_;
  const int number_of_cameras = static_cast<int>(cameras.size());
  const int camera_direction = device.facing;

  capture_ = std::make_unique<CameraCapture>();
  capture_->Start(
      device.symbolic_link, resolution,
      [this, generation, shared_result, number_of_cameras, camera_direction](
          HRESULT hr, int width, int height) {
        PostToPlatformThread([=]() {
          OnCaptureStarted(generation, shared_result, hr, width, height,
                           number_of_cameras, camera_direction);
        });
      },
      [this, generation](const uint8_t* bgra, int width, int height,
                         int stride) {
        OnFrame(generation, bgra, width, height, stride);
      },
      [this, generation](HRESULT hr) {
        PostToPlatformThread([=]() { OnCaptureError(generation, hr); });
      });
}

void MobileScannerPlugin::OnCaptureStarted(
    int generation,
    std::shared_ptr<flutter::MethodResult<EncodableValue>> result, HRESULT hr,
    int width, int height, int number_of_cameras, int camera_direction) {
  if (generation != start_generation_) {
    result->Error(kCameraError,
                  "The camera was stopped before it finished starting.");
    return;
  }

  if (FAILED(hr)) {
    StopCapture();
    result->Error(hr == E_ACCESSDENIED ? kPermissionDeniedError : kCameraError,
                  HResultMessage(hr));
    return;
  }

  if (texture_id_ < 0) {
    RegisterTexture();
  }
  result->Success(EncodableValue(
      BuildStartResult(width, height, number_of_cameras, camera_direction)));
}

void MobileScannerPlugin::OnCaptureError(int generation, HRESULT hr) {
  if (generation != start_generation_ || !event_sink_) {
    return;
  }
  event_sink_->Error(kCameraError, HResultMessage(hr));
}

void MobileScannerPlugin::StopCapture() {
  start_generation_++;
  // Destroying the capture joins its thread, after which no more frames
  // arrive.
  capture_ = nullptr;
}

void MobileScannerPlugin::Stop(MethodResult result) {
  StopCapture();
  UnregisterTexture();
  {
    std::lock_guard<std::mutex> lock(scan_mutex_);
    paused_ = false;
  }
  result->Success();
}

void MobileScannerPlugin::Pause(MethodResult result) {
  // Release the camera but keep the texture, so the last frame stays visible.
  StopCapture();
  {
    std::lock_guard<std::mutex> lock(scan_mutex_);
    paused_ = true;
  }
  result->Success();
}

void MobileScannerPlugin::UpdateScanWindow(const EncodableMap* args,
                                           MethodResult result) {
  std::optional<ScanWindow> scan_window;

  const EncodableValue* rect = GetArg(args, "rect");
  if (rect != nullptr) {
    const auto* values = std::get_if<EncodableList>(rect);
    if (values == nullptr || values->size() != 4 ||
        !std::all_of(values->begin(), values->end(), [](const auto& value) {
          return std::holds_alternative<double>(value);
        })) {
      result->Error(kGenericError, "The scan window is not valid.");
      return;
    }
    scan_window = ScanWindow{
        std::get<double>((*values)[0]),
        std::get<double>((*values)[1]),
        std::get<double>((*values)[2]),
        std::get<double>((*values)[3]),
    };
  }

  {
    std::lock_guard<std::mutex> lock(scan_mutex_);
    scan_window_ = scan_window;
  }
  result->Success();
}

void MobileScannerPlugin::AnalyzeImage(const EncodableMap* args,
                                       MethodResult result) {
  const EncodableValue* file_path = GetArg(args, "filePath");
  if (file_path == nullptr || !std::holds_alternative<std::string>(*file_path)) {
    result->Error(kGenericError, "No file path was provided.");
    return;
  }

  // Decode on a worker, since loading and scanning a large image can take a
  // while. std::function requires a copyable callable, so the result is
  // shared rather than moved into the task.
  std::shared_ptr<flutter::MethodResult<EncodableValue>> shared_result =
      std::move(result);
  analyze_worker_->Post([this, shared_result,
                         path = Utf8ToWide(std::get<std::string>(*file_path)),
                         formats = GetFormatsArg(args)]() {
    std::optional<BgraImage> image = LoadImageFile(path);
    if (!image) {
      PostToPlatformThread([shared_result]() {
        shared_result->Error(kBarcodeError,
                             "The provided file is not an image.");
      });
      return;
    }

    BarcodeDecoder decoder;
    decoder.SetFormats(formats);
    EncodableList barcodes =
        decoder.Decode(image->pixels.data(), image->width, image->height,
                       image->width * 4, std::nullopt);

    PostToPlatformThread([shared_result, barcodes = std::move(barcodes)]() {
      shared_result->Success(EncodableValue(EncodableMap{
          {EncodableValue("name"), EncodableValue("barcode")},
          {EncodableValue("data"), EncodableValue(barcodes)},
      }));
    });
  });
}

void MobileScannerPlugin::OnFrame(int generation, const uint8_t* bgra,
                                  int width, int height, int stride) {
  if (texture_id_ < 0) {
    return;
  }

  const bool mirror = mirror_;

  {
    // Flutter's pixel buffer textures expect RGBA.
    std::lock_guard<std::mutex> lock(buffer_mutex_);
    rgba_buffer_.resize(static_cast<size_t>(width) * height * 4);
    for (int y = 0; y < height; y++) {
      const uint8_t* src = bgra + static_cast<ptrdiff_t>(y) * stride;
      uint8_t* dst = rgba_buffer_.data() + static_cast<size_t>(y) * width * 4;
      int dst_step = 4;
      if (mirror) {
        dst += static_cast<size_t>(width - 1) * 4;
        dst_step = -4;
      }
      for (int x = 0; x < width; x++, src += 4, dst += dst_step) {
        dst[0] = src[2];
        dst[1] = src[1];
        dst[2] = src[0];
        dst[3] = 0xFF;
      }
    }
    pixel_buffer_.width = static_cast<size_t>(width);
    pixel_buffer_.height = static_cast<size_t>(height);
  }
  texture_registrar_->MarkTextureFrameAvailable(texture_id_);

  {
    std::lock_guard<std::mutex> lock(scan_mutex_);
    if (paused_ || (detection_speed_ == kDetectionSpeedNormal &&
                    std::chrono::steady_clock::now() - last_scan_time_ <
                        std::chrono::milliseconds(detection_timeout_ms_))) {
      return;
    }
  }

  // Skip this frame if the previous one is still being scanned.
  if (scan_in_progress_.exchange(true)) {
    return;
  }

  const size_t row_size = static_cast<size_t>(width) * 4;
  scan_frame_.resize(row_size * height);
  for (int y = 0; y < height; y++) {
    std::memcpy(scan_frame_.data() + row_size * y,
                bgra + static_cast<ptrdiff_t>(y) * stride, row_size);
  }

  scan_worker_->Post([this, generation, width, height, mirror]() {
    ScanFrame(generation, width, height, mirror);
    scan_in_progress_ = false;
  });
}

void MobileScannerPlugin::ScanFrame(int generation, int width, int height,
                                    bool mirror) {
  // Take a snapshot of the settings, so that decoding does not hold the lock.
  BarcodeDecoder decoder;
  std::optional<ScanWindow> scan_window;
  bool return_image;
  {
    std::lock_guard<std::mutex> lock(scan_mutex_);
    decoder = decoder_;
    scan_window = scan_window_;
    return_image = return_image_;
  }

  // Decode the unmirrored frame, since mirrored 1D barcodes do not scan.
  // The scan window is in preview coordinates, so mirror it to match.
  if (scan_window && mirror) {
    scan_window = ScanWindow{1.0 - scan_window->right, scan_window->top,
                             1.0 - scan_window->left, scan_window->bottom};
  }
  EncodableList barcodes =
      decoder.Decode(scan_frame_.data(), width, height, width * 4, scan_window);
  if (barcodes.empty()) {
    return;
  }
  if (mirror) {
    MirrorBarcodes(barcodes, width);
  }

  {
    std::lock_guard<std::mutex> lock(scan_mutex_);
    last_scan_time_ = std::chrono::steady_clock::now();

    if (detection_speed_ == kDetectionSpeedNoDuplicates) {
      std::vector<std::string> values;
      for (const EncodableValue& barcode : barcodes) {
        const auto& map = std::get<EncodableMap>(barcode);
        values.push_back(
            std::get<std::string>(map.at(EncodableValue("rawValue"))));
      }
      std::sort(values.begin(), values.end());
      if (values == last_scanned_values_) {
        return;
      }
      last_scanned_values_ = std::move(values);
    }
  }

  // The image is mirrored like the preview, so the corners line up with it.
  std::optional<std::vector<uint8_t>> jpeg;
  if (return_image) {
    jpeg = EncodeJpeg(scan_frame_.data(), width, height, mirror);
  }

  PostToPlatformThread([this, generation, barcodes = std::move(barcodes),
                        jpeg = std::move(jpeg), width, height]() mutable {
    // Drop results from a capture that has since been stopped or paused.
    if (generation != start_generation_) {
      return;
    }
    SendBarcodes(std::move(barcodes), std::move(jpeg), width, height);
  });
}

void MobileScannerPlugin::SendBarcodes(EncodableList barcodes,
                                       std::optional<std::vector<uint8_t>> jpeg,
                                       int image_width, int image_height) {
  if (!event_sink_) {
    return;
  }

  EncodableMap image{
      {EncodableValue("width"),
       EncodableValue(static_cast<double>(image_width))},
      {EncodableValue("height"),
       EncodableValue(static_cast<double>(image_height))},
  };
  if (jpeg) {
    image[EncodableValue("bytes")] = EncodableValue(std::move(*jpeg));
  }

  event_sink_->Success(EncodableValue(EncodableMap{
      {EncodableValue("name"), EncodableValue("barcode")},
      {EncodableValue("data"), EncodableValue(std::move(barcodes))},
      {EncodableValue("image"), EncodableValue(std::move(image))},
  }));
}

int64_t MobileScannerPlugin::RegisterTexture() {
  texture_ = std::make_unique<flutter::TextureVariant>(
      flutter::PixelBufferTexture([this](size_t, size_t)
                                      -> const FlutterDesktopPixelBuffer* {
        // The lock is held until the engine has copied the buffer and calls
        // the release callback.
        buffer_mutex_.lock();
        if (rgba_buffer_.empty()) {
          buffer_mutex_.unlock();
          return nullptr;
        }
        pixel_buffer_.buffer = rgba_buffer_.data();
        pixel_buffer_.release_context = &buffer_mutex_;
        pixel_buffer_.release_callback = [](void* mutex) {
          static_cast<std::mutex*>(mutex)->unlock();
        };
        return &pixel_buffer_;
      }));
  texture_id_ = texture_registrar_->RegisterTexture(texture_.get());
  return texture_id_;
}

void MobileScannerPlugin::UnregisterTexture() {
  if (texture_id_ < 0) {
    return;
  }

  // Keep the texture alive until the engine is done with it.
  std::shared_ptr<flutter::TextureVariant> texture = std::move(texture_);
  texture_registrar_->UnregisterTexture(texture_id_, [texture]() {});
  texture_id_ = -1;

  std::lock_guard<std::mutex> lock(buffer_mutex_);
  rgba_buffer_.clear();
}

EncodableMap MobileScannerPlugin::BuildStartResult(
    int preview_width, int preview_height, int number_of_cameras,
    int camera_direction) const {
  return EncodableMap{
      {EncodableValue("textureId"), EncodableValue(texture_id_.load())},
      {EncodableValue("cameraDirection"), EncodableValue(camera_direction)},
      {EncodableValue("numberOfCameras"), EncodableValue(number_of_cameras)},
      {EncodableValue("currentTorchState"),
       EncodableValue(kTorchStateUnavailable)},
      {EncodableValue("size"),
       EncodableValue(EncodableMap{
           {EncodableValue("width"),
            EncodableValue(static_cast<double>(preview_width))},
           {EncodableValue("height"),
            EncodableValue(static_cast<double>(preview_height))},
       })},
  };
}

void MobileScannerPlugin::PostToPlatformThread(std::function<void()> task) {
  {
    std::lock_guard<std::mutex> lock(task_mutex_);
    tasks_.push_back(std::move(task));
  }

  flutter::FlutterView* view = registrar_->GetView();
  if (view == nullptr) {
    return;
  }
  HWND window = GetAncestor(view->GetNativeWindow(), GA_ROOT);
  if (window != nullptr) {
    PostMessage(window, task_message_, 0, 0);
  }
}

std::optional<LRESULT> MobileScannerPlugin::HandleWindowProc(HWND, UINT message,
                                                             WPARAM, LPARAM) {
  if (message != task_message_) {
    return std::nullopt;
  }

  std::deque<std::function<void()>> tasks;
  {
    std::lock_guard<std::mutex> lock(task_mutex_);
    tasks.swap(tasks_);
  }
  for (auto& task : tasks) {
    task();
  }
  return 0;
}

}  // namespace mobile_scanner
