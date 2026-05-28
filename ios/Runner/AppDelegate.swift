import Flutter
import UIKit
import AVFoundation
import MediaPlayer

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    
    let methodChannel = FlutterMethodChannel(name: "sos_app/sms",
                                              binaryMessenger: engineBridge.applicationRegistrar.messenger())
    methodChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      self?.handle(call, result: result)
    })
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "toggleFlashlight":
      toggleFlashlight(result: result)
    case "volumeUp":
      adjustVolume(by: 0.0625, result: result)
    case "volumeDown":
      adjustVolume(by: -0.0625, result: result)
    case "playPauseMedia", "toggleCall", "triggerAssistant", "sendSMS":
      result(FlutterError(code: "UNSUPPORTED_ON_IOS",
                          message: "\(call.method) is not supported on iOS due to platform security restrictions",
                          details: nil))
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func toggleFlashlight(result: @escaping FlutterResult) {
    guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
      result(FlutterError(code: "NO_TORCH", message: "Device does not have a torch", details: nil))
      return
    }
    do {
      try device.lockForConfiguration()
      if device.torchMode == .on {
        device.torchMode = .off
      } else {
        try device.setTorchModeOn(level: 1.0)
      }
      device.unlockForConfiguration()
      result("Flashlight toggled")
    } catch {
      result(FlutterError(code: "FLASHLIGHT_FAILED", message: error.localizedDescription, details: nil))
    }
  }

  private func adjustVolume(by increment: Float, result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      let volumeView = MPVolumeView()
      if let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider {
        slider.value = max(0.0, min(1.0, slider.value + increment))
        result("Volume adjusted")
      } else {
        result(FlutterError(code: "VOLUME_FAILED", message: "Could not locate iOS volume slider", details: nil))
      }
    }
  }
}
