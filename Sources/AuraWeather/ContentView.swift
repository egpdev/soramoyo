import SwiftUI

private enum AuraTab: String { case now = "Now", forecast = "Forecast", settings = "Settings" }

struct ContentView: View {
    @EnvironmentObject private var weather: WeatherStore
    @State private var tab: AuraTab = .now
    @AppStorage("auraTemperatureUnit") private var unitRaw = TemperatureUnit.celsius.rawValue
    @AppStorage("auraLanguage") private var languageRaw = AuraLanguage.german.rawValue
    private var unit: TemperatureUnit { TemperatureUnit(rawValue: unitRaw) ?? .celsius }
    private var language: AuraLanguage { AuraLanguage(rawValue: languageRaw) ?? .german }

    var body: some View {
        HStack(spacing: 0) {
            Sidebar(selection: $tab, language: language)
            Divider().overlay(Color.white.opacity(0.09))
            Group {
                switch tab {
                case .now: NowView(unit: unit, language: language, openSettings: { tab = .settings })
                case .forecast: ForecastView(unit: unit, language: language)
                case .settings: SettingsView(unitRaw: $unitRaw, languageRaw: $languageRaw, language: language, openNow: { tab = .now })
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }.background(Color.black)
    }
}

private struct Sidebar: View {
    @Binding var selection: AuraTab
    let language: AuraLanguage
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) { LiquidMark().frame(width: 32, height: 32); Text("AURA").font(.system(size: 17, weight: .bold, design: .rounded)).tracking(3) }
                .padding(.top, 38).padding(.horizontal, 28)
            VStack(alignment: .leading, spacing: 13) {
                ForEach([AuraTab.now, .forecast, .settings], id: \.rawValue) { item in
                    Button { selection = item } label: { NavItem(icon: item == .now ? "cloud.sun" : item == .forecast ? "calendar" : "slider.horizontal.3", label: language.t(item == .now ? "now" : item == .forecast ? "forecast" : "settings"), active: selection == item) }.buttonStyle(.plain)
                }
            }.padding(.top, 54).padding(.horizontal, 18)
            Spacer()
            VStack(alignment: .leading, spacing: 7) { Text("LOCAL WEATHER").micro(); Text("Location stays on this Mac.").muted() }.padding(28)
        }.frame(width: 210).background(Color.white.opacity(0.025))
    }
}

private struct NowView: View {
    @EnvironmentObject private var weather: WeatherStore
    let unit: TemperatureUnit; let language: AuraLanguage; let openSettings: () -> Void
    @State private var showsDayPulse = false
    var body: some View { ScrollView { VStack(alignment: .leading, spacing: 26) { Header(); currentWeather; advice }.padding(42) } }
    private var currentWeather: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 28) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 5) { Text(weather.snapshot.temperatureText(weather.snapshot.temperature, unit: unit).dropLast()).font(.system(size: 116, weight: .ultraLight, design: .rounded)); Text(unit == .celsius ? "°C" : "°F").font(.system(size: 22, weight: .medium)).foregroundStyle(.white.opacity(0.55)) }
                    Label(weather.snapshot.condition, systemImage: weather.snapshot.symbol).font(.system(size: 16, weight: .medium)).foregroundStyle(Color.ice)
                    Text("H \(weather.snapshot.temperatureText(weather.snapshot.high, unit: unit))  ·  L \(weather.snapshot.temperatureText(weather.snapshot.low, unit: unit))").font(.system(size: 14, design: .monospaced)).foregroundStyle(.white.opacity(0.48))
                }
                Spacer(minLength: 20)
                Button {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) { showsDayPulse.toggle() }
                } label: {
                    LiquidWeatherWidget(snapshot: weather.snapshot, unit: unit)
                        .frame(width: 250, height: 250)
                        .scaleEffect(showsDayPulse ? 1.035 : 1)
                        .shadow(color: Color.ice.opacity(showsDayPulse ? 0.34 : 0.18), radius: showsDayPulse ? 42 : 28)
                }.buttonStyle(.plain).accessibilityLabel("Open today’s weather")
            }
            if showsDayPulse {
                DayPulse(snapshot: weather.snapshot, hours: weather.hourlyForecast, unit: unit) {
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.78)) { showsDayPulse = false }
                }
                .frame(width: 292)
                .offset(x: -232, y: 22)
                .transition(.asymmetric(insertion: .scale(scale: 0.82, anchor: .bottomTrailing).combined(with: .opacity), removal: .scale(scale: 0.92, anchor: .bottomTrailing).combined(with: .opacity)))
                .zIndex(3)
            }
        }.padding(34).glassPanel()
    }
    private var advice: some View {
        let local = OutfitEngine.advice(for: weather.snapshot)
        return VStack(alignment: .leading, spacing: 17) {
            HStack(alignment: .top, spacing: 20) {
                Image(systemName: "sparkles").font(.system(size: 19, weight: .medium)).foregroundStyle(Color.ice).frame(width: 42, height: 42).background(Color.ice.opacity(0.16), in: Circle())
                VStack(alignment: .leading, spacing: 7) { Text(weather.geminiNote == nil ? "WHAT TO WEAR" : "AURA AI NOTE").micro(); Text(weather.geminiNote ?? local.headline).font(.system(size: 22, weight: .medium, design: .rounded)); Text(weather.geminiNote ?? local.detail).font(.system(size: 14)).foregroundStyle(.white.opacity(0.57)) }
                Spacer(); if weather.geminiNote == nil { VStack(alignment: .trailing, spacing: 8) { ForEach(local.items, id: \.self) { Tag(text: $0) } } }
            }
            Divider().overlay(Color.white.opacity(0.09))
            HStack { Text(weather.geminiStatus).font(.system(size: 12)).foregroundStyle(.white.opacity(0.44)); Spacer(); if weather.hasGeminiKey { Button("Ask Gemini") { weather.generateGeminiAdvice() }.buttonStyle(AuraButtonStyle()) } else { Button("Enable Gemini") { openSettings() }.buttonStyle(AuraButtonStyle()) } }
        }.padding(24).glassPanel()
    }
}

