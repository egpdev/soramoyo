import Foundation

enum AuraLanguage: String, CaseIterable, Identifiable {
    case german, russian, english
    var id: String { rawValue }
    var label: String { self == .german ? "Deutsch" : self == .russian ? "Русский" : "English" }
    var locale: Locale {
        Locale(identifier: self == .german ? "de_DE" : self == .russian ? "ru_RU" : "en_GB")
    }
    func t(_ key: String) -> String {
        let text: [String: (String, String, String)] = [
            "now": ("Jetzt", "Сейчас", "Now"), "forecast": ("Vorhersage", "Прогноз", "Forecast"), "settings": ("Einstellungen", "Настройки", "Settings"),
            "location": ("STANDORT", "ЛОКАЦИЯ", "LOCATION"), "language": ("SPRACHE", "ЯЗЫК", "LANGUAGE"), "units": ("EINHEITEN", "ЕДИНИЦЫ", "UNITS"),
            "placeHint": ("z. B. Kreuzberg, Berlin", "например, Кройцберг, Берлин", "e.g. Kreuzberg, Berlin"),
            "placeHelp": ("Stadtteil oder Stadt suchen", "Ищи район или город", "Search a district or city"),
            "usePlace": ("Ort verwenden", "Выбрать", "Use place"), "useLocation": ("Meinen Standort", "Моя геолокация", "Use my location"),
            "nowDry": ("JETZT TROCKEN", "СЕЙЧАС СУХО", "DRY NOW"), "rainPeak": ("REGENRISIKO SPÄTER", "ОСАДКИ ПОЗЖЕ", "RAIN CHANCE LATER"),
            "probability": ("Regenrisiko für den Tag, aktuell trocken", "вероятность осадков за день, сейчас сухо", "chance for the day, dry right now")
            ,"localWeather": ("LOKALES WETTER", "МЕСТНАЯ ПОГОДА", "LOCAL WEATHER"), "localPrivacy": ("Standort bleibt auf diesem Mac.", "Геолокация остаётся на этом Mac.", "Location stays on this Mac."),
            "weatherQuiet": ("WETTER, GANZ RUHIG", "ПОГОДА, БЕЗ ШУМА", "WEATHER, MADE QUIET"), "weekAhead": ("DIE NÄCHSTEN TAGE", "БЛИЖАЙШИЕ ДНИ", "THE WEEK AHEAD"), "outside": ("DRAUSSEN", "НА УЛИЦЕ", "OUTSIDE CONDITIONS"),
            "feelsLike": ("GEFÜHLT", "ОЩУЩАЕТСЯ", "FEELS LIKE"), "wind": ("WIND", "ВЕТЕР", "WIND"), "dayPulse": ("TAGESVERLAUF", "ПОГОДА ПО ЧАСАМ", "DAY PULSE"),
            "hourlyEmpty": ("Stundendaten erscheinen nach der nächsten Aktualisierung.", "Почасовые данные появятся после обновления.", "Hourly detail will appear after the next refresh."),
            "mildNow": ("Aktuell mild, maximal", "Сейчас умеренно, максимум", "Mild now, reaching"), "rainLikely": ("Später ist Regen wahrscheinlich.", "Позже возможен дождь.", "Rain is likely later today."), "rainUnlikely": ("Regen ist heute unwahrscheinlich.", "Дождь сегодня маловероятен.", "Rain is unlikely today."),
            "whatWear": ("WAS ANZIEHEN", "ЧТО НАДЕТЬ", "WHAT TO WEAR"), "aiNote": ("SORAMOYO KI-TIPP", "СОВЕТ SORAMOYO AI", "SORAMOYO AI NOTE"), "askGemini": ("Gemini fragen", "Спросить Gemini", "Ask Gemini"), "enableGemini": ("Gemini aktivieren", "Включить Gemini", "Enable Gemini"),
            "forecastRefresh": ("Die Vorhersage wird bei Standort- oder Ortswechsel aktualisiert.", "Прогноз обновляется при выборе геолокации или города.", "Forecast refreshes whenever you use your location or set a city in Settings."),
            "makeYours": ("PASS ES AN", "НАСТРОЙ ПОД СЕБЯ", "MAKE IT YOURS"), "temperature": ("Temperatur", "Температура", "Temperature"),
            "geminiTitle": ("GEMINI OUTFIT-TIPP", "СОВЕТ ПО ОДЕЖДЕ ОТ GEMINI", "GEMINI OUTFIT ADVICE"), "geminiPrivacy": ("Gemini erhält nur Wetterdaten für Stadt oder Bezirk, niemals exakte Koordinaten. Der Schlüssel bleibt im macOS-Schlüsselbund.", "Gemini получает только погоду города или района, без точных координат. Ключ хранится в Связке ключей macOS.", "Gemini receives city or district weather only, never exact coordinates. The key stays in macOS Keychain."),
            "saveKey": ("Schlüssel speichern", "Сохранить ключ", "Save key"), "keySaved": ("Schlüssel gespeichert — neuen zum Ersetzen eingeben", "Ключ сохранён — введи новый для замены", "Key saved — enter a new one to replace it"), "pasteKey": ("Gemini API-Schlüssel einfügen", "Вставь API-ключ Gemini", "Paste Gemini API key"), "backNow": ("Zurück zu Jetzt", "Назад к погоде", "Back to Now"),
            "liveStatus": ("Live-Wetter · gerade aktualisiert", "Погода сейчас · только что обновлено", "Live conditions · updated now"), "refreshFailed": ("Aktualisierung fehlgeschlagen · letzte Daten", "Не удалось обновить · показаны последние данные", "Couldn’t refresh — showing the last conditions"), "localAdvice": ("Lokaler Outfit-Tipp ist aktiv", "Локальный совет по одежде активен", "Local outfit advice is active"), "thinking": ("Outfit wird zusammengestellt…", "Подбираю одежду…", "Thinking about your outfit…"),
            "live": ("LIVE", "СЕЙЧАС", "LIVE"), "high": ("H", "МАКС", "H"), "low": ("T", "МИН", "L"), "openToday": ("Heutiges Wetter öffnen", "Открыть погоду на сегодня", "Open today’s weather"),
            "geminiReady": ("Gemini ist bereit · Schlüssel im macOS-Schlüsselbund", "Gemini готов · ключ хранится в Связке ключей macOS", "Gemini is ready · key saved in macOS Keychain"), "geminiKeyNeeded": ("Zuerst Gemini-Schlüssel in Einstellungen hinzufügen", "Сначала добавь ключ Gemini в настройках", "Add a Gemini API key in Settings first"), "geminiResult": ("KI-Outfit-Tipp · nur Wetter für Stadt oder Bezirk", "Совет AI по одежде · только погода города или района", "AI outfit note · city or district weather only"), "geminiError": ("Gemini konnte nicht antworten. Schlüssel und Verbindung prüfen.", "Gemini не смог ответить. Проверь ключ и подключение.", "Gemini couldn’t answer. Check the key and connection."),
            "previewStatus": ("Berlin als Vorschau", "Предпросмотр погоды Берлина", "Using Berlin as a preview"), "locationOff": ("Standortzugriff aus · Berlin wird gezeigt", "Доступ к геолокации выключен · показан Берлин", "Location access is off · showing Berlin"), "locationUnavailable": ("Standort nicht verfügbar · Berlin wird gezeigt", "Геолокация недоступна · показан Берлин", "Location unavailable · showing Berlin"), "cityNotFound": ("Ort nicht gefunden", "Город или район не найден", "City or district not found"),
            "optional": ("Optional", "Необязательно", "Optional")
        ]
        guard let value = text[key] else { return key }
        switch self { case .german: return value.0; case .russian: return value.1; case .english: return value.2 }
    }

