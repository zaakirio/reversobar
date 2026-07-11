import Foundation

enum ReversoError: Error {
    case badStatus(Int)
    case empty
}

/// Thin client over Reverso's public translation + pronunciation endpoints.
struct ReversoClient: Sendable {

    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.waitsForConnectivity = true
        // URLSession negotiates and decodes gzip automatically; do not set Accept-Encoding manually.
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:151.0) Gecko/20100101 Firefox/151.0"
        ]
        self.session = URLSession(configuration: config)
    }

    // MARK: - Translation

    func translate(_ input: String, from: Language, to: Language) async throws -> TranslationResponse {
        let url = URL(string: "https://api.reverso.net/translate/v1/translation")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://www.reverso.net/", forHTTPHeaderField: "Referer")
        request.setValue("https://www.reverso.net", forHTTPHeaderField: "Origin")
        request.setValue("translation.web", forHTTPHeaderField: "X-Reverso-Origin")

        let body: [String: Any] = [
            "input": input,
            "from": from.code,
            "to": to.code,
            "options": [
                "contextResults": true,
                "languageDetection": true,
                "origin": "translation.web",
                "sentenceSplitter": true
            ],
            "format": "text"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw ReversoError.badStatus(http.statusCode)
        }
        return try JSONDecoder().decode(TranslationResponse.self, from: data)
    }

    // MARK: - Text to speech

    /// Builds the Reverso pronunciation stream URL for a phrase in a given language.
    func voiceURL(for text: String, language: Language, speed: Int = 90) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let encoded = trimmed.data(using: .utf8)?.base64EncodedString() else { return nil }
        // The base64 text is itself a path/query component, so percent-encode it.
        let allowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "+/=&?"))
        let safe = encoded.addingPercentEncoding(withAllowedCharacters: allowed) ?? encoded
        let string = "https://voice.reverso.net/RestPronunciation.svc/v1/output=json/GetVoiceStream/voiceName=\(language.voice)?voiceSpeed=\(speed)&inputText=\(safe)"
        return URL(string: string)
    }

    /// Downloads MP3 audio for a phrase. Returned data is fed straight to an audio player.
    func fetchAudio(for text: String, language: Language) async throws -> Data {
        guard let url = voiceURL(for: text, language: language) else { throw ReversoError.empty }
        var request = URLRequest(url: url)
        request.setValue("https://www.reverso.net/", forHTTPHeaderField: "Referer")
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw ReversoError.badStatus(http.statusCode)
        }
        guard !data.isEmpty else { throw ReversoError.empty }
        return data
    }
}
