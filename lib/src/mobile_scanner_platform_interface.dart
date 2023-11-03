import 'package:mobile_scanner/src/method_channel/mobile_scanner_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The platform interface for the `mobile_scanner` plugin.
abstract class MobileScannerPlatform extends PlatformInterface {
  /// Constructs a MobileScannerPlatform.
  MobileScannerPlatform() : super(token: _token);

  static final Object _token = Object();

  static MobileScannerPlatform _instance = MethodChannelMobileScanner();

  /// The default instance of [MobileScannerPlatform] to use.
  ///
  /// Defaults to [MethodChannelMobileScanner].
  static MobileScannerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MobileScannerPlatform] when
  /// they register themselves.
  static set instance(MobileScannerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }
}