private struct DayPulse: View {
    let snapshot: WeatherSnapshot
    let hours: [HourlyForecast]
    let unit: TemperatureUnit
    let dismiss: () -> Void

    private var visibleHours: [HourlyForecast] { Array(hours.prefix(4)) }
    private var summary: String {
        let rain = snapshot.rainChance >= 35 ? "Rain is likely later today." : "Rain is unlikely today."
        return "Mild now, reaching \(snapshot.temperatureText(snapshot.high, unit: unit)). \(rain)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack { Text("DAY PULSE").micro(); Spacer(); Button(action: dismiss) { Image(systemName: "xmark").font(.system(size: 10, weight: .bold)).frame(width: 24, height: 24).background(.white.opacity(0.10), in: Circle()) }.buttonStyle(.plain) }
            Text(summary).font(.system(size: 14, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.9)).fixedSize(horizontal: false, vertical: true)
            if visibleHours.isEmpty {
                Text("Hourly detail will appear after the next refresh.").muted()
            } else {
                ForEach(visibleHours) { hour in
                    HStack(spacing: 10) {
                        Text(hour.date.formatted(.dateTime.hour(.defaultDigits(amPM: .abbreviated)))).font(.system(size: 11, design: .monospaced)).frame(width: 42, alignment: .leading).foregroundStyle(.white.opacity(0.5))
                        Image(systemName: hour.symbol).font(.system(size: 13)).foregroundStyle(Color.ice).frame(width: 17)
                        Text(hour.condition).font(.system(size: 12)).foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Text(snapshot.temperatureText(hour.temperature, unit: unit)).font(.system(size: 12, weight: .semibold, design: .rounded))
                        if hour.rainChance > 0 { Text("\(hour.rainChance)%").font(.system(size: 10, design: .monospaced)).foregroundStyle(.white.opacity(0.45)) }
                    }
                }
            }
        }
        .padding(18)
        .background(.black.opacity(0.88), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.ice.opacity(0.32), lineWidth: 1))
        .shadow(color: .black.opacity(0.55), radius: 24, y: 12)
    }
}

private struct ForecastView: View {
    @EnvironmentObject private var weather: WeatherStore
    let unit: TemperatureUnit; let language: AuraLanguage
    var days: [ForecastDay] { weather.forecast.isEmpty ? previewForecast : weather.forecast }
    var body: some View { ScrollView { VStack(alignment: .leading, spacing: 26) {
        Header(title: "Forecast", subtitle: "THE WEEK AHEAD")
        HStack(spacing: 12) { ForEach(days) { ForecastCell(day: $0, unit: unit) } }
        VStack(alignment: .leading, spacing: 16) { Text(language.t("outside")).micro(); HStack(spacing: 12) { MetricCard(label: language.t("feelsLike"), value: weather.snapshot.temperatureText(weather.snapshot.feelsLike, unit: unit), icon: "thermometer.medium"); MetricCard(label: weather.snapshot.precipitation > 0 ? language.t("rainPeak") : language.t("nowDry"), value: weather.snapshot.precipitation > 0 ? "\(weather.snapshot.rainChance)%" : "0 mm", icon: "drop.fill"); MetricCard(label: language.t("wind"), value: "\(Int(weather.snapshot.windSpeed.rounded())) km/h", icon: "wind") }; Text(weather.snapshot.precipitation > 0 ? language.t("rainPeak") : "\(weather.snapshot.rainChance)% · \(language.t("probability"))").muted() }.padding(25).glassPanel()
        Text("Forecast refreshes whenever you use your location or set a city in Settings.").muted()
    }.padding(42) } }
    private var previewForecast: [ForecastDay] { (0..<5).compactMap { offset in Calendar.current.date(byAdding: .day, value: offset, to: .now).map { ForecastDay(date: $0, high: 18 + Double(offset), low: 10, rainChance: 15, code: offset == 2 ? 61 : 2) } } }
}

