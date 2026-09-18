import Foundation

enum AuraLanguage: String, CaseIterable, Identifiable {
    case german, russian, english
    var id: String { rawValue }
    var label: String { self == .german ? "Deutsch" : self == .russian ? "Русский" : "English" }
    func t(_ key: String) -> String {
        let text: [String: (String, String, String)] = [
            "now": ("Jetzt", "Сейчас", "Now"), "forecast": ("Vorhersage", "Прогноз", "Forecast"), "settings": ("Einstellungen", "Настройки", "Settings"),
            "location": ("STANDORT", "ЛОКАЦИЯ", "LOCATION"), "language": ("SPRACHE", "ЯЗЫК", "LANGUAGE"), "units": ("EINHEITEN", "ЕДИНИЦЫ", "UNITS"),
            "placeHint": ("z. B. Kreuzberg, Berlin", "например, Кройцберг, Берлин", "e.g. Kreuzberg, Berlin"),
            "placeHelp": ("Stadtteil oder Stadt suchen", "Ищи район или город", "Search a district or city"),
            "usePlace": ("Ort verwenden", "Выбрать", "Use place"), "useLocation": ("Meinen Standort", "Моя геолокация", "Use my location"),
            "nowDry": ("JETZT TROCKEN", "СЕЙЧАС СУХО", "DRY NOW"), "rainPeak": ("REGENRISIKO SPÄTER", "ОСАДКИ ПОЗЖЕ", "RAIN CHANCE LATER"),
            "probability": ("Wahrscheinlichkeit, kein Regen jetzt", "Вероятность, не дождь прямо сейчас", "Probability, not rain right now")
        ]
        guard let value = text[key] else { return key }
        switch self { case .german: return value.0; case .russian: return value.1; case .english: return value.2 }
    }
}
