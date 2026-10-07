#include "camera_capture.h"

// This must be included before many other Windows headers.
#include <windows.h>

// initguid.h makes devpkey.h define the DEVPKEY_* constants in this file.
#include <initguid.h>
#include <devpkey.h>

#include <cfgmgr32.h>
#include <mfapi.h>
#include <mferror.h>
#include <mfidl.h>
#include <mfreadwrite.h>
#include <wrl/client.h>

#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <limits>
#include <utility>

namespace mobile_scanner {

namespace {

using Microsoft::WRL::ComPtr;

constexpr DWORD kVideoStream =
    static_cast<DWORD>(MF_SOURCE_READER_FIRST_VIDEO_STREAM);
constexpr int kDefaultWidth = 1280;
constexpr int kDefaultHeight = 720;

// Panel values from the ACPI _PLD (physical location of device) buffer.
constexpr BYTE kPldPanelFront = 4;
constexpr BYTE kPldPanelBack = 5;

// Reads which side of the device the camera is mounted on, from the _PLD
// buffer that the firmware exposes for built-in cameras.
int GetCameraFacing(const std::wstring& symbolic_link) {
  WCHAR instance_id[MAX_DEVICE_ID_LEN];
  ULONG size = sizeof(instance_id);
  DEVPROPTYPE type;
  if (CM_Get_Device_Interface_PropertyW(
          symbolic_link.c_str(), &DEVPKEY_Device_InstanceId, &type,
          reinterpret_cast<PBYTE>(instance_id), &size, 0) != CR_SUCCESS) {
    return kCameraFacingUnknown;
  }

  DEVINST device;
  if (CM_Locate_DevNodeW(&device, instance_id, CM_LOCATE_DEVNODE_NORMAL) !=
      CR_SUCCESS) {
    return kCameraFacingUnknown;
  }

  BYTE pld[32];
  size = sizeof(pld);
  if (CM_Get_DevNode_PropertyW(device, &DEVPKEY_Device_PhysicalDeviceLocation,
                               &type, pld, &size, 0) != CR_SUCCESS ||
      size < 9) {
    // Built-in cameras describe their location; USB cameras do not.
    return kCameraFacingExternal;
  }

  // The panel is stored in bits 67-69 of the buffer.
  switch ((pld[8] >> 3) & 0x7) {
    case kPldPanelFront:
      return kCameraFacingFront;
    case kPldPanelBack:
      return kCameraFacingBack;
    default:
      return kCameraFacingUnknown;
  }
}

bool IsCompressed(const GUID& subtype) {
  return subtype == MFVideoFormat_MJPG || subtype == MFVideoFormat_H264 ||
         subtype == MFVideoFormat_HEVC;
}

// Selects the native camera format closest to the preferred resolution,
// preferring frame rates of up to 30 fps and uncompressed formats.
HRESULT SelectNativeMediaType(IMFSourceReader* reader, int preferred_width,
                              int preferred_height,
                              ComPtr<IMFMediaType>* selected) {
  const int64_t preferred_area =
      static_cast<int64_t>(preferred_width) * preferred_height;

  int64_t best_area_distance = (std::numeric_limits<int64_t>::max)();
  UINT32 best_fps = 0;
  bool best_compressed = true;

  for (DWORD i = 0;; i++) {
    ComPtr<IMFMediaType> type;
    HRESULT hr = reader->GetNativeMediaType(kVideoStream, i, &type);
    if (hr == MF_E_NO_MORE_TYPES) {
      break;
    }
    if (FAILED(hr)) {
      return hr;
    }

    UINT32 width = 0, height = 0, fps_numerator = 0, fps_denominator = 1;
    GUID subtype = GUID_NULL;
    if (FAILED(MFGetAttributeSize(type.Get(), MF_MT_FRAME_SIZE, &width,
                                  &height)) ||
        FAILED(type->GetGUID(MF_MT_SUBTYPE, &subtype))) {
      continue;
    }
    MFGetAttributeRatio(type.Get(), MF_MT_FRAME_RATE, &fps_numerator,
                        &fps_denominator);
    const UINT32 fps =
        fps_denominator == 0 ? 0 : (std::min)(fps_numerator / fps_denominator, 30u);
    const bool compressed = IsCompressed(subtype);
    const int64_t area_distance =
        std::llabs(static_cast<int64_t>(width) * height - preferred_area);

    const bool better =
        area_distance < best_area_distance ||
        (area_distance == best_area_distance &&
         (fps > best_fps ||
          (fps == best_fps && best_compressed && !compressed)));
    if (better) {
      best_area_distance = area_distance;
      best_fps = fps;
      best_compressed = compressed;
      *selected = type;
    }
  }

  return *selected ? S_OK : MF_E_INVALIDMEDIATYPE;
}

HRESULT OpenReader(const std::wstring& symbolic_link,
                   std::optional<std::pair<int, int>> preferred_resolution,
                   ComPtr<IMFSourceReader>* reader) {
  ComPtr<IMFAttributes> source_attributes;
  HRESULT hr = MFCreateAttributes(&source_attributes, 2);
  if (SUCCEEDED(hr)) {
    hr = source_attributes->SetGUID(
        MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE,
        MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP_GUID);
  }
  if (SUCCEEDED(hr)) {
    hr = source_attributes->SetString(
        MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP_SYMBOLIC_LINK,
        symbolic_link.c_str());
  }

  ComPtr<IMFMediaSource> source;
  if (SUCCEEDED(hr)) {
    hr = MFCreateDeviceSource(source_attributes.Get(), &source);
  }

  // Advanced video processing lets the reader decode compressed formats and
  // convert to RGB32.
  ComPtr<IMFAttributes> reader_attributes;
  if (SUCCEEDED(hr)) {
    hr = MFCreateAttributes(&reader_attributes, 1);
  }
  if (SUCCEEDED(hr)) {
    hr = reader_attributes->SetUINT32(
        MF_SOURCE_READER_ENABLE_ADVANCED_VIDEO_PROCESSING, TRUE);
  }
  if (SUCCEEDED(hr)) {
    hr = MFCreateSourceReaderFromMediaSource(source.Get(),
                                             reader_attributes.Get(),
                                             reader->ReleaseAndGetAddressOf());
  }
  if (FAILED(hr)) {
    if (source) {
      source->Shutdown();
    }
    return hr;
  }

  // Cameras report their resolutions in landscape, while the requested
  // resolution may be in portrait.
  int preferred_width = kDefaultWidth;
  int preferred_height = kDefaultHeight;
  if (preferred_resolution) {
    preferred_width =
        (std::max)(preferred_resolution->first, preferred_resolution->second);
    preferred_height =
        (std::min)(preferred_resolution->first, preferred_resolution->second);
  }

  ComPtr<IMFMediaType> native_type;
  hr = SelectNativeMediaType(reader->Get(), preferred_width, preferred_height,
                             &native_type);
  if (SUCCEEDED(hr)) {
    hr = (*reader)->SetCurrentMediaType(kVideoStream, nullptr,
                                        native_type.Get());
  }

  ComPtr<IMFMediaType> output_type;
  if (SUCCEEDED(hr)) {
    hr = MFCreateMediaType(&output_type);
  }
  if (SUCCEEDED(hr)) {
    hr = output_type->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Video);
  }
  if (SUCCEEDED(hr)) {
    hr = output_type->SetGUID(MF_MT_SUBTYPE, MFVideoFormat_RGB32);
  }
  if (SUCCEEDED(hr)) {
    hr = (*reader)->SetCurrentMediaType(kVideoStream, nullptr,
                                        output_type.Get());
  }
  return hr;
}

struct FrameFormat {
  int width = 0;
  int height = 0;
  // Bytes per row; negative for bottom-up images.
  LONG default_stride = 0;
};

HRESULT GetFrameFormat(IMFSourceReader* reader, FrameFormat* format) {
  ComPtr<IMFMediaType> type;
  HRESULT hr = reader->GetCurrentMediaType(kVideoStream, &type);
  UINT32 width = 0, height = 0;
  if (SUCCEEDED(hr)) {
    hr = MFGetAttributeSize(type.Get(), MF_MT_FRAME_SIZE, &width, &height);
  }
  if (FAILED(hr)) {
    return hr;
  }

  format->width = static_cast<int>(width);
  format->height = static_cast<int>(height);

  UINT32 stride = 0;
  if (SUCCEEDED(type->GetUINT32(MF_MT_DEFAULT_STRIDE, &stride))) {
    format->default_stride = static_cast<LONG>(stride);
  } else {
    hr = MFGetStrideForBitmapInfoHeader(MFVideoFormat_RGB32.Data1, width,
                                        &format->default_stride);
  }
  return hr;
}

}  // namespace

