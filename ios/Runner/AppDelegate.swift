import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var speechRecognizer: NativeSpeechRecognizer?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Configuration du channel natif pour reconnaissance vocale
    let controller = window?.rootViewController as! FlutterViewController
    setupNativeSpeechChannel(controller: controller)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func setupNativeSpeechChannel(controller: FlutterViewController) {
    let methodChannel = FlutterMethodChannel(
      name: "com.ryze.speech/native",
      binaryMessenger: controller.binaryMessenger
    )

    let eventChannel = FlutterEventChannel(
      name: "com.ryze.speech/events",
      binaryMessenger: controller.binaryMessenger
    )

    speechRecognizer = NativeSpeechRecognizer()
    eventChannel.setStreamHandler(speechRecognizer)

    methodChannel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self, let recognizer = self.speechRecognizer else {
        result(FlutterError(code: "UNAVAILABLE", message: "Speech recognizer not initialized", details: nil))
        return
      }

      switch call.method {
      case "requestPermissions":
        NativeSpeechRecognizer.requestPermissions(result: result)

      case "isAvailable":
        result(recognizer.isAvailable())

      case "setLocale":
        if let args = call.arguments as? [String: Any],
           let localeId = args["localeId"] as? String {
          recognizer.setLocale(localeId: localeId)
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "localeId required", details: nil))
        }

      case "startListening":
        recognizer.startListening(result: result)

      case "stopListening":
        recognizer.stopListening()
        result(true)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
