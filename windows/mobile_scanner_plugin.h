#ifndef FLUTTER_PLUGIN_MOBILE_SCANNER_PLUGIN_H_
#define FLUTTER_PLUGIN_MOBILE_SCANNER_PLUGIN_H_

#include <flutter/event_channel.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/texture_registrar.h>
#include <windows.h>

#include <atomic>
#include <chrono>
#include <cstdint>
#include <deque>
#include <functional>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <vector>

#include "barcode_decoder.h"
#include "camera_capture.h"
#include "worker_thread.h"

namespace mobile_scanner {

class MobileScannerPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  explicit MobileScannerPlugin(flutter::PluginRegistrarWindows* registrar);

  virtual ~MobileScannerPlugin();

  // Disallow copy and assign.
  MobileScannerPlugin(const MobileScannerPlugin&) = delete;
  MobileScannerPlugin& operator=(const MobileScannerPlugin&) = delete;

 private:
  using MethodResult =
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      MethodResult result);

  void Start(const flutter::EncodableMap* args, MethodResult result);
  void Stop(MethodResult result);
  void Pause(MethodResult result);
  void UpdateScanWindow(const flutter::EncodableMap* args,
                        MethodResult result);
  void AnalyzeImage(const flutter::EncodableMap* args, MethodResult result);

  // Completes a `start` call once the capture thread has opened the camera.
  void OnCaptureStarted(
      int generation,
      std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>> result,
      HRESULT hr, int width, int height, int number_of_cameras,
      int camera_direction);
  // Reports a camera failure that happened after a successful start.
  void OnCaptureError(int generation, HRESULT hr);
  void StopCapture();

  // Handles a camera frame in 32-bit BGRA format, on the capture thread.
  // Updates the preview texture and hands the frame to the scan worker if it
  // is idle; frames that arrive while a scan is running are not scanned.
  void OnFrame(int generation, const uint8_t* bgra, int width, int height,
               int stride);
  // Scans `scan_frame_` for barcodes, on the scan worker.
  void ScanFrame(int generation, int width, int height, bool mirror);

  // Registers the preview texture with the engine and returns its id.
  int64_t RegisterTexture();
  void UnregisterTexture();

  // Builds the reply for a successful `start` call.
  flutter::EncodableMap BuildStartResult(int preview_width, int preview_height,
                                         int number_of_cameras,
                                         int camera_direction) const;

  // Sends a barcode event to Dart. Must be called on the platform thread.
  void SendBarcodes(flutter::EncodableList barcodes,
                    std::optional<std::vector<uint8_t>> jpeg, int image_width,
                    int image_height);

  // Runs `task` on the platform thread. Flutter channels on Windows may only
  // be used from the platform thread, so results produced on the capture
  // thread must be sent through here.
  void PostToPlatformThread(std::function<void()> task);
  std::optional<LRESULT> HandleWindowProc(HWND hwnd, UINT message,
                                          WPARAM wparam, LPARAM lparam);

  flutter::PluginRegistrarWindows* registrar_;
  flutter::TextureRegistrar* texture_registrar_;

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      method_channel_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>>
      event_channel_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>>
      device_orientation_channel_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;

  // Platform thread task queue.
  int window_proc_delegate_id_ = -1;
  UINT task_message_ = 0;
  std::mutex task_mutex_;
  std::deque<std::function<void()>> tasks_;

  // Camera capture. `start_generation_` is bumped whenever the capture is
  // started or stopped, so that late callbacks from an earlier capture are
  // ignored.
  std::unique_ptr<CameraCapture> capture_;
  int start_generation_ = 0;
  // Whether to mirror the preview horizontally, like a front facing camera
  // on mobile devices.
  std::atomic<bool> mirror_ = false;

  // Preview texture. `buffer_mutex_` guards the pixel buffer, which is written
  // by the capture thread and read by the raster thread.
  std::unique_ptr<flutter::TextureVariant> texture_;
  std::atomic<int64_t> texture_id_ = -1;
  std::mutex buffer_mutex_;
  std::vector<uint8_t> rgba_buffer_;
  FlutterDesktopPixelBuffer pixel_buffer_ = {};

  // Live frames are scanned on `scan_worker_`, and `analyzeImage` runs on
  // `analyze_worker_`, so neither blocks the camera or the UI.
  std::unique_ptr<WorkerThread> scan_worker_;
  std::unique_ptr<WorkerThread> analyze_worker_;
  // Set while the scan worker owns `scan_frame_`, which otherwise belongs to
  // the capture thread.
  std::atomic<bool> scan_in_progress_ = false;
  // A tightly packed, unmirrored BGRA copy of the frame being scanned.
  std::vector<uint8_t> scan_frame_;

  // Scanning state. `scan_mutex_` guards everything below, which is shared
  // between the platform thread, the capture thread and the scan worker.
  std::mutex scan_mutex_;
  BarcodeDecoder decoder_;
  std::optional<ScanWindow> scan_window_;
  int detection_speed_ = 0;
  int detection_timeout_ms_ = 250;
  bool return_image_ = false;
  bool paused_ = false;
  std::chrono::steady_clock::time_point last_scan_time_;
  std::vector<std::string> last_scanned_values_;
};

}  // namespace mobile_scanner

#endif  // FLUTTER_PLUGIN_MOBILE_SCANNER_PLUGIN_H_
