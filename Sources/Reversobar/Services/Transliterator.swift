import Foundation

/// One unit of phonetic input that maps a Latin chunk to a Cyrillic chunk.
struct Phoneme: Identifiable {
    let id = UUID()
    let latin: String
    let cyrillic: String
    /// True when more than one Latin letter produced this phoneme (a digraph like "sh" → ш).
    var isDigraph: Bool { latin.count > 1 }
}

/// Greedy longest-match phonetic transliteration from Latin keystrokes to Russian Cyrillic.
///
/// Lets a user type `privet` and see `привет`, while exposing the per-chunk breakdown so they
/// can see which phonemes they are forming (e.g. `sh` → ш, `zh` → ж).
enum Transliterator {

    /// Multi- and single-character rules. Order does not matter here; lookup tries longest first.
    private static let rules: [String: String] = [
        // 4-letter
        "shch": "щ",
        // 3-letter
        "sch": "щ",
        // 2-letter digraphs
        "yo": "ё", "jo": "ё",
        "yu": "ю", "ju": "ю",
        "ya": "я", "ja": "я",
        "ye": "е", "je": "е",
        "yi": "й",
        "zh": "ж", "kh": "х", "ts": "ц", "ch": "ч", "sh": "ш",
        "ph": "ф", "ck": "к", "ee": "и", "oo": "у",
        // single letters
        "a": "а", "b": "б", "c": "ц", "d": "д", "e": "е", "f": "ф",
        "g": "г", "h": "х", "i": "и", "j": "й", "k": "к", "l": "л",
        "m": "м", "n": "н", "o": "о", "p": "п", "q": "к", "r": "р",
        "s": "с", "t": "т", "u": "у", "v": "в", "w": "в", "x": "кс",
        "y": "ы", "z": "з",
        // signs
        "'": "ь", "`": "ъ",
    ]

    private static let maxRuleLength = 4

    /// Returns the Cyrillic string and the ordered breakdown of phonemes.
    static func convert(_ input: String) -> (text: String, phonemes: [Phoneme]) {
        var output = ""
        var phonemes: [Phoneme] = []
        let chars = Array(input)
        var i = 0

        while i < chars.count {
            var matched = false
            let remaining = chars.count - i
            // Try the longest possible rule first.
            for len in stride(from: min(maxRuleLength, remaining), through: 1, by: -1) {
                let slice = String(chars[i..<(i + len)])
                let lower = slice.lowercased()
                guard let mapped = rules[lower] else { continue }

                let cased = applyCase(of: slice, to: mapped)
                output += cased
                phonemes.append(Phoneme(latin: slice, cyrillic: cased))
                i += len
                matched = true
                break
            }

            if !matched {
                // Pass unknown characters through unchanged (spaces, digits, punctuation).
                let slice = String(chars[i])
                output += slice
                if slice != " " {
                    phonemes.append(Phoneme(latin: slice, cyrillic: slice))
                }
                i += 1
            }
        }

        return (output, phonemes)
    }

    /// Mirrors the capitalization of the Latin source onto the Cyrillic result.
    private static func applyCase(of latin: String, to cyrillic: String) -> String {
        guard let first = latin.first else { return cyrillic }
        if latin.allSatisfy({ $0.isUppercase || !$0.isLetter }) && latin.contains(where: { $0.isLetter }) {
            // ALL CAPS input → all caps output.
            return cyrillic.uppercased()
        }
        if first.isUppercase {
            return cyrillic.prefix(1).uppercased() + cyrillic.dropFirst()
        }
        return cyrillic
    }
}
