import Foundation

/// A saved translation in the user's phrasebook.
struct Bookmark: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()
    let source: String
    let sourceLang: String        // Language.code
    let translation: String
    let targetLang: String        // Language.code
    let transliteration: String?
    var createdAt = Date()

    /// Identity for de-duplication (ignores id/date/transliteration).
    var key: String {
        "\(sourceLang)|\(source.lowercased())|\(targetLang)|\(translation.lowercased())"
    }

    var sourceLanguage: Language { Language.byCode(sourceLang) ?? .english }
    var targetLanguage: Language { Language.byCode(targetLang) ?? .russian }
}
