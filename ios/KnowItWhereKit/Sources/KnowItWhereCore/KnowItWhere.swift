import Foundation

/// Identifiers shared with the Flutter app (see README "Shared cache contract").
public enum KnowItWhere {
  public static let appGroupId = "group.com.AandMapps.knowitwhere"
  /// UserDefaults key in the App Group suite holding the JSON snapshot.
  public static let sharedCacheKey = "items"
  /// WidgetKit kind; the Flutter app reloads this timeline after each mutation.
  public static let widgetKind = "KnowItWhereWidget"
  public static let urlScheme = "knowitwhere"
}

/// Deep links handled by the Flutter app (SRS §4.3).
public enum DeepLink {
  public static let add = URL(string: "\(KnowItWhere.urlScheme)://add")!

  public static func item(_ id: String) -> URL {
    var components = URLComponents()
    components.scheme = KnowItWhere.urlScheme
    components.host = "item"
    components.path = "/" + id
    return components.url!
  }
}
