import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var weather: WeatherStore

    var body: some View {
        HStack(spacing: 0) {
            Sidebar()
            Divider().overlay(Color.white.opacity(0.09))
            mainContent
        }
        .background(Color.black)
    }

    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                header
                currentWeather
                advice
                forecast
            }
            .padding(42)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 7) {
                Text("WEATHER, MADE QUIET")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .tracking(2.5)
                    .foregroundStyle(.white.opacity(0.46))
                Text(weather.snapshot.city)
                    .font(.system(size: 34, weight: .medium, design: .rounded))
                HStack(spacing: 7) {
                    Circle().fill(Color(red: 0.62, green: 0.81, blue: 0.96)).frame(width: 7, height: 7)
                    Text(weather.status)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.52))
                }
            }
            Spacer()
            Button(action: weather.refreshCurrentWeather) {
                Image(systemName: weather.isLoading ? "arrow.triangle.2.circlepath" : "location.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.10), in: Circle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .rotationEffect(.degrees(weather.isLoading ? 360 : 0))
            .animation(weather.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: weather.isLoading)
        }
    }

    private var currentWeather: some View {
        HStack(spacing: 28) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("\(Int(weather.snapshot.temperature.rounded()))")
                        .font(.system(size: 116, weight: .ultraLight, design: .rounded))
                    Text("°C").font(.system(size: 22, weight: .medium)).foregroundStyle(.white.opacity(0.55))
                }
                Label(weather.snapshot.condition, systemImage: weather.snapshot.symbol)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(red: 0.70, green: 0.84, blue: 0.95))
                Text("H \(Int(weather.snapshot.high.rounded()))°  ·  L \(Int(weather.snapshot.low.rounded()))°")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.48))
            }
            Spacer(minLength: 20)
            LiquidWeatherWidget(snapshot: weather.snapshot)
                .frame(width: 250, height: 250)
        }
        .padding(34)
        .glassPanel()
    }

    private var advice: some View {
        let outfit = OutfitEngine.advice(for: weather.snapshot)
        return HStack(alignment: .top, spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(Color(red: 0.69, green: 0.84, blue: 0.96))
                .frame(width: 42, height: 42)
                .background(Color(red: 0.45, green: 0.67, blue: 0.87).opacity(0.17), in: Circle())
            VStack(alignment: .leading, spacing: 7) {
                Text("WHAT TO WEAR")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.8)
                    .foregroundStyle(.white.opacity(0.45))
                Text(outfit.headline).font(.system(size: 22, weight: .medium, design: .rounded))
                Text(outfit.detail).font(.system(size: 14)).foregroundStyle(.white.opacity(0.57))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                ForEach(outfit.items, id: \.self) { item in
                    Text(item).font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(.white.opacity(0.09), in: Capsule())
                }
            }
        }
        .padding(24)
        .glassPanel()
    }

    private var forecast: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("NEXT FIVE DAYS")
                .font(.system(size: 11, weight: .bold, design: .monospaced)).tracking(1.8).foregroundStyle(.white.opacity(0.45))
            HStack(spacing: 10) {
                ForEach(weather.forecast.isEmpty ? previewForecast : weather.forecast) { day in
                    ForecastCell(day: day)
                }
            }
        }
    }

    private var previewForecast: [ForecastDay] {
        (0..<5).compactMap { offset in
            Calendar.current.date(byAdding: .day, value: offset, to: .now).map { ForecastDay(date: $0, high: 18 + Double(offset), low: 10, rainChance: 15, code: offset == 2 ? 61 : 2) }
        }
    }
}

