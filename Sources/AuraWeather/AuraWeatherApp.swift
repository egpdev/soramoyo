import SwiftUI

@main
struct AuraWeatherApp: App {
    @StateObject private var weather = WeatherStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(weather)
                .frame(minWidth: 900, minHeight: 640)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