private struct SettingsView: View {
    @EnvironmentObject private var weather: WeatherStore
    @Binding var unitRaw: String; @Binding var languageRaw: String; let language: AuraLanguage; let openNow: () -> Void
    @State private var city = ""; @State private var key = ""
    var body: some View { ScrollView { VStack(alignment: .leading, spacing: 23) {
        Header(title: "Settings", subtitle: "MAKE IT YOURS")
        VStack(alignment: .leading, spacing: 10) { Text(language.t("location")).micro(); Text(language.t("placeHelp")).muted(); HStack { TextField(language.t("placeHint"), text: $city).textFieldStyle(.plain).padding(12).background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10)).onChange(of: city) { weather.searchPlaces(matching: $0) }; Button(language.t("usePlace")) { weather.useCity(named: city) }.buttonStyle(AuraButtonStyle()); Button(language.t("useLocation")) { weather.requestCurrentLocation() }.buttonStyle(AuraSecondaryButtonStyle()) }; ForEach(weather.locationSuggestions) { suggestion in Button { city = suggestion.query; weather.useCity(named: suggestion.query) } label: { HStack { Image(systemName: "mappin.and.ellipse").foregroundStyle(Color.ice); Text(suggestion.title); Spacer() }.font(.system(size: 13, weight: .medium)).padding(10).background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 9)) }.buttonStyle(.plain) } }.padding(24).glassPanel()
        VStack(alignment: .leading, spacing: 15) { Text(language.t("units")).micro(); Picker("Temperature", selection: $unitRaw) { ForEach(TemperatureUnit.allCases) { Text($0.label).tag($0.rawValue) } }.pickerStyle(.segmented) }.padding(24).glassPanel()
        VStack(alignment: .leading, spacing: 15) { Text(language.t("language")).micro(); Picker("Language", selection: $languageRaw) { ForEach(AuraLanguage.allCases) { Text($0.label).tag($0.rawValue) } }.pickerStyle(.segmented) }.padding(24).glassPanel()
        VStack(alignment: .leading, spacing: 13) { Text("GEMINI OUTFIT ADVICE").micro(); Text("Optional. Asking Gemini sends city-level weather values only — never your exact coordinates. The key is saved in macOS Keychain, never in the project.").muted(); HStack { SecureField(weather.hasGeminiKey ? "Key saved — enter a new one to replace it" : "Paste Gemini API key", text: $key).textFieldStyle(.plain).padding(12).background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10)); Button("Save key") { weather.saveGeminiKey(key); key = "" }.buttonStyle(AuraButtonStyle()).disabled(key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }; Text(weather.geminiStatus).font(.system(size: 12)).foregroundStyle(.white.opacity(0.44)) }.padding(24).glassPanel()
        HStack { Spacer(); Button("Back to Now") { openNow() }.buttonStyle(AuraSecondaryButtonStyle()) }
    }.padding(42) } }
}

private struct Header: View {
    @EnvironmentObject private var weather: WeatherStore
    var title: String? = nil; var subtitle: String? = nil
    var body: some View { HStack(alignment: .top) { VStack(alignment: .leading, spacing: 7) { Text(subtitle ?? "WEATHER, MADE QUIET").micro(); Text(title ?? weather.snapshot.city).font(.system(size: 34, weight: .medium, design: .rounded)); if title == nil { HStack(spacing: 7) { Circle().fill(Color.ice).frame(width: 7, height: 7); Text(weather.status).muted() } } }; Spacer(); Button(action: weather.refreshCurrentWeather) { Image(systemName: weather.isLoading ? "arrow.triangle.2.circlepath" : "location.fill").font(.system(size: 14, weight: .semibold)).frame(width: 40, height: 40).background(.white.opacity(0.10), in: Circle()) }.buttonStyle(.plain).foregroundStyle(.white) } }
}

