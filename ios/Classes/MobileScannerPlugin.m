#import "MobileScannerPlugin.h"
#if __has_include(<mobile_scanner/mobile_scanner-Swift.h>)
#import <mobile_scanner/mobile_scanner-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "mobile_scanner-Swift.h"
#endif

@implementation MobileScannerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftMobileScannerPlugin registerWithRegistrar:registrar];
}
@end
