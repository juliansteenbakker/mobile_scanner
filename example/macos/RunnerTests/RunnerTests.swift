import FlutterMacOS
import Cocoa
import XCTest

@testable import mobile_scanner

// This demonstrates a simple unit test of the Swift portion of this plugin's implementation.
//
// See https://developer.apple.com/documentation/xctest for more information about using XCTest.

class RunnerTests: XCTestCase {

  // TODO: this test was left as-is from the template, but it obviuosly fails for now.
  // Add new tests later.
  /*
  func testGetPlatformVersion() {
    let plugin = MobileScannerPlugin()

    let call = FlutterMethodCall(methodName: "getPlatformVersion", arguments: [])

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssertEqual(result as! String,
                     "macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }*/

}
