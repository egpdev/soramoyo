import Foundation

enum TemperatureUnit: String, CaseIterable, Identifiable {
    case celsius, fahrenheit
    var id: String { rawValue }
    var label: String { self == .celsius ? "Celsius · °C" : "Fahrenheit · °F" }
}

struct WeatherSnapshot: Equatable, Codable {
    let city: String
    let temperature: Double
    let feelsLike: Double
    let precipitation: Double
    let windSpeed: Double
    let code: Int
    let high: Double
    let low: Double
    let rainChance: Int

    static let preview = WeatherSnapshot(
        city: "Berlin", temperature: 17, feelsLike: 15, precipitation: 0,
        windSpeed: 14, code: 2, high: 19, low: 10, rainChance: 20
    )

    var condition: String {
        switch code {
        case 0: return "Clear"
        case 1, 2: return "Partly cloudy"
        case 3: return "Overcast"
        case 45, 48: return "Fog"
        case 51, 53, 55, 56, 57: return "Drizzle"
        case 61, 63, 65, 66, 67, 80, 81, 82: return "Rain"
        case 71, 73, 75, 77, 85, 86: return "Snow"
        case 95, 96, 99: return "Thunderstorm"
        default: return "Weather"
        }
    }

    var symbol: String {
        switch code {
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

    func temperatureText(_ value: Double, unit: TemperatureUnit) -> String {
        let converted = unit == .celsius ? value : (value * 9 / 5) + 32
        return "\(Int(converted.rounded()))°"
    }
}

struct ForecastDay: Identifiable, Equatable, Codable {
    let date: Date
    let high: Double
    let low: Double
    let rainChance: Int
    let code: Int
    var id: Date { date }
}

struct OutfitAdvice: Equatable, Codable {
    let headline: String
    let detail: String
    let items: [String]
}

enum OutfitEngine {
    static func advice(for weather: WeatherSnapshot) -> OutfitAdvice {
        var items: [String] = []
        var headline = "Light layers are enough."
        var detail = "Comfortable for being outside — keep one extra layer nearby."
        let cold = weather.feelsLike < 8
        let cool = weather.feelsLike < 16
        let wet = weather.rainChance >= 35 || weather.precipitation > 0 || (51...67).contains(weather.code)
        let windy = weather.windSpeed >= 24

        if cold {
            headline = "Keep warmth close."
            detail = "It feels cold outside, so make your outer layer do the work."
            items += ["Warm coat", "Knit layer"]
        } else if cool {
            headline = "Take a proper layer."
            detail = "The temperature is mild, but it can feel cooler in the wind."
            items += ["Light jacket", "Long sleeve"]
        } else {
            items += ["T-shirt", "Light overshirt"]
        }

        if wet { items.append("Umbrella") }
        if windy { items.append("Windproof layer") }
        if weather.temperature >= 24 { items = ["T-shirt", "Sunglasses", wet ? "Compact umbrella" : "Water bottle"] }
        return OutfitAdvice(headline: headline, detail: detail, items: Array(items.prefix(3)))
    }
}
