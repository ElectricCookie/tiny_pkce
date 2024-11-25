import Flutter
import UIKit
import AuthenticationServices

public class TinyPkceLauncherPlugin: NSObject, FlutterPlugin, ASWebAuthenticationPresentationContextProviding {
    private var authSession: ASWebAuthenticationSession?
    
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first!
    }
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "tiny_pkce_launcher", binaryMessenger: registrar.messenger())
    let instance = TinyPkceLauncherPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "launchUrl":
      

      guard let arguments = call.arguments as? [String: Any],
            let urlString = arguments["url"] as? String,
            let scheme = arguments["scheme"] as? String,
            let url = URL(string: urlString) else {
        result(nil)
        return
      }

      
      authSession = ASWebAuthenticationSession(url: url, callbackURLScheme: scheme) { [weak self] url, error in
          defer { self?.authSession = nil }
          
          if let error = error {
              self?.authSession?.cancel()
              result(FlutterError())
          } else {
              result(url?.absoluteString)
          }
      }
      
      if #available(iOS 13.0, *) {
          authSession?.presentationContextProvider = self
          authSession?.prefersEphemeralWebBrowserSession = true
      }
      
      authSession?.start()
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}


