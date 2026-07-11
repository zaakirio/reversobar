import Foundation

/// A supported language: its Reverso translation code, display labels, flag asset, TTS voice,
/// and whether it uses Cyrillic (which unlocks phonetic Latin→Cyrillic input).
struct Language: Identifiable, Hashable, Sendable {
    let code: String      // Reverso API code, e.g. "eng"
    let short: String     // compact UI label, e.g. "EN"
    let name: String      // English name, e.g. "English"
    let native: String    // endonym, e.g. "Русский"
    let flag: String      // flag-icons country code, e.g. "gb"
    let voice: String     // Reverso TTS voice name
    let isCyrillic: Bool  // enables phonetic input

    var id: String { code }
}

extension Language {
    /// All supported languages. Codes, voices and flags are verified against the live Reverso APIs.
    static let all: [Language] = [
        Language(code: "eng", short: "EN", name: "English",    native: "English",      flag: "gb", voice: "Graham22k",           isCyrillic: false),
        Language(code: "rus", short: "RU", name: "Russian",    native: "Русский",      flag: "ru", voice: "Alyona22k",           isCyrillic: true),
        Language(code: "spa", short: "ES", name: "Spanish",    native: "Español",      flag: "es", voice: "Maria22k",            isCyrillic: false),
        Language(code: "fra", short: "FR", name: "French",     native: "Français",     flag: "fr", voice: "Manon22k",            isCyrillic: false),
        Language(code: "ger", short: "DE", name: "German",     native: "Deutsch",      flag: "de", voice: "Claudia22k",          isCyrillic: false),
        Language(code: "ita", short: "IT", name: "Italian",    native: "Italiano",     flag: "it", voice: "Chiara22k",           isCyrillic: false),
        Language(code: "por", short: "PT", name: "Portuguese", native: "Português",    flag: "pt", voice: "Isabel22k",           isCyrillic: false),
        Language(code: "dut", short: "NL", name: "Dutch",      native: "Nederlands",   flag: "nl", voice: "Femke22k",            isCyrillic: false),
        Language(code: "pol", short: "PL", name: "Polish",     native: "Polski",       flag: "pl", voice: "Ania22k",            isCyrillic: false),
        Language(code: "ukr", short: "UK", name: "Ukrainian",  native: "Українська",   flag: "ua", voice: "uk-UA-PolinaNeural",  isCyrillic: true),
        Language(code: "tur", short: "TR", name: "Turkish",    native: "Türkçe",       flag: "tr", voice: "Ipek22k",            isCyrillic: false),
        Language(code: "ara", short: "AR", name: "Arabic",     native: "العربية",       flag: "sa", voice: "Salma22k",           isCyrillic: false),
        Language(code: "heb", short: "HE", name: "Hebrew",     native: "עברית",         flag: "il", voice: "he-IL-HilaNeural",    isCyrillic: false),
        Language(code: "jpn", short: "JA", name: "Japanese",   native: "日本語",         flag: "jp", voice: "Sakura22k",          isCyrillic: false),
        Language(code: "kor", short: "KO", name: "Korean",     native: "한국어",         flag: "kr", voice: "Minji22k",           isCyrillic: false),
        Language(code: "chi", short: "ZH", name: "Chinese",    native: "中文",           flag: "cn", voice: "Lulu22k",            isCyrillic: false),
        Language(code: "rum", short: "RO", name: "Romanian",   native: "Română",       flag: "ro", voice: "ro-RO-AlinaNeural",   isCyrillic: false),
        Language(code: "cze", short: "CS", name: "Czech",      native: "Čeština",      flag: "cz", voice: "Eliska22k",          isCyrillic: false),
    ]

    static func byCode(_ code: String) -> Language? { all.first { $0.code == code } }

    static let english = byCode("eng")!
    static let russian = byCode("rus")!
}
