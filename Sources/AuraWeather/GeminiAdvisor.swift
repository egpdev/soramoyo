import Foundation

struct GeminiAdvisor {
    func outfitNote(for weather: WeatherSnapshot, apiKey: String) async throws -> String {
        let prompt = """
        You are a concise personal weather stylist. Based only on this city-level weather summary, give one practical outfit recommendation in English. Keep it under 45 words. No greetings, no emojis, no medical advice. City: \(weather.city). Condition: \(weather.condition). Temperature: \(Int(weather.temperature.rounded()))C, feels like \(Int(weather.feelsLike.rounded()))C, wind \(Int(weather.windSpeed.rounded())) km/h, rain chance \(weather.rainChance)%.
        """
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = try JSONEncoder().encode(GeminiRequest(contents: [.init(parts: [.init(text: prompt)])], generationConfig: .init(temperature: 0.35, maxOutputTokens: 100)))
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw GeminiError.requestFailed }
        let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
        let text = decoded.candidates?.first?.content.parts.compactMap(\.text).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else { throw GeminiError.emptyResponse }
        return text
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

enum GeminiError: LocalizedError { case requestFailed, emptyResponse
    var errorDescription: String? { self == .requestFailed ? "Gemini couldn’t answer. Check the API key and connection." : "Gemini returned no outfit note." }
}
