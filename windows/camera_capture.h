#ifndef FLUTTER_PLUGIN_MOBILE_SCANNER_CAMERA_CAPTURE_H_
#define FLUTTER_PLUGIN_MOBILE_SCANNER_CAMERA_CAPTURE_H_

#include <windows.h>

#include <atomic>
#include <cstdint>
#include <functional>
#include <optional>
#include <string>
#include <thread>
#include <vector>

namespace mobile_scanner {

// `CameraFacing.rawValue` values from lib/src/enums/camera_facing.dart.
constexpr int kCameraFacingFront = 0;
constexpr int kCameraFacingBack = 1;
constexpr int kCameraFacingExternal = 2;
constexpr int kCameraFacingUnknown = -1;

struct CameraDevice {
  std::wstring symbolic_link;
  // One of the kCameraFacing* values, derived from the panel the device is
  // mounted on. Devices without location information (typically USB cameras)
  // are reported as external.
  int facing;
};

// Lists the video capture devices, in system order.
std::vector<CameraDevice> EnumerateCameras();

// Captures frames from a single camera on a background thread using a Media
// Foundation Source Reader, converting them to 32-bit BGRA.
class CameraCapture {
 public:
  // Called once the camera is open (or failed to open), on the capture thread.
  using StartedCallback = std::function<void(HRESULT hr, int width, int height)>;
  // Called for every frame, on the capture thread. `stride` may be negative
  // for bottom-up images, in which case `bgra` points to the top row.
  using FrameCallback =
      std::function<void(const uint8_t* bgra, int width, int height,
                         int stride)>;
  // Called when capturing stops unexpectedly after a successful start, for
  // example when the camera is unplugged. Called on the capture thread.
  using ErrorCallback = std::function<void(HRESULT hr)>;

  CameraCapture() = default;
  ~CameraCapture();

  CameraCapture(const CameraCapture&) = delete;
  CameraCapture& operator=(const CameraCapture&) = delete;

  // Opens the camera and starts capturing on a background thread. The
  // resolution closest to `preferred_resolution` (or 1280x720 if not given)
  // is used.
  void Start(const std::wstring& symbolic_link,
             std::optional<std::pair<int, int>> preferred_resolution,
             StartedCallback on_started, FrameCallback on_frame,
             ErrorCallback on_error);

  // Stops capturing and waits for the capture thread to exit. No callbacks
  // are invoked after this returns.
  void Stop();

 private:
  void Run(std::wstring symbolic_link,
           std::optional<std::pair<int, int>> preferred_resolution,
           StartedCallback on_started, FrameCallback on_frame,
           ErrorCallback on_error);

  std::thread thread_;
  std::atomic<bool> stop_requested_ = false;
};

// Returns a human readable message for the given HRESULT.
std::string HResultMessage(HRESULT hr);

}  // namespace mobile_scanner

#endif  // FLUTTER_PLUGIN_MOBILE_SCANNER_CAMERA_CAPTURE_H_
