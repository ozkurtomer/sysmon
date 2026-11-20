import Foundation

/// Language preference. `.system` follows the Mac's preferred language.
enum Lang: String { case system, en, tr }

enum Loc {
    static var override: Lang = Lang(rawValue: UserDefaults.standard.string(forKey: "lang") ?? "") ?? .system

    /// Resolved language code ("en" or "tr").
    static var code: String {
        switch override {
        case .en: return "en"
        case .tr: return "tr"
        case .system:
            return (Locale.preferredLanguages.first ?? "en").lowercased().hasPrefix("tr") ? "tr" : "en"
        }
    }
}

private let table: [String: [String: String]] = [
    "en": [
        "playtime": "Playtime",
        "mood_calm": "All clear",
        "mood_busy": "Enemies nearby",
        "mood_boss": "Boss fight!",
        "mood_low": "Low health!",
        "cpu": "CPU", "ram": "RAM", "disk": "Disk", "battery": "Battery",
        "charging": "charging",
        "enemies": "ENEMIES",
        "boss": "BOSS",
        "quit_tip": "Ask this app to quit",
        "quit_title": "Quit %@?",
        "quit_info": "The app will be asked to quit. If it has unsaved work, it will ask you first.",
        "quit_btn": "Quit app", "cancel": "Cancel",
        "star": "Star on GitHub ★",
        "issue": "Report a bug or idea…",
        "login": "Launch at login",
        "language": "Language",
        "system": "System default",
        "activity": "Open Activity Monitor",
        "quit_app": "Quit SysMon",
        "unit_d": "d", "unit_h": "h", "unit_m": "m",
    ],
    "tr": [
        "playtime": "Oyun süresi",
        "mood_calm": "Her şey yolunda",
        "mood_busy": "Düşmanlar yakında",
        "mood_boss": "Boss savaşı!",
        "mood_low": "Can azalıyor!",
        "cpu": "CPU", "ram": "RAM", "disk": "Disk", "battery": "Pil",
        "charging": "şarjda",
        "enemies": "DÜŞMANLAR",
        "boss": "BOSS",
        "quit_tip": "Bu uygulamadan kapanmasını iste",
        "quit_title": "%@ kapatılsın mı?",
        "quit_info": "Uygulamaya kapanması söylenecek. Kaydedilmemiş işi varsa önce size soracak.",
        "quit_btn": "Uygulamayı kapat", "cancel": "Vazgeç",
        "star": "GitHub'da yıldızla ★",
        "issue": "Hata veya fikir bildir…",
        "login": "Girişte başlat",
        "language": "Dil",
        "system": "Sistem varsayılanı",
        "activity": "Etkinlik Monitörü'nü aç",
        "quit_app": "SysMon'dan çık",
        "unit_d": "g", "unit_h": "sa", "unit_m": "dk",
    ],
]

/// Localized string for `key` in the active language (falls back to English).
func t(_ key: String) -> String {
    table[Loc.code]?[key] ?? table["en"]?[key] ?? key
}
