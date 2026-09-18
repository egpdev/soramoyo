import Foundation
import SwiftUI
import WidgetKit

private struct SoramoyoWeather: Equatable {
    let city: String
    let temperature: Double
    let apparentTemperature: Double
    let high: Double
    let low: Double
    let weatherCode: Int

    static let preview = SoramoyoWeather(city: "Berlin", temperature: 18, apparentTemperature: 17, high: 21, low: 14, weatherCode: 2)

    var symbol: String {
        switch weatherCode {
        case 0: return "sun.max.fill"
        case 1, 2: return "cloud.sun.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51...67, 80...82: return "cloud.rain.fill"
        case 71...77, 85, 86: return "cloud.snow.fill"
        case 95...99: return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }

    var condition: String {
        let language = Locale.current.language.languageCode?.identifier ?? "en"
        let key: String
        switch weatherCode {
        case 0: key = "clear"
        case 1, 2: key = "partlyCloudy"
        case 3: key = "cloudy"
        case 45, 48: key = "fog"
        case 51...67, 80...82: key = "rain"
        case 71...77, 85, 86: key = "snow"
        case 95...99: key = "storm"
        default: key = "cloudy"
        }
        let strings: [String: [String: String]] = [
            "en": ["clear": "Clear", "partlyCloudy": "Partly cloudy", "cloudy": "Cloudy", "fog": "Foggy", "rain": "Rain", "snow": "Snow", "storm": "Storm"],
            "de": ["clear": "Klar", "partlyCloudy": "Teilweise bewölkt", "cloudy": "Bewölkt", "fog": "Neblig", "rain": "Regen", "snow": "Schnee", "storm": "Gewitter"],
            "ru": ["clear": "Ясно", "partlyCloudy": "Переменная облачность", "cloudy": "Облачно", "fog": "Туман", "rain": "Дождь", "snow": "Снег", "storm": "Гроза"]
        ]
        return strings[language]?[key] ?? strings["en"]![key]!
    }

    var outfitCue: String {
        let language = Locale.current.language.languageCode?.identifier ?? "en"
        let cue: String
        if (51...67).contains(weatherCode) || (80...82).contains(weatherCode) || (95...99).contains(weatherCode) {
            cue = "rain"
        } else if apparentTemperature <= 8 {
            cue = "cold"
        } else if apparentTemperature <= 16 {
            cue = "layer"
        } else if apparentTemperature >= 27 {
            cue = "hot"
        } else {
            cue = "light"
        }
        let strings: [String: [String: String]] = [
            "en": ["rain": "Take an umbrella", "cold": "Warm jacket", "layer": "Add one layer", "hot": "Keep it light", "light": "Light layers"],
            "de": ["rain": "Schirm mitnehmen", "cold": "Warme Jacke", "layer": "Eine Schicht mehr", "hot": "Leicht anziehen", "light": "Leichte Schichten"],
            "ru": ["rain": "Возьми зонт", "cold": "Тёплая куртка", "layer": "Добавь один слой", "hot": "Одевайся легко", "light": "Лёгкие слои"]
        ]
        return strings[language]?[cue] ?? strings["en"]![cue]!
    }
}

private struct OpenMeteoResponse: Decodable {
    struct Current: Decodable {
        let temperature_2m: Double
        let apparent_temperature: Double
        let weather_code: Int
    }
    struct Daily: Decodable {
        let temperature_2m_max: [Double]
        let temperature_2m_min: [Double]
    }
    let current: Current
    let daily: Daily
}

private func fetchBerlinWeather() async throws -> SoramoyoWeather {
    var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
    components.queryItems = [
        URLQueryItem(name: "latitude", value: "52.5200"),
        URLQueryItem(name: "longitude", value: "13.4050"),
        URLQueryItem(name: "current", value: "temperature_2m,apparent_temperature,weather_code"),
        URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min"),
        URLQueryItem(name: "forecast_days", value: "1"),
        URLQueryItem(name: "timezone", value: "auto")
    ]
    let (data, response) = try await URLSession.shared.data(from: components.url!)
    guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw URLError(.badServerResponse) }
    let payload = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
    return SoramoyoWeather(
        city: "Berlin",
        temperature: payload.current.temperature_2m,
        apparentTemperature: payload.current.apparent_temperature,
        high: payload.daily.temperature_2m_max.first ?? payload.current.temperature_2m,
        low: payload.daily.temperature_2m_min.first ?? payload.current.temperature_2m,
        weatherCode: payload.current.weather_code
    )
}

