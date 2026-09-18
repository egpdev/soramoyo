// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AuraWeather",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "AuraWeather", targets: ["AuraWeather"])],
    targets: [
        .executableTarget(name: "AuraWeather"),
        .testTarget(name: "AuraWeatherTests", dependencies: ["AuraWeather"])
    ]
)
