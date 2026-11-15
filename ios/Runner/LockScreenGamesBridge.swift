import Flutter
import WidgetKit

enum LockScreenGamesBridge {
  static let channelName = "peakform/lock_screen_games"
  static let appGroup = "group.com.peakform.peakformAi"
  static let gamesKey = "upcoming_games_json"

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "syncGames" else {
        result(FlutterMethodNotImplemented)
        return
      }

      let json = call.arguments as? String ?? "[]"
      UserDefaults(suiteName: appGroup)?.set(json, forKey: gamesKey)
      if #available(iOS 14.0, *) {
        WidgetCenter.shared.reloadAllTimelines()
      }
      result(nil)
    }
  }
}
