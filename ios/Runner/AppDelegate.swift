import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private let CHANNEL = "com.example.elmapp/openfile"
  var openFileUrl: URL?
  var flutterResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let methodChannel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: controller.binaryMessenger)

    methodChannel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "getFileContent":
        self.flutterResult = result
      case "saveFileContent":
        if let content = call.arguments as? String, let url = self.openFileUrl {
          do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            result(true)
          } catch {
            result(FlutterError(code: "WRITE_ERROR", message: "Failed to write file", details: error.localizedDescription))
          }
        } else {
          result(FlutterError(code: "NO_FILE", message: "No file open", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    openFileUrl = url
    if let result = flutterResult {
      let content = try? String(contentsOf: url, encoding: .utf8)
      result(content)
      self.flutterResult = nil // Clear the result after use to avoid retaining an outdated reference
    }
    return true
  }
}