private struct Sidebar: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                LiquidMark().frame(width: 32, height: 32)
                Text("AURA").font(.system(size: 17, weight: .bold, design: .rounded)).tracking(3)
            }
            .padding(.top, 38).padding(.horizontal, 28)
            VStack(alignment: .leading, spacing: 13) {
                NavItem(icon: "cloud.sun", label: "Now", active: true)
                NavItem(icon: "calendar", label: "Forecast", active: false)
                NavItem(icon: "slider.horizontal.3", label: "Settings", active: false)
            }
            .padding(.top, 54).padding(.horizontal, 18)
            Spacer()
            VStack(alignment: .leading, spacing: 7) {
                Text("LOCAL WEATHER").font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(1.4)
                Text("Location stays on this Mac.").font(.system(size: 11)).foregroundStyle(.white.opacity(0.42))
            }
            .padding(28)
        }
        .frame(width: 210)
        .background(Color.white.opacity(0.025))
    }
}

private struct NavItem: View {
    let icon: String; let label: String; let active: Bool
    var body: some View {
        Label(label, systemImage: icon).font(.system(size: 14, weight: active ? .semibold : .medium))
            .foregroundStyle(active ? .white : .white.opacity(0.52))
            .padding(.horizontal, 13).padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(active ? .white.opacity(0.10) : .clear, in: RoundedRectangle(cornerRadius: 11))
    }
}

private struct ForecastCell: View {
    let day: ForecastDay
    var body: some View {
        VStack(spacing: 13) {
            Text(day.date.formatted(.dateTime.weekday(.narrow))).font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundStyle(.white.opacity(0.54))
            Image(systemName: WeatherSnapshot.preview.code == day.code ? "cloud.sun.fill" : WeatherSnapshot(city: "", temperature: 0, feelsLike: 0, precipitation: 0, windSpeed: 0, code: day.code, high: 0, low: 0, rainChance: 0).symbol)
                .font(.system(size: 19)).foregroundStyle(Color(red: 0.69, green: 0.84, blue: 0.96))
            Text("\(Int(day.high.rounded()))°").font(.system(size: 16, weight: .semibold, design: .rounded))
            Text("\(Int(day.low.rounded()))°").font(.system(size: 12)).foregroundStyle(.white.opacity(0.42))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 17)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct LiquidWeatherWidget: View {
    let snapshot: WeatherSnapshot
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 48, style: .continuous)
                .fill(.ultraThinMaterial).opacity(0.55)
                .overlay(RoundedRectangle(cornerRadius: 48).stroke(.white.opacity(0.22), lineWidth: 1))
            Circle().fill(Color(red: 0.59, green: 0.79, blue: 0.95).opacity(0.15)).blur(radius: 25).frame(width: 150)
            LiquidMark().frame(width: 112, height: 112)
            VStack {
                HStack { Text("AURA").font(.system(size: 9, weight: .bold, design: .monospaced)).tracking(2); Spacer(); Text("LIVE").font(.system(size: 9, weight: .bold, design: .monospaced)) }
                    .foregroundStyle(.white.opacity(0.48)).padding(20)
                Spacer()
                Text("\(Int(snapshot.temperature.rounded()))°").font(.system(size: 27, weight: .medium, design: .rounded)).padding(.bottom, 20)
            }
        }
        .shadow(color: Color(red: 0.54, green: 0.75, blue: 0.93).opacity(0.19), radius: 34)
    }
}

private struct LiquidMark: View {
    var body: some View {
        ZStack {
            Circle().fill(.black.opacity(0.48))
            Circle().stroke(AngularGradient(colors: [.white.opacity(0.85), .white.opacity(0.10), Color(red: 0.56, green: 0.78, blue: 0.96), .white.opacity(0.85)], center: .center), style: StrokeStyle(lineWidth: 6, lineCap: .round, dash: [0.72, 0.22]))
                .padding(8).rotationEffect(.degrees(-38)).shadow(color: .white.opacity(0.42), radius: 7)
            Image(systemName: "cloud.fill").font(.system(size: 19, weight: .medium)).foregroundStyle(Color(red: 0.68, green: 0.84, blue: 0.96))
        }
    }
}

private extension View {
    func glassPanel() -> some View {
        self.background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(.white.opacity(0.10), lineWidth: 1))
    }
}