private struct SoramoyoEntry: TimelineEntry {
    let date: Date
    let weather: SoramoyoWeather
}

private struct SoramoyoProvider: TimelineProvider {
    func placeholder(in context: Context) -> SoramoyoEntry { SoramoyoEntry(date: .now, weather: .preview) }
    func getSnapshot(in context: Context, completion: @escaping (SoramoyoEntry) -> Void) { completion(SoramoyoEntry(date: .now, weather: .preview)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SoramoyoEntry>) -> Void) {
        Task {
            let weather = (try? await fetchBerlinWeather()) ?? .preview
            completion(Timeline(entries: [SoramoyoEntry(date: .now, weather: weather)], policy: .after(.now.addingTimeInterval(30 * 60))))
        }
    }
}

private extension Color {
    static let soramoyoBlue = Color(red: 0.64, green: 0.83, blue: 0.98)
}

private struct WeatherOrb: View {
    let weather: SoramoyoWeather
    let diameter: CGFloat
    var body: some View {
        ZStack {
            Circle().fill(Color(red: 0.10, green: 0.12, blue: 0.14)).shadow(color: .soramoyoBlue.opacity(0.32), radius: 16)
            Circle().stroke(Color.white.opacity(0.10), lineWidth: 10)
            Circle()
                .trim(from: 0.04, to: 0.80)
                .stroke(AngularGradient(colors: [.soramoyoBlue, .white.opacity(0.92), .soramoyoBlue.opacity(0.25)], center: .center), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(18))
            Image(systemName: weather.symbol)
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: diameter * 0.25, weight: .semibold))
                .foregroundStyle(Color.soramoyoBlue)
        }
        .frame(width: diameter, height: diameter)
    }
}

private struct SoramoyoWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SoramoyoEntry
    var body: some View {
        Group { if family == .systemSmall { smallView } else { mediumView } }
            .containerBackground(for: .widget) {
                ZStack {
                    Color.black
                    RadialGradient(colors: [Color.soramoyoBlue.opacity(0.10), .clear], center: .topTrailing, startRadius: 0, endRadius: 230)
                }
            }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("空模様").font(.system(size: 11, weight: .bold, design: .monospaced)).tracking(2).foregroundStyle(.secondary)
                Spacer()
                Text(entry.weather.city.uppercased()).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            HStack(spacing: 11) {
                WeatherOrb(weather: entry.weather, diameter: 58)
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(Int(entry.weather.temperature.rounded()))°").font(.system(size: 31, weight: .medium, design: .rounded)).monospacedDigit()
                    Text(entry.weather.condition).font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.soramoyoBlue).lineLimit(1).minimumScaleFactor(0.7)
                }
            }
            Spacer(minLength: 0)
            Text(entry.weather.outfitCue).font(.system(size: 12, weight: .semibold)).lineLimit(1)
        }
        .padding(2)
    }

    private var mediumView: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text("SORAMOYO").font(.system(size: 11, weight: .bold, design: .monospaced)).tracking(2.5).foregroundStyle(.secondary)
                Text(entry.weather.city).font(.system(size: 18, weight: .semibold, design: .rounded))
                Spacer(minLength: 0)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(Int(entry.weather.temperature.rounded()))°").font(.system(size: 42, weight: .medium, design: .rounded)).monospacedDigit()
                    Text("C").font(.system(size: 14, weight: .bold)).foregroundStyle(.secondary)
                }
                Text(entry.weather.condition).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.soramoyoBlue)
                Text("H \(Int(entry.weather.high.rounded()))°  ·  L \(Int(entry.weather.low.rounded()))°").font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            VStack(spacing: 8) {
                WeatherOrb(weather: entry.weather, diameter: 88)
                Text(entry.weather.outfitCue).font(.system(size: 12, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.75)
            }
        }
        .padding(2)
    }
}

@main
struct SoramoyoWeatherWidget: Widget {
    let kind = "SoramoyoWeatherWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SoramoyoProvider()) { entry in SoramoyoWidgetView(entry: entry) }
            .configurationDisplayName("SORAMOYO Weather")
            .description("Quiet live weather and a simple outfit cue.")
            .supportedFamilies([.systemSmall, .systemMedium])
            .contentMarginsDisabled()
    }
}