std::vector<CameraDevice> EnumerateCameras() {
  std::vector<CameraDevice> cameras;

  ComPtr<IMFAttributes> attributes;
  if (FAILED(MFCreateAttributes(&attributes, 1)) ||
      FAILED(attributes->SetGUID(MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE,
                                 MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP_GUID))) {
    return cameras;
  }

  IMFActivate** devices = nullptr;
  UINT32 count = 0;
  if (FAILED(MFEnumDeviceSources(attributes.Get(), &devices, &count))) {
    return cameras;
  }

  for (UINT32 i = 0; i < count; i++) {
    WCHAR* symbolic_link = nullptr;
    UINT32 length = 0;
    if (SUCCEEDED(devices[i]->GetAllocatedString(
            MF_DEVSOURCE_ATTRIBUTE_SOURCE_TYPE_VIDCAP_SYMBOLIC_LINK,
            &symbolic_link, &length))) {
      cameras.push_back({symbolic_link, GetCameraFacing(symbolic_link)});
      CoTaskMemFree(symbolic_link);
    }
    devices[i]->Release();
  }
  CoTaskMemFree(devices);

  return cameras;
}

CameraCapture::~CameraCapture() { Stop(); }

void CameraCapture::Start(
    const std::wstring& symbolic_link,
    std::optional<std::pair<int, int>> preferred_resolution,
    StartedCallback on_started, FrameCallback on_frame,
    ErrorCallback on_error) {
  Stop();
  stop_requested_ = false;
  thread_ = std::thread(&CameraCapture::Run, this, symbolic_link,
                        preferred_resolution, std::move(on_started),
                        std::move(on_frame), std::move(on_error));
}

