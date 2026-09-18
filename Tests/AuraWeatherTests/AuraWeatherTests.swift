import XCTest
@testable import AuraWeather

final class AuraWeatherTests: XCTestCase {
    func testColdWetWeatherSuggestsOuterLayerAndUmbrella() {
        let weather = WeatherSnapshot(city: "Berlin", temperature: 6, feelsLike: 4, precipitation: 1, windSpeed: 12, code: 61, high: 7, low: 2, rainChance: 70)
        let advice = OutfitEngine.advice(for: weather)
        XCTAssertTrue(advice.items.contains("Warm coat"))
        XCTAssertTrue(advice.items.contains("Umbrella"))
    }

    func testWarmWeatherSuggestsTShirt() {
        let weather = WeatherSnapshot(city: "Berlin", temperature: 26, feelsLike: 26, precipitation: 0, windSpeed: 5, code: 0, high: 27, low: 16, rainChance: 0)
        XCTAssertTrue(OutfitEngine.advice(for: weather).items.contains("T-shirt"))
    }
}
