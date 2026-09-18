import Combine
import CoreLocation
import Foundation

@MainActor
final class WeatherStore: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var snapshot: WeatherSnapshot = .preview
    @Published private(set) var forecast: [ForecastDay] = []
    @Published private(set) var isLoading = false
    @Published private(set) var status = "Using Berlin as a preview"
    @Published private(set) var geminiNote: String?
    @Published private(set) var geminiStatus = "Local outfit advice is active"
    @Published private(set) var hasGeminiKey = false

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var cachedGeminiKey: String?

    override init() {
        super.init()
        cachedGeminiKey = KeychainStore.geminiKey()
        hasGeminiKey = cachedGeminiKey != nil
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        Task { await refresh(latitude: 52.52, longitude: 13.405, city: "Berlin") }
    }

    func requestCurrentLocation() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorized:
            locationManager.requestLocation()
        default:
            status = "Location access is off — showing Berlin"
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let allowed = manager.authorizationStatus == .authorized || manager.authorizationStatus == .authorizedAlways
        guard allowed else { return }
        Task { @MainActor [weak self] in self?.locationManager.requestLocation() }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            let city = await self.cityName(for: location) ?? "Your location"
            await self.refresh(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, city: city)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in self?.status = "Location unavailable — showing Berlin" }
    }

    func refreshCurrentWeather() {
        requestCurrentLocation()
    }

    func useCity(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        Task {
            do {
                guard let place = try await geocoder.geocodeAddressString(trimmed).first?.location else {
                    status = "City not found"
                    return
                }
                let resolvedName = await cityName(for: place) ?? trimmed
                await refresh(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude, city: resolvedName)
            } catch {
                status = "City not found — try a more specific name"
            }
        }
    }

    func saveGeminiKey(_ key: String) {
        do {
            let cleanedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
            try KeychainStore.saveGeminiKey(cleanedKey)
            cachedGeminiKey = cleanedKey
            hasGeminiKey = true
            geminiStatus = "Gemini is ready — your key is in macOS Keychain"
        } catch {
            geminiStatus = "Couldn’t save the Gemini key"
        }
    }

    func generateGeminiAdvice() {
        guard let key = cachedGeminiKey ?? KeychainStore.geminiKey(), !key.isEmpty else {
            geminiStatus = "Add a Gemini API key in Settings first"
            return
        }
        geminiStatus = "Thinking about your outfit…"
        Task {
            do {
                geminiNote = try await GeminiAdvisor().outfitNote(for: snapshot, apiKey: key)
                geminiStatus = "AI outfit note · city-level weather only"
            } catch {
                if let urlError = error as? URLError, urlError.code == .timedOut {
                    geminiStatus = GeminiError.timedOut.localizedDescription
                } else {
                    geminiStatus = error.localizedDescription
                }
            }
        }
    }

    private func cityName(for location: CLLocation) async -> String? {
        do { return try await geocoder.reverseGeocodeLocation(location).first?.locality }
        catch { return nil }
    }

    private func refresh(latitude: Double, longitude: Double, city: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
            components.queryItems = [
                .init(name: "latitude", value: String(latitude)),
                .init(name: "longitude", value: String(longitude)),
                .init(name: "current", value: "temperature_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m"),
                .init(name: "daily", value: "temperature_2m_max,temperature_2m_min,precipitation_probability_max,weather_code"),
                .init(name: "forecast_days", value: "5"),
                .init(name: "timezone", value: "auto")
            ]
            let (data, _) = try await URLSession.shared.data(from: components.url!)
            let decoder = JSONDecoder()
            let dayFormatter = DateFormatter()
            dayFormatter.locale = Locale(identifier: "en_US_POSIX")
            dayFormatter.dateFormat = "yyyy-MM-dd"
            decoder.dateDecodingStrategy = .formatted(dayFormatter)
            let response = try decoder.decode(OpenMeteoResponse.self, from: data)
            let daily = response.daily
            snapshot = WeatherSnapshot(
                city: city, temperature: response.current.temperature2m,
                feelsLike: response.current.apparentTemperature,
                precipitation: response.current.precipitation,
                windSpeed: response.current.windSpeed10m,
                code: response.current.weatherCode,
                high: daily.temperatureMax.first ?? response.current.temperature2m,
                low: daily.temperatureMin.first ?? response.current.temperature2m,
                rainChance: daily.rainChance.first ?? 0
            )
            forecast = zip(zip(zip(daily.time, daily.temperatureMax), daily.temperatureMin), zip(daily.rainChance, daily.weatherCode)).map {
                ForecastDay(date: $0.0.0.0, high: $0.0.0.1, low: $0.0.1, rainChance: $0.1.0, code: $0.1.1)
            }
            status = "Live conditions · updated now"
        } catch {
            status = "Couldn’t refresh — showing the last conditions"
        }
    }
}

private struct OpenMeteoResponse: Decodable {
    let current: Current
    let daily: Daily
    struct Current: Decodable {
        let temperature2m: Double
        let apparentTemperature: Double
        let precipitation: Double
        let weatherCode: Int
        let windSpeed10m: Double
        enum CodingKeys: String, CodingKey {
            case temperature2m = "temperature_2m", apparentTemperature = "apparent_temperature"
            case precipitation, weatherCode = "weather_code", windSpeed10m = "wind_speed_10m"
        }
    }
    struct Daily: Decodable {
        let time: [Date]
        let temperatureMax: [Double]
        let temperatureMin: [Double]
        let rainChance: [Int]
        let weatherCode: [Int]
        enum CodingKeys: String, CodingKey {
            case time, temperatureMax = "temperature_2m_max", temperatureMin = "temperature_2m_min"
            case rainChance = "precipitation_probability_max", weatherCode = "weather_code"
        }
    }
}