void CameraCapture::Stop() {
  stop_requested_ = true;
  if (thread_.joinable()) {
    thread_.join();
  }
}

void CameraCapture::Run(std::wstring symbolic_link,
                        std::optional<std::pair<int, int>> preferred_resolution,
                        StartedCallback on_started, FrameCallback on_frame,
                        ErrorCallback on_error) {
  const HRESULT co_init = CoInitializeEx(nullptr, COINIT_MULTITHREADED);

  ComPtr<IMFSourceReader> reader;
  FrameFormat format;
  HRESULT hr = OpenReader(symbolic_link, preferred_resolution, &reader);
  if (SUCCEEDED(hr)) {
    hr = GetFrameFormat(reader.Get(), &format);
  }
  on_started(hr, format.width, format.height);

  while (SUCCEEDED(hr) && !stop_requested_) {
    DWORD flags = 0;
    LONGLONG timestamp = 0;
    ComPtr<IMFSample> sample;
    hr = reader->ReadSample(kVideoStream, 0, nullptr, &flags, &timestamp,
                            &sample);
    if (stop_requested_) {
      break;
    }
    if (SUCCEEDED(hr) && (flags & MF_SOURCE_READERF_ERROR)) {
      hr = MF_E_VIDEO_RECORDING_DEVICE_INVALIDATED;
    } else if (SUCCEEDED(hr) && (flags & MF_SOURCE_READERF_ENDOFSTREAM)) {
      hr = MF_E_END_OF_STREAM;
    }
    if (FAILED(hr)) {
      on_error(hr);
      break;
    }

    if (flags & MF_SOURCE_READERF_CURRENTMEDIATYPECHANGED) {
      hr = GetFrameFormat(reader.Get(), &format);
      if (FAILED(hr)) {
        on_error(hr);
        break;
      }
    }

    ComPtr<IMFMediaBuffer> buffer;
    if (!sample || FAILED(sample->GetBufferByIndex(0, &buffer))) {
      continue;
    }

    // Prefer the 2D buffer interface, which reports the actual pitch.
    ComPtr<IMF2DBuffer> buffer_2d;
    BYTE* scanline0 = nullptr;
    LONG pitch = 0;
    if (SUCCEEDED(buffer.As(&buffer_2d)) &&
        SUCCEEDED(buffer_2d->Lock2D(&scanline0, &pitch))) {
      on_frame(scanline0, format.width, format.height, pitch);
      buffer_2d->Unlock2D();
    } else {
      BYTE* data = nullptr;
      if (SUCCEEDED(buffer->Lock(&data, nullptr, nullptr))) {
        pitch = format.default_stride;
        if (pitch < 0) {
          // Bottom-up image: the top row is the last one in memory.
          data += static_cast<ptrdiff_t>(-pitch) * (format.height - 1);
        }
        on_frame(data, format.width, format.height, pitch);
        buffer->Unlock();
      }
    }
  }

  if (reader) {
    reader.Reset();
  }
  if (SUCCEEDED(co_init)) {
    CoUninitialize();
  }
}

std::string HResultMessage(HRESULT hr) {
  LPWSTR buffer = nullptr;
  DWORD length = FormatMessageW(
      FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM |
          FORMAT_MESSAGE_IGNORE_INSERTS,
      nullptr, static_cast<DWORD>(hr), 0, reinterpret_cast<LPWSTR>(&buffer), 0,
      nullptr);
  // Media Foundation errors are not in the system message table.
  if (length == 0) {
    HMODULE mfplat = GetModuleHandleW(L"mfplat.dll");
    length = FormatMessageW(
        FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_HMODULE |
            FORMAT_MESSAGE_IGNORE_INSERTS,
        mfplat, static_cast<DWORD>(hr), 0, reinterpret_cast<LPWSTR>(&buffer),
        0, nullptr);
  }

  std::string message;
  if (length > 0) {
    // Trim the trailing line break.
    while (length > 0 &&
           (buffer[length - 1] == L'\r' || buffer[length - 1] == L'\n')) {
      length--;
    }
    const int size = WideCharToMultiByte(CP_UTF8, 0, buffer,
                                         static_cast<int>(length), nullptr, 0,
                                         nullptr, nullptr);
    message.resize(size);
    WideCharToMultiByte(CP_UTF8, 0, buffer, static_cast<int>(length),
                        message.data(), size, nullptr, nullptr);
  }
  LocalFree(buffer);

  char code[16];
  snprintf(code, sizeof(code), "0x%08lX", static_cast<unsigned long>(hr));
  return message.empty() ? std::string("Camera error ") + code
                         : message + " (" + code + ")";
}

}  // namespace mobile_scanner