    func weatherStatus(_ status: String) -> String {
        if status.contains("Live conditions") { return t("liveStatus") }
        if status.contains("Couldn’t refresh") { return t("refreshFailed") }
        if status.contains("Using Berlin") { return t("previewStatus") }
        if status.contains("Location access is off") { return t("locationOff") }
        if status.contains("Location unavailable") { return t("locationUnavailable") }
        if status.contains("City not found") { return t("cityNotFound") }
        return status
    }

    func geminiStatus(_ status: String) -> String {
        if status.contains("Local outfit advice") { return t("localAdvice") }
        if status.contains("Thinking about") { return t("thinking") }
        if status.contains("Gemini is ready") { return t("geminiReady") }
        if status.contains("Add a Gemini API key") { return t("geminiKeyNeeded") }
        if status.contains("AI outfit note") { return t("geminiResult") }
        return self == .english ? status : t("geminiError")
    }

    func condition(_ code: Int) -> String {
        switch code {
        case 0: return self == .german ? "Klar" : self == .russian ? "Ясно" : "Clear"
        case 1, 2: return self == .german ? "Teilweise bewölkt" : self == .russian ? "Переменная облачность" : "Partly cloudy"
        case 3: return self == .german ? "Bedeckt" : self == .russian ? "Облачно" : "Overcast"
        case 45, 48: return self == .german ? "Nebel" : self == .russian ? "Туман" : "Fog"
        case 51...67, 80...82: return self == .german ? "Regen" : self == .russian ? "Дождь" : "Rain"
        case 71...77, 85, 86: return self == .german ? "Schnee" : self == .russian ? "Снег" : "Snow"
        case 95...99: return self == .german ? "Gewitter" : self == .russian ? "Гроза" : "Thunderstorm"
        default: return self == .german ? "Wetter" : self == .russian ? "Погода" : "Weather"
        }
    }

    func localOutfit(_ weather: WeatherSnapshot) -> OutfitAdvice {
        let cold = weather.feelsLike < 8, cool = weather.feelsLike < 16, wet = weather.rainChance >= 35 || weather.precipitation > 0
        if self == .russian {
            return cold ? .init(headline: "Одевайся теплее.", detail: "На улице холодно — важен тёплый верхний слой.", items: ["Тёплая куртка", "Свитер", wet ? "Зонт" : "Шарф"]) : cool ? .init(headline: "Добавь лёгкий слой.", detail: "Температура умеренная, но ветер может ощущаться прохладнее.", items: ["Лёгкая куртка", "Лонгслив", wet ? "Зонт" : "Кроссовки"]) : .init(headline: "Лёгкой одежды достаточно.", detail: "Комфортная погода; тонкий слой пригодится вечером.", items: ["Футболка", "Рубашка", wet ? "Зонт" : "Кроссовки"])
        }
        if self == .german {
            return cold ? .init(headline: "Warm anziehen.", detail: "Draußen ist es kalt — eine warme Außenschicht zählt.", items: ["Warme Jacke", "Pullover", wet ? "Schirm" : "Schal"]) : cool ? .init(headline: "Eine leichte Schicht dazu.", detail: "Mild, im Wind aber etwas kühler.", items: ["Leichte Jacke", "Longsleeve", wet ? "Schirm" : "Sneaker"]) : .init(headline: "Leichte Kleidung reicht.", detail: "Angenehm draußen; für den Abend eine dünne Schicht.", items: ["T-Shirt", "Overshirt", wet ? "Schirm" : "Sneaker"])
        }
        return OutfitEngine.advice(for: weather)
    }
}