private struct NavItem: View { let icon: String; let label: String; let active: Bool; var body: some View { Label(label, systemImage: icon).font(.system(size: 14, weight: active ? .semibold : .medium)).foregroundStyle(active ? .white : .white.opacity(0.52)).padding(.horizontal, 13).padding(.vertical, 10).frame(maxWidth: .infinity, alignment: .leading).background(active ? .white.opacity(0.10) : .clear, in: RoundedRectangle(cornerRadius: 11)) } }
private struct ForecastCell: View { let day: ForecastDay; let unit: TemperatureUnit; var body: some View { VStack(spacing: 13) { Text(day.date.formatted(.dateTime.weekday(.narrow))).font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundStyle(.white.opacity(0.54)); Image(systemName: WeatherSnapshot(city: "", temperature: 0, feelsLike: 0, precipitation: 0, windSpeed: 0, code: day.code, high: 0, low: 0, rainChance: 0).symbol).font(.system(size: 19)).foregroundStyle(Color.ice); Text(WeatherSnapshot.preview.temperatureText(day.high, unit: unit)).font(.system(size: 16, weight: .semibold, design: .rounded)); Text(WeatherSnapshot.preview.temperatureText(day.low, unit: unit)).font(.system(size: 12)).foregroundStyle(.white.opacity(0.42)); if day.rainChance > 0 { Text("\(day.rainChance)%").font(.system(size: 10, design: .monospaced)).foregroundStyle(.white.opacity(0.36)) } }.frame(maxWidth: .infinity).padding(.vertical, 17).background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 16)) } }
private struct MetricCard: View { let label: String; let value: String; let icon: String; var body: some View { HStack { Image(systemName: icon).foregroundStyle(Color.ice); VStack(alignment: .leading, spacing: 4) { Text(label).micro(); Text(value).font(.system(size: 19, weight: .medium, design: .rounded)) }; Spacer() }.padding(17).frame(maxWidth: .infinity).background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 15)) } }
private struct Tag: View { let text: String; var body: some View { Text(text).font(.system(size: 13, weight: .medium)).padding(.horizontal, 12).padding(.vertical, 7).background(.white.opacity(0.09), in: Capsule()) } }
private struct LiquidWeatherWidget: View { let snapshot: WeatherSnapshot; let unit: TemperatureUnit; var body: some View { ZStack { RoundedRectangle(cornerRadius: 48, style: .continuous).fill(.ultraThinMaterial).opacity(0.55).overlay(RoundedRectangle(cornerRadius: 48).stroke(.white.opacity(0.22), lineWidth: 1)); Circle().fill(Color.ice.opacity(0.15)).blur(radius: 25).frame(width: 150); LiquidMark().frame(width: 112, height: 112); VStack { HStack { Text("AURA").micro(); Spacer(); Text("LIVE").micro() }.foregroundStyle(.white.opacity(0.48)).padding(20); Spacer(); Text(snapshot.temperatureText(snapshot.temperature, unit: unit)).font(.system(size: 27, weight: .medium, design: .rounded)).padding(.bottom, 20) } }.shadow(color: Color.ice.opacity(0.19), radius: 34) } }
private struct LiquidMark: View { var body: some View { ZStack { Circle().fill(.black.opacity(0.48)); Circle().stroke(AngularGradient(colors: [.white.opacity(0.85), .white.opacity(0.10), Color.ice, .white.opacity(0.85)], center: .center), style: StrokeStyle(lineWidth: 6, lineCap: .round, dash: [0.72, 0.22])).padding(8).rotationEffect(.degrees(-38)).shadow(color: .white.opacity(0.42), radius: 7); Image(systemName: "cloud.fill").font(.system(size: 19, weight: .medium)).foregroundStyle(Color.ice) } } }
private struct AuraButtonStyle: ButtonStyle { func makeBody(configuration: Configuration) -> some View { configuration.label.font(.system(size: 13, weight: .semibold)).padding(.horizontal, 14).padding(.vertical, 10).foregroundStyle(.black).background(Color.ice.opacity(configuration.isPressed ? 0.75 : 1), in: Capsule()) } }
private struct AuraSecondaryButtonStyle: ButtonStyle { func makeBody(configuration: Configuration) -> some View { configuration.label.font(.system(size: 13, weight: .semibold)).padding(.horizontal, 14).padding(.vertical, 10).foregroundStyle(.white).background(.white.opacity(configuration.isPressed ? 0.15 : 0.09), in: Capsule()) } }
private extension Color { static let ice = Color(red: 0.69, green: 0.84, blue: 0.96) }
private extension View { func glassPanel() -> some View { background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 28, style: .continuous)).overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(.white.opacity(0.10), lineWidth: 1)) }; func micro() -> some View { font(.system(size: 11, weight: .bold, design: .monospaced)).tracking(1.8).foregroundStyle(.white.opacity(0.45)) }; func muted() -> some View { font(.system(size: 13)).foregroundStyle(.white.opacity(0.52)) } }
