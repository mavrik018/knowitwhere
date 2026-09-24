import CoreSpotlight
import Flutter
import UIKit
import UniformTypeIdentifiers

/// Core Spotlight bridge (FR7).
///
/// Dart sends the full item list after every mutation (`replaceAll`), which
/// re-indexes name as the title and location as the description; deleted
/// items drop out because the whole domain is replaced. Taps on a Spotlight
/// result are forwarded to Dart as `openItem(id)`.
final class SpotlightPlugin: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate {
  static let domain = "com.AandMapps.knowitwhere.items"

  private let channel: FlutterMethodChannel
  /// A tap that arrived before Dart asked for it (cold launch from Spotlight).
  private var pendingItemId: String?
  private var dartReady = false

  init(channel: FlutterMethodChannel) {
    self.channel = channel
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "knowitwhere/spotlight", binaryMessenger: registrar.messenger())
    let instance = SpotlightPlugin(channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addSceneDelegate(instance)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "replaceAll":
      guard let items = call.arguments as? [[String: String]] else {
        result(FlutterError(code: "bad_args", message: "Expected a list of items", details: nil))
        return
      }
      replaceAll(items, result: result)
    case "takeInitialItem":
      dartReady = true
      result(pendingItemId)
      pendingItemId = nil
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func replaceAll(_ items: [[String: String]], result: @escaping FlutterResult) {
    let searchable = items.compactMap { item -> CSSearchableItem? in
      guard let id = item["id"], let name = item["name"], let location = item["location"] else {
        return nil
      }
      let attributes = CSSearchableItemAttributeSet(contentType: UTType.text)
      attributes.title = name
      attributes.contentDescription = location
      return CSSearchableItem(
        uniqueIdentifier: id, domainIdentifier: Self.domain, attributeSet: attributes)
    }

    let index = CSSearchableIndex.default()
    index.deleteSearchableItems(withDomainIdentifiers: [Self.domain]) { error in
      if let error {
        Self.finish(result, error)
        return
      }
      if searchable.isEmpty {
        Self.finish(result, nil)
        return
      }
      index.indexSearchableItems(searchable) { error in Self.finish(result, error) }
    }
  }

  private static func finish(_ result: @escaping FlutterResult, _ error: Error?) {
    DispatchQueue.main.async {
      if let error {
        result(
          FlutterError(code: "spotlight_failed", message: error.localizedDescription, details: nil))
      } else {
        result(nil)
      }
    }
  }

  // MARK: - Spotlight taps (FR7.2)

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions?
  ) -> Bool {
    var handled = false
    for activity in connectionOptions?.userActivities ?? [] {
      handled = open(activity) || handled
    }
    return handled
  }

  func scene(_ scene: UIScene, continue userActivity: NSUserActivity) -> Bool {
    open(userActivity)
  }

  private func open(_ activity: NSUserActivity) -> Bool {
    guard activity.activityType == CSSearchableItemActionType,
      let id = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String
    else {
      return false
    }
    if dartReady {
      channel.invokeMethod("openItem", arguments: id)
    } else {
      pendingItemId = id
    }
    return true
  }
}
