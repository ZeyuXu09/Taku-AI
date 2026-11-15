import SwiftUI
import WidgetKit

struct WidgetGame: Decodable {
  let opponent: String
  let gameAtMs: Double
  let isHome: Bool

  var gameAt: Date {
    Date(timeIntervalSince1970: gameAtMs / 1000)
  }

  var place: String { isHome ? "Home" : "Away" }

  var timeLabel: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE h:mm a"
    return formatter.string(from: gameAt)
  }

  var countdown: String {
    let seconds = gameAt.timeIntervalSinceNow
    if seconds <= 0 { return "Now" }
    let days = Int(seconds) / 86_400
    let hours = (Int(seconds) % 86_400) / 3_600
    if days > 0 { return "\(days)d" }
    if hours > 0 { return "\(hours)h" }
    let minutes = max(1, Int(seconds) / 60)
    return "\(minutes)m"
  }

  static let preview = WidgetGame(
    opponent: "Rivals",
    gameAtMs: Date().addingTimeInterval(86_400).timeIntervalSince1970 * 1000,
    isHome: true
  )
}

struct GameEntry: TimelineEntry {
  let date: Date
  let games: [WidgetGame]

  var next: WidgetGame? { games.first }
}

enum GameWidgetStore {
  static let appGroup = "group.com.peakform.peakformAi"
  static let gamesKey = "upcoming_games_json"

  static func loadUpcoming() -> [WidgetGame] {
    guard
      let raw = UserDefaults(suiteName: appGroup)?.string(forKey: gamesKey),
      let data = raw.data(using: .utf8),
      let decoded = try? JSONDecoder().decode([WidgetGame].self, from: data)
    else {
      return []
    }
    return decoded.filter { $0.gameAt > Date() }
  }
}

struct GameTimelineProvider: TimelineProvider {
  func placeholder(in context: Context) -> GameEntry {
    GameEntry(date: Date(), games: [.preview])
  }

  func getSnapshot(in context: Context, completion: @escaping (GameEntry) -> Void) {
    let games = GameWidgetStore.loadUpcoming()
    completion(
      GameEntry(
        date: Date(),
        games: games.isEmpty ? [.preview] : games
      )
    )
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<GameEntry>) -> Void) {
    let games = GameWidgetStore.loadUpcoming()
    let now = Date()
    var refresh = now.addingTimeInterval(30 * 60)
    if let next = games.first {
      refresh = min(refresh, next.gameAt)
    }
    completion(
      Timeline(
        entries: [GameEntry(date: now, games: games)],
        policy: .after(refresh)
      )
    )
  }
}

struct GameLockScreenWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: "GameLockScreenWidget",
      provider: GameTimelineProvider()
    ) { entry in
      LockScreenGameView(entry: entry)
        .containerBackground(for: .widget) {
          AccessoryWidgetBackground()
        }
    }
    .configurationDisplayName("Next Game")
    .description("See your next scheduled game on the Lock Screen.")
    .supportedFamilies([
      .accessoryRectangular,
      .accessoryCircular,
      .accessoryInline,
    ])
  }
}

struct GameHomeScreenWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: "GameHomeScreenWidget",
      provider: GameTimelineProvider()
    ) { entry in
      HomeScreenGameView(entry: entry)
        .containerBackground(for: .widget) {
          Color("WidgetBackground")
        }
    }
    .configurationDisplayName("Upcoming Games")
    .description("See your next scheduled games.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct LockScreenGameView: View {
  let entry: GameEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    switch family {
    case .accessoryCircular:
      ZStack {
        AccessoryWidgetBackground()
        VStack(spacing: 1) {
          Text(entry.next?.countdown ?? "--")
            .font(.headline.weight(.bold))
          Text("GAME")
            .font(.caption2)
        }
      }
    case .accessoryInline:
      Text(inlineText)
    default:
      VStack(alignment: .leading, spacing: 2) {
        Text("NEXT GAME")
          .font(.caption2.weight(.semibold))
        if let game = entry.next {
          Text("vs \(game.opponent)")
            .font(.headline)
            .lineLimit(1)
          Text("\(game.timeLabel) · \(game.place)")
            .font(.caption2)
            .lineLimit(1)
        } else {
          Text("No upcoming games")
            .font(.headline)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private var inlineText: String {
    guard let game = entry.next else { return "No upcoming games" }
    return "vs \(game.opponent) · \(game.timeLabel)"
  }
}

struct HomeScreenGameView: View {
  let entry: GameEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    if family == .systemMedium {
      medium
    } else {
      small
    }
  }

  private var small: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("NEXT GAME")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
      if let game = entry.next {
        Text("vs \(game.opponent)")
          .font(.headline.weight(.bold))
          .lineLimit(2)
        Text("\(game.timeLabel) · \(game.place)")
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer(minLength: 0)
        Text(game.countdown)
          .font(.title2.weight(.heavy))
      } else {
        Spacer(minLength: 0)
        Text("No upcoming games")
          .font(.subheadline.weight(.semibold))
        Spacer(minLength: 0)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }

  private var medium: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("UPCOMING GAMES")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
      if entry.games.isEmpty {
        Text("No upcoming games")
          .font(.headline)
        Spacer(minLength: 0)
      } else {
        ForEach(Array(entry.games.prefix(3).enumerated()), id: \.offset) { _, game in
          HStack {
            Text("vs \(game.opponent)")
              .font(.subheadline.weight(.semibold))
              .lineLimit(1)
            Spacer()
            Text("\(game.timeLabel) · \(game.place)")
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }
        Spacer(minLength: 0)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }
}

@main
struct GameLockScreenWidgetBundle: WidgetBundle {
  var body: some Widget {
    GameLockScreenWidget()
    GameHomeScreenWidget()
  }
}
