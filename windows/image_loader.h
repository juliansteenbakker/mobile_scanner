#ifndef FLUTTER_PLUGIN_IMAGE_LOADER_H_
#define FLUTTER_PLUGIN_IMAGE_LOADER_H_

#include <windows.h>
#include <wincodec.h>

#include <stdexcept>
#include <string>
#include <vector>

namespace mobile_scanner {

struct ImageData {
  std::vector<uint8_t> pixels;  // RGBA, row-major
  int width = 0;
  int height = 0;
};

/// Converts a UTF-8 string to a wide string for use with Windows APIs.
inline std::wstring Utf8ToWide(const std::string& utf8) {
  if (utf8.empty()) return {};
  int len = MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(),
                                static_cast<int>(utf8.size()), nullptr, 0);
  std::wstring wide(len, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(),
                      static_cast<int>(utf8.size()), &wide[0], len);
  return wide;
}

/// Loads an image from |path| (UTF-16) and converts it to 32-bit RGBA pixels.
/// Throws std::runtime_error on failure.
inline ImageData LoadImageAsRGBA(const std::wstring& path) {
  IWICImagingFactory* factory = nullptr;
  HRESULT hr = CoCreateInstance(CLSID_WICImagingFactory, nullptr,
                                CLSCTX_INPROC_SERVER,
                                IID_PPV_ARGS(&factory));
  if (FAILED(hr)) {
    throw std::runtime_error("Failed to create WIC imaging factory");
  }

  IWICBitmapDecoder* decoder = nullptr;
  hr = factory->CreateDecoderFromFilename(path.c_str(), nullptr,
                                          GENERIC_READ,
                                          WICDecodeMetadataCacheOnDemand,
                                          &decoder);
  if (FAILED(hr)) {
    factory->Release();
    throw std::runtime_error("Failed to open image file");
  }

  IWICBitmapFrameDecode* frame = nullptr;
  hr = decoder->GetFrame(0, &frame);
  if (FAILED(hr)) {
    decoder->Release();
    factory->Release();
    throw std::runtime_error("Failed to decode image frame");
  }

  IWICFormatConverter* converter = nullptr;
  hr = factory->CreateFormatConverter(&converter);
  if (FAILED(hr)) {
    frame->Release();
    decoder->Release();
    factory->Release();
    throw std::runtime_error("Failed to create WIC format converter");
  }

  hr = converter->Initialize(frame, GUID_WICPixelFormat32bppRGBA,
                              WICBitmapDitherTypeNone, nullptr, 0.0,
                              WICBitmapPaletteTypeCustom);
  if (FAILED(hr)) {
    converter->Release();
    frame->Release();
    decoder->Release();
    factory->Release();
    throw std::runtime_error("Failed to initialize WIC format converter");
  }

  UINT width = 0, height = 0;
  hr = converter->GetSize(&width, &height);
  if (FAILED(hr) || width == 0 || height == 0) {
    converter->Release();
    frame->Release();
    decoder->Release();
    factory->Release();
    throw std::runtime_error("Failed to get image size");
  }

  const UINT stride = width * 4;
  const UINT buf_size = stride * height;
  std::vector<uint8_t> pixels(buf_size);
  hr = converter->CopyPixels(nullptr, stride, buf_size, pixels.data());

  converter->Release();
  frame->Release();
  decoder->Release();
  factory->Release();

  if (FAILED(hr)) {
    throw std::runtime_error("Failed to copy image pixels");
  }

  return ImageData{std::move(pixels), static_cast<int>(width),
                   static_cast<int>(height)};
}

}  // namespace mobile_scanner

#endif  // FLUTTER_PLUGIN_IMAGE_LOADER_H_
