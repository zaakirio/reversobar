import Foundation

/// A supported language: its Reverso translation code, display labels, flag asset, TTS voice,
/// and an optional phonetic scheme (which unlocks Latin → native-script input).
struct Language: Identifiable, Hashable, Sendable {
    let code: String      // Reverso API code, e.g. "eng"
    let short: String     // compact UI label, e.g. "EN"
    let name: String      // English name, e.g. "English"
    let native: String    // endonym, e.g. "Русский"
    let flag: String      // flag-icons country code, e.g. "gb"
    let voice: String     // Reverso TTS voice name
    var phoneticScheme: PhoneticScheme? = nil

    var id: String { code }
}

extension Language {
    /// All supported languages. Codes, voices and flags are verified against the live Reverso APIs.
    static let all: [Language] = [
        Language(code: "eng", short: "EN", name: "English",    native: "English",      flag: "gb", voice: "Graham22k"),
        Language(code: "rus", short: "RU", name: "Russian",    native: "Русский",      flag: "ru", voice: "Alyona22k",           phoneticScheme: .russian),
        Language(code: "spa", short: "ES", name: "Spanish",    native: "Español",      flag: "es", voice: "Maria22k"),
        Language(code: "fra", short: "FR", name: "French",     native: "Français",     flag: "fr", voice: "Manon22k"),
        Language(code: "ger", short: "DE", name: "German",     native: "Deutsch",      flag: "de", voice: "Claudia22k"),
        Language(code: "ita", short: "IT", name: "Italian",    native: "Italiano",     flag: "it", voice: "Chiara22k"),
        Language(code: "por", short: "PT", name: "Portuguese", native: "Português",    flag: "pt", voice: "Isabel22k"),
        Language(code: "dut", short: "NL", name: "Dutch",      native: "Nederlands",   flag: "nl", voice: "Femke22k"),
        Language(code: "pol", short: "PL", name: "Polish",     native: "Polski",       flag: "pl", voice: "Ania22k"),
        Language(code: "ukr", short: "UK", name: "Ukrainian",  native: "Українська",   flag: "ua", voice: "uk-UA-PolinaNeural",  phoneticScheme: .ukrainian),
        Language(code: "tur", short: "TR", name: "Turkish",    native: "Türkçe",       flag: "tr", voice: "Ipek22k"),
        Language(code: "ara", short: "AR", name: "Arabic",     native: "العربية",       flag: "sa", voice: "Salma22k"),
        Language(code: "heb", short: "HE", name: "Hebrew",     native: "עברית",         flag: "il", voice: "he-IL-HilaNeural"),
        Language(code: "jpn", short: "JA", name: "Japanese",   native: "日本語",         flag: "jp", voice: "Sakura22k",          phoneticScheme: .japanese),
        Language(code: "kor", short: "KO", name: "Korean",     native: "한국어",         flag: "kr", voice: "Minji22k",           phoneticScheme: .korean),
        Language(code: "chi", short: "ZH", name: "Chinese",    native: "中文",           flag: "cn", voice: "Lulu22k"),
        Language(code: "rum", short: "RO", name: "Romanian",   native: "Română",       flag: "ro", voice: "ro-RO-AlinaNeural"),
        Language(code: "cze", short: "CS", name: "Czech",      native: "Čeština",      flag: "cz", voice: "Eliska22k"),
    ]

    static func byCode(_ code: String) -> Language? { all.first { $0.code == code } }

    static let english = byCode("eng")!
    static let russian = byCode("rus")!
}
