import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var speechRecognizer: NativeSpeechRecognizer?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Configuration des channels après que la fenêtre soit prête
    // Utiliser un délai pour s'assurer que window?.rootViewController est disponible
    DispatchQueue.main.async { [weak self] in
      guard let self = self,
            let window = self.window,
            let controller = window.rootViewController as? FlutterViewController else {
        print("⚠️ Window or FlutterViewController not ready yet")
        return
      }
      
      // Configuration du channel natif pour reconnaissance vocale
      self.setupNativeSpeechChannel(controller: controller)
      
      // Configuration du channel pour les données du widget (App Group)
      self.setupWidgetDataChannel(controller: controller)
    }

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

  private func setupWidgetDataChannel(controller: FlutterViewController) {
    let methodChannel = FlutterMethodChannel(
      name: "com.ryze.widget/data",
      binaryMessenger: controller.binaryMessenger
    )

    methodChannel.setMethodCallHandler { (call, result) in
      let appGroupId = "group.com.ryze.app"
      guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
        result(FlutterError(code: "APP_GROUP_ERROR", message: "App Group not available", details: nil))
        return
      }

      switch call.method {
      case "setString":
        if let args = call.arguments as? [String: Any],
           let key = args["key"] as? String,
           let value = args["value"] as? String {
          userDefaults.set(value, forKey: key)
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "key and value required", details: nil))
        }

      case "getString":
        if let args = call.arguments as? [String: Any],
           let key = args["key"] as? String {
          let value = userDefaults.string(forKey: key)
          result(value)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "key required", details: nil))
        }

      case "remove":
        if let args = call.arguments as? [String: Any],
           let key = args["key"] as? String {
          userDefaults.removeObject(forKey: key)
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "key required", details: nil))
        }

      case "reloadWidgetTimelines":
        if #available(iOS 14.0, *) {
          // Recharger tous les widgets de l'app
          // Utiliser WidgetCenter pour recharger les timelines
          WidgetCenter.shared.reloadAllTimelines()
          result(true)
        } else {
          result(FlutterError(code: "NOT_AVAILABLE", message: "WidgetKit not available", details: nil))
        }
        
      case "getBool":
        if let args = call.arguments as? [String: Any],
           let key = args["key"] as? String {
          let value = userDefaults.bool(forKey: key)
          result(value)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "key required", details: nil))
        }

      case "getInt":
        if let args = call.arguments as? [String: Any],
           let key = args["key"] as? String {
          let value = userDefaults.integer(forKey: key)
          result(value)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "key required", details: nil))
        }

      case "getDouble":
        if let args = call.arguments as? [String: Any],
           let key = args["key"] as? String {
          // Utiliser object(forKey:) pour distinguer absence de valeur vs 0.0 réel
          if userDefaults.object(forKey: key) != nil {
            let value = userDefaults.double(forKey: key)
            result(value)
          } else {
            result(nil)
          }
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "key required", details: nil))
        }

      case "setInt":
        if let args = call.arguments as? [String: Any],
           let key = args["key"] as? String,
           let value = args["value"] as? Int {
          userDefaults.set(value, forKey: key)
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "key and value required", details: nil))
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
