import Foundation

struct GeminiAdvisor {
    func outfitNote(for weather: WeatherSnapshot, hourly: [HourlyForecast], language: AuraLanguage, apiKey: String) async throws -> String {
        let nextHours = hourly.prefix(6).map { "\($0.date.formatted(.dateTime.hour())): \(Int($0.temperature.rounded()))C, \($0.rainChance)% precipitation" }.joined(separator: "; ")
        let prompt = """
        You are a personal stylist, not a chatbot. Return exactly one complete, useful outfit sentence in \(language == .russian ? "Russian" : language == .german ? "German" : "English"). Name at least three concrete items: top, outer layer if needed, bottoms, and shoes. Never start with only “Wear”. No greetings or emojis. Area: \(weather.city). Current condition: \(weather.condition). Temperature: \(Int(weather.temperature.rounded()))C, feels like \(Int(weather.feelsLike.rounded()))C, wind \(Int(weather.windSpeed.rounded())) km/h. Peak rain probability today: \(weather.rainChance)%. Next hours: \(nextHours). A probability is not rain happening now; mention this if rain is relevant.
        """
        // Gemini 2.5 Flash is no longer available to newly created API keys.
        // 3.6 Flash is the current fast text model exposed for this key.
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 18
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = try JSONEncoder().encode(GeminiRequest(contents: [.init(parts: [.init(text: prompt)])], generationConfig: .init(temperature: 0.35, maxOutputTokens: 100)))
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw GeminiError.requestFailed }
        guard 200..<300 ~= http.statusCode else { throw GeminiError.httpStatus(http.statusCode) }
        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        let text = decoded.candidates?.first?.content.parts.compactMap(\.text).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard text.split(whereSeparator: \.isWhitespace).count >= 5 else { return fallbackOutfit(for: weather, language: language) }
        return text
    }

    private func fallbackOutfit(for weather: WeatherSnapshot, language: AuraLanguage) -> String {
        if language == .russian { return weather.feelsLike < 16 ? "Лонгслив, лёгкая куртка, джинсы и кроссовки; зонт возьми только если вероятность дождя вырастет." : "Футболка, лёгкая рубашка, джинсы и кроссовки — на вечер захвати тонкий слой." }
        if language == .german { return weather.feelsLike < 16 ? "Longsleeve, leichte Jacke, Jeans und Sneaker; nimm einen Schirm nur bei steigender Regenwahrscheinlichkeit." : "T-Shirt, leichtes Overshirt, Jeans und Sneaker; für den Abend eine dünne Lage einpacken." }
        return weather.feelsLike < 16 ? "Long-sleeve tee, light jacket, jeans and sneakers; take an umbrella only if the rain chance rises." : "T-shirt, light overshirt, jeans and sneakers; bring one thin layer for the evening." 
    }
}

private struct GeminiRequest: Encodable {
    let contents: [Content]
    let generationConfig: GenerationConfig
    struct Content: Encodable { let parts: [Part] }
    struct Part: Encodable { let text: String }
    struct GenerationConfig: Encodable { let temperature: Double; let maxOutputTokens: Int }
}

private struct GeminiResponse: Decodable {
    let candidates: [Candidate]?
    struct Candidate: Decodable { let content: Content }
    struct Content: Decodable { let parts: [Part] }
    struct Part: Decodable { let text: String? }
}

enum GeminiError: LocalizedError { case requestFailed, emptyResponse, httpStatus(Int), timedOut
    var errorDescription: String? {
        switch self {
        case .requestFailed: return "Gemini couldn’t answer. Check the connection."
        case .emptyResponse: return "Gemini returned no outfit note."
        case .httpStatus(let code): return "Gemini returned HTTP \(code). The key is saved, but this request was rejected."
        case .timedOut: return "Gemini took too long. Please try once more."
        }
    }
}
