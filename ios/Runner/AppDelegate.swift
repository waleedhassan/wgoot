import CoreLocation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let compass = CompassStreamHandler()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "WgootCompass") else {
      return
    }
    let messenger = registrar.messenger()
    FlutterMethodChannel(name: "apps.waleed.sunnah.wgoot/compass", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        switch call.method {
        case "isAvailable":
          result(CLLocationManager.headingAvailable())
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    FlutterEventChannel(name: "apps.waleed.sunnah.wgoot/compass/heading", binaryMessenger: messenger)
      .setStreamHandler(compass)
  }
}

/// Streams `[magneticHeadingDegrees, accuracyLevel]` to the Qibla screen.
///
/// Magnetic heading needs no location permission (true heading would), so
/// Dart applies the declination for the chosen city instead. The accuracy
/// level follows Android's 0–3 `SENSOR_STATUS_*` scale.
final class CompassStreamHandler: NSObject, FlutterStreamHandler, CLLocationManagerDelegate {
  private let manager = CLLocationManager()
  private var sink: FlutterEventSink?

  override init() {
    super.init()
    manager.delegate = self
    manager.headingFilter = 0.5
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    guard CLLocationManager.headingAvailable() else {
      return FlutterError(code: "unavailable", message: "No compass on this device", details: nil)
    }
    sink = events
    UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    updateHeadingOrientation()
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(updateHeadingOrientation),
      name: UIDevice.orientationDidChangeNotification,
      object: nil
    )
    manager.startUpdatingHeading()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    manager.stopUpdatingHeading()
    UIDevice.current.endGeneratingDeviceOrientationNotifications()
    NotificationCenter.default.removeObserver(
      self,
      name: UIDevice.orientationDidChangeNotification,
      object: nil
    )
    sink = nil
    return nil
  }

  func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    let error = newHeading.headingAccuracy
    let level: Int
    if error < 0 {
      level = 0
    } else if error <= 10 {
      level = 3
    } else if error <= 25 {
      level = 2
    } else {
      level = 1
    }
    sink?([newHeading.magneticHeading, level])
  }

  func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
    return true
  }

  @objc private func updateHeadingOrientation() {
    switch UIDevice.current.orientation {
    case .portraitUpsideDown:
      manager.headingOrientation = .portraitUpsideDown
    case .landscapeLeft:
      manager.headingOrientation = .landscapeLeft
    case .landscapeRight:
      manager.headingOrientation = .landscapeRight
    case .portrait:
      manager.headingOrientation = .portrait
    default:
      break
    }
  }
}
