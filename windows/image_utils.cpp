#include "image_utils.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <wincodec.h>
#include <wrl/client.h>

#include <cstring>

namespace mobile_scanner {

namespace {

using Microsoft::WRL::ComPtr;

constexpr float kJpegQuality = 0.8f;

}  // namespace

std::optional<BgraImage> LoadImageFile(const std::wstring& path) {
  ComPtr<IWICImagingFactory> factory;
  ComPtr<IWICBitmapDecoder> decoder;
  ComPtr<IWICBitmapFrameDecode> frame;
  ComPtr<IWICBitmapSource> bitmap;
  UINT width = 0;
  UINT height = 0;
  if (FAILED(CoCreateInstance(CLSID_WICImagingFactory, nullptr,
                              CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&factory))) ||
      FAILED(factory->CreateDecoderFromFilename(
          path.c_str(), nullptr, GENERIC_READ, WICDecodeMetadataCacheOnDemand,
          &decoder)) ||
      FAILED(decoder->GetFrame(0, &frame)) ||
      FAILED(WICConvertBitmapSource(GUID_WICPixelFormat32bppBGRA, frame.Get(),
                                    &bitmap)) ||
      FAILED(bitmap->GetSize(&width, &height))) {
    return std::nullopt;
  }

  BgraImage image;
  image.width = static_cast<int>(width);
  image.height = static_cast<int>(height);
  const UINT stride = width * 4;
  image.pixels.resize(static_cast<size_t>(stride) * height);
  if (FAILED(bitmap->CopyPixels(nullptr, stride,
                                static_cast<UINT>(image.pixels.size()),
                                image.pixels.data()))) {
    return std::nullopt;
  }
  return image;
}

std::optional<std::vector<uint8_t>> EncodeJpeg(const uint8_t* bgra, int width,
                                               int height, bool mirror) {
  const UINT stride = static_cast<UINT>(width) * 4;
  const UINT size = stride * static_cast<UINT>(height);

  ComPtr<IWICImagingFactory> factory;
  ComPtr<IWICBitmap> bitmap;
  if (FAILED(CoCreateInstance(CLSID_WICImagingFactory, nullptr,
                              CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&factory))) ||
      FAILED(factory->CreateBitmapFromMemory(
          static_cast<UINT>(width), static_cast<UINT>(height),
          GUID_WICPixelFormat32bppBGRA, stride, size,
          const_cast<BYTE*>(bgra), &bitmap))) {
    return std::nullopt;
  }

  ComPtr<IWICBitmapSource> source = bitmap;
  if (mirror) {
    ComPtr<IWICBitmapFlipRotator> flipped;
    if (FAILED(factory->CreateBitmapFlipRotator(&flipped)) ||
        FAILED(flipped->Initialize(bitmap.Get(),
                                   WICBitmapTransformFlipHorizontal))) {
      return std::nullopt;
    }
    source = flipped;
  }

  // JPEG has no alpha channel.
  ComPtr<IWICBitmapSource> converted;
  ComPtr<IStream> stream;
  ComPtr<IWICBitmapEncoder> encoder;
  ComPtr<IWICBitmapFrameEncode> frame;
  ComPtr<IPropertyBag2> properties;
  if (FAILED(WICConvertBitmapSource(GUID_WICPixelFormat24bppBGR, source.Get(),
                                    &converted)) ||
      FAILED(CreateStreamOnHGlobal(nullptr, TRUE, &stream)) ||
      FAILED(factory->CreateEncoder(GUID_ContainerFormatJpeg, nullptr,
                                    &encoder)) ||
      FAILED(encoder->Initialize(stream.Get(), WICBitmapEncoderNoCache)) ||
      FAILED(encoder->CreateNewFrame(&frame, &properties))) {
    return std::nullopt;
  }

  PROPBAG2 quality_option = {};
  quality_option.pstrName = const_cast<LPOLESTR>(L"ImageQuality");
  VARIANT quality;
  VariantInit(&quality);
  quality.vt = VT_R4;
  quality.fltVal = kJpegQuality;

  WICPixelFormatGUID pixel_format = GUID_WICPixelFormat24bppBGR;
  if (FAILED(properties->Write(1, &quality_option, &quality)) ||
      FAILED(frame->Initialize(properties.Get())) ||
      FAILED(frame->SetSize(static_cast<UINT>(width),
                            static_cast<UINT>(height))) ||
      FAILED(frame->SetPixelFormat(&pixel_format)) ||
      pixel_format != GUID_WICPixelFormat24bppBGR ||
      FAILED(frame->WriteSource(converted.Get(), nullptr)) ||
      FAILED(frame->Commit()) || FAILED(encoder->Commit())) {
    return std::nullopt;
  }

  HGLOBAL memory = nullptr;
  STATSTG stat = {};
  if (FAILED(GetHGlobalFromStream(stream.Get(), &memory)) ||
      FAILED(stream->Stat(&stat, STATFLAG_NONAME))) {
    return std::nullopt;
  }

  const void* data = GlobalLock(memory);
  if (data == nullptr) {
    return std::nullopt;
  }
  std::vector<uint8_t> jpeg(static_cast<size_t>(stat.cbSize.QuadPart));
  std::memcpy(jpeg.data(), data, jpeg.size());
  GlobalUnlock(memory);
  return jpeg;
}

}  // namespace mobile_scanner
