import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 1. Provide the API key FIRST — must be before any GMSMapView is created
    GMSServices.provideAPIKey("AIzaSyBXva4PuRMiA-l2pgeSCSwxabTPG6FoupY")

    // 2. Create a Flutter engine explicitly
    let flutterEngine = FlutterEngine(name: "main_engine")
    flutterEngine.run()

    // 3. Register ALL plugins (incl. FGMGoogleMapsPlugin) directly with this engine
    GeneratedPluginRegistrant.register(with: flutterEngine)

    // 4. Create the root FlutterViewController backed by the same engine
    let flutterViewController = FlutterViewController(
      engine: flutterEngine,
      nibName: nil,
      bundle: nil
    )

    // 5. Set up the window
    let window = UIWindow(frame: UIScreen.main.bounds)
    window.rootViewController = flutterViewController
    window.makeKeyAndVisible()
    self.window = window

    return true
  }
}
