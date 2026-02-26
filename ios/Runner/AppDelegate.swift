import Flutter
import UIKit
import ObjectiveC

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Guard against Jitsi WebRTC's enumerateDevices crashing on iOS Simulator
    // (NSDictionary rejects nil values when camera hardware is absent)
    Self.swizzleJitsiWebRTCIfSimulator()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// On iOS Simulator, replace WebRTCModule.enumerateDevices: with a safe version
  /// that invokes the callback with an empty array instead of crashing.
  private static func swizzleJitsiWebRTCIfSimulator() {
    #if targetEnvironment(simulator)
    guard
      let targetClass = NSClassFromString("WebRTCModule"),
      let originalMethod = class_getInstanceMethod(targetClass,
        NSSelectorFromString("enumerateDevices:")),
      let replacementMethod = class_getInstanceMethod(AppDelegate.self,
        #selector(AppDelegate.safeEnumerateDevices(_:)))
    else {
      print("[SimGuard] WebRTCModule not found — skipping swizzle (safe to ignore)")
      return
    }
    method_exchangeImplementations(originalMethod, replacementMethod)
    print("[SimGuard] Swizzled WebRTCModule.enumerateDevices for iOS Simulator safety")
    #endif
  }

  /// Safe replacement for WebRTCModule.enumerateDevices: on simulator.
  /// Calls back with an empty devices array instead of crashing on nil.
  @objc func safeEnumerateDevices(_ callback: Any?) {
    // Resolve the callback — Jitsi passes an RCTResponseSenderBlock (NSArray*).
    // On simulator we simply return an empty list and no error.
    if let block = callback as? ([Any?]) -> Void {
      block([[]])
    }
  }
}

