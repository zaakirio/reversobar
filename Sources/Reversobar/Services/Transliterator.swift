import Foundation

/// One unit of phonetic input that maps a Latin chunk to a native-script chunk.
struct Phoneme: Identifiable {
    let id = UUID()
    let latin: String
    let native: String
    /// True when more than one Latin letter produced this phoneme (a digraph like "sh" → ш).
    var isDigraph: Bool { latin.count > 1 }
}

/// A phonetic input scheme: Latin keystrokes → a non-Latin script, for languages where the
/// romanization is regular enough to convert rule-by-rule as the user types.
enum PhoneticScheme: String, Sendable {
    case russian
    case ukrainian
    case japanese   // Hepburn romaji → hiragana
    case korean     // Revised Romanization → hangul

    /// Example shown in the search placeholder while phonetic input is on.
    var placeholder: String {
        switch self {
        case .russian: return "privet → привет…"
        case .ukrainian: return "pryvit → привіт…"
        case .japanese: return "konnichiwa → こんにちは…"
        case .korean: return "annyeong → 안녕…"
        }
    }

    /// Example shown in the phonetic preview before any input.
    var hint: String {
        switch self {
        case .russian: return "Type phonetically — e.g. \u{201C}zhivu v moskve\u{201D}"
        case .ukrainian: return "Type phonetically — e.g. \u{201C}dobroho dnya\u{201D}"
        case .japanese: return "Type romaji — e.g. \u{201C}arigatou gozaimasu\u{201D}"
        case .korean: return "Type romanized — e.g. \u{201C}gamsahamnida\u{201D}"
        }
    }

    /// The script the scheme produces, for help text.
    var scriptName: String {
        switch self {
        case .russian, .ukrainian: return "Cyrillic"
        case .japanese: return "hiragana"
        case .korean: return "Hangul"
        }
    }
}

/// Greedy longest-match phonetic transliteration from Latin keystrokes to a native script.
///
/// Lets a user type `privet` and see `привет` (or `konnichiwa` → こんにちは), while exposing
/// the per-chunk breakdown so they can see which phonemes they are forming.
enum Transliterator {

    /// Returns the native-script string and the ordered breakdown of phonemes.
    static func convert(_ input: String, scheme: PhoneticScheme) -> (text: String, phonemes: [Phoneme]) {
        switch scheme {
        case .russian: return greedyConvert(input, rules: russianRules, mirrorCase: true)
        case .ukrainian: return greedyConvert(input, rules: ukrainianRules, mirrorCase: true)
        case .japanese: return convertKana(input)
        case .korean: return HangulComposer.convert(input)
        }
    }

    // MARK: - Greedy longest-match engine

    private static func greedyConvert(
        _ input: String,
        rules: [String: String],
        mirrorCase: Bool
    ) -> (text: String, phonemes: [Phoneme]) {
        let maxLen = rules.keys.map(\.count).max() ?? 1
        var output = ""
        var phonemes: [Phoneme] = []
        let chars = Array(input)
        var i = 0

        while i < chars.count {
            var matched = false
            for len in stride(from: min(maxLen, chars.count - i), through: 1, by: -1) {
                let slice = String(chars[i..<(i + len)])
                guard let mapped = rules[slice.lowercased()] else { continue }
                let cased = mirrorCase ? applyCase(of: slice, to: mapped) : mapped
                output += cased
                phonemes.append(Phoneme(latin: slice, native: cased))
                i += len
                matched = true
                break
            }
            if !matched {
                // Pass unknown characters through unchanged (spaces, digits, punctuation).
                let slice = String(chars[i])
                output += slice
                if slice != " " {
                    phonemes.append(Phoneme(latin: slice, native: slice))
                }
                i += 1
            }
        }
        return (output, phonemes)
    }

    /// Mirrors the capitalization of the Latin source onto the converted result.
    private static func applyCase(of latin: String, to converted: String) -> String {
        guard let first = latin.first else { return converted }
        if latin.allSatisfy({ $0.isUppercase || !$0.isLetter }) && latin.contains(where: { $0.isLetter }) {
            return converted.uppercased()
        }
        if first.isUppercase {
            return converted.prefix(1).uppercased() + converted.dropFirst()
        }
        return converted
    }

    // MARK: - Russian

    private static let russianRules: [String: String] = [
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

    // MARK: - Ukrainian

    /// Differs from Russian where the alphabets differ: г is "h" (ґ is "g"), и is "y",
    /// і/ї/є exist, and there is no ё/ы/э.
    private static let ukrainianRules: [String: String] = [
        // 4-letter
        "shch": "щ",
        // 3-letter
        "sch": "щ",
        // 2-letter digraphs
        "yu": "ю", "ju": "ю",
        "ya": "я", "ja": "я",
        "ye": "є", "je": "є",
        "yi": "ї", "ji": "ї",
        "yo": "йо", "jo": "йо",
        "zh": "ж", "kh": "х", "ts": "ц", "ch": "ч", "sh": "ш",
        "ph": "ф", "ck": "к",
        // single letters
        "a": "а", "b": "б", "c": "ц", "d": "д", "e": "е", "f": "ф",
        "g": "ґ", "h": "г", "i": "і", "j": "й", "k": "к", "l": "л",
        "m": "м", "n": "н", "o": "о", "p": "п", "q": "к", "r": "р",
        "s": "с", "t": "т", "u": "у", "v": "в", "w": "в", "x": "кс",
        "y": "и", "z": "з",
        // signs
        "'": "ь",
    ]

    // MARK: - Japanese (romaji → hiragana)

    private static func convertKana(_ input: String) -> (text: String, phonemes: [Phoneme]) {
        var output = ""
        var phonemes: [Phoneme] = []
        let chars = Array(input.lowercased())
        let original = Array(input)
        var i = 0

        while i < chars.count {
            // Sokuon: a doubled consonant (kk, tt, pp…) becomes っ and the consonant carries on.
            if i + 1 < chars.count, chars[i] == chars[i + 1],
               "kstcpgzdbfrhmyw".contains(chars[i]) {
                output += "っ"
                phonemes.append(Phoneme(latin: String(original[i]), native: "っ"))
                i += 1
                continue
            }
            // Moraic n (IME rule): "n" becomes ん unless a vowel or y follows (na/nya…),
            // so "onna" → おんな and "sensei" → せんせい. "n'" forces ん before a vowel.
            if chars[i] == "n" {
                let next = i + 1 < chars.count ? chars[i + 1] : nil
                if next == "'" {
                    output += "ん"
                    phonemes.append(Phoneme(latin: String(original[i...(i + 1)]), native: "ん"))
                    i += 2
                    continue
                }
                if next == nil || !"aiueoy".contains(next!) {
                    output += "ん"
                    phonemes.append(Phoneme(latin: String(original[i]), native: "ん"))
                    i += 1
                    continue
                }
            }
            var matched = false
            for len in stride(from: min(3, chars.count - i), through: 1, by: -1) {
                let slice = String(chars[i..<(i + len)])
                guard let kana = kanaRules[slice] else { continue }
                output += kana
                phonemes.append(Phoneme(latin: String(original[i..<(i + len)]), native: kana))
                i += len
                matched = true
                break
            }
            if !matched {
                let slice = String(original[i])
                output += slice
                if slice != " " {
                    phonemes.append(Phoneme(latin: slice, native: slice))
                }
                i += 1
            }
        }
        return (output, phonemes)
    }

    private static let kanaRules: [String: String] = [
        // yōon (3-letter first so greedy matching prefers them)
        "kya": "きゃ", "kyu": "きゅ", "kyo": "きょ",
        "sha": "しゃ", "shu": "しゅ", "sho": "しょ", "shi": "し",
        "cha": "ちゃ", "chu": "ちゅ", "cho": "ちょ", "chi": "ち",
        "tsu": "つ",
        "nya": "にゃ", "nyu": "にゅ", "nyo": "にょ",
        "hya": "ひゃ", "hyu": "ひゅ", "hyo": "ひょ",
        "mya": "みゃ", "myu": "みゅ", "myo": "みょ",
        "rya": "りゃ", "ryu": "りゅ", "ryo": "りょ",
        "gya": "ぎゃ", "gyu": "ぎゅ", "gyo": "ぎょ",
        "bya": "びゃ", "byu": "びゅ", "byo": "びょ",
        "pya": "ぴゃ", "pyu": "ぴゅ", "pyo": "ぴょ",
        "dji": "ぢ", "dzu": "づ",
        // 2-letter
        "ka": "か", "ki": "き", "ku": "く", "ke": "け", "ko": "こ",
        "sa": "さ", "si": "し", "su": "す", "se": "せ", "so": "そ",
        "ta": "た", "ti": "ち", "tu": "つ", "te": "て", "to": "と",
        "na": "な", "ni": "に", "nu": "ぬ", "ne": "ね", "no": "の",
        "ha": "は", "hi": "ひ", "hu": "ふ", "fu": "ふ", "he": "へ", "ho": "ほ",
        "ma": "ま", "mi": "み", "mu": "む", "me": "め", "mo": "も",
        "ya": "や", "yu": "ゆ", "yo": "よ",
        "ra": "ら", "ri": "り", "ru": "る", "re": "れ", "ro": "ろ",
        "wa": "わ", "wo": "を",
        "ga": "が", "gi": "ぎ", "gu": "ぐ", "ge": "げ", "go": "ご",
        "za": "ざ", "ji": "じ", "zi": "じ", "zu": "ず", "ze": "ぜ", "zo": "ぞ",
        "da": "だ", "de": "で", "do": "ど",
        "ba": "ば", "bi": "び", "bu": "ぶ", "be": "べ", "bo": "ぼ",
        "pa": "ぱ", "pi": "ぴ", "pu": "ぷ", "pe": "ぺ", "po": "ぽ",
        "ja": "じゃ", "ju": "じゅ", "jo": "じょ",
        // vowels (moraic n is handled in convertKana)
        "a": "あ", "i": "い", "u": "う", "e": "え", "o": "お",
        "-": "ー",
    ]
}

// MARK: - Korean (Revised Romanization → hangul)

/// Parses romaja into jamo tokens, then composes syllable blocks with the standard
/// Unicode hangul composition (0xAC00 + (L·21 + V)·28 + T).
private enum HangulComposer {

    // Longest-match-first token tables. Index values follow the Unicode jamo orders.
    private static let initials: [(String, Int)] = [
        ("kk", 1), ("tt", 4), ("pp", 8), ("ss", 10), ("jj", 13), ("ch", 14),
        ("g", 0), ("n", 2), ("d", 3), ("r", 5), ("l", 5), ("m", 6), ("b", 7),
        ("s", 9), ("j", 12), ("k", 15), ("t", 16), ("p", 17), ("h", 18),
    ]

    private static let vowels: [(String, Int)] = [
        ("yae", 3), ("yeo", 6), ("wae", 10),
        ("ae", 1), ("ya", 2), ("eo", 4), ("ye", 7), ("wa", 9), ("oe", 11),
        ("yo", 12), ("wo", 14), ("we", 15), ("wi", 16), ("yu", 17), ("eu", 18), ("ui", 19),
        ("a", 0), ("e", 5), ("o", 8), ("u", 13), ("i", 20),
    ]

    private static let finals: [String: Int] = [
        "g": 1, "kk": 2, "n": 4, "d": 7, "l": 8, "r": 8, "m": 16, "b": 17,
        "s": 19, "ss": 20, "ng": 21, "j": 22, "ch": 23, "k": 24, "t": 25, "p": 26, "h": 27,
    ]

    private static let vowelStarts = Set("aeiouyw")

    static func convert(_ input: String) -> (text: String, phonemes: [Phoneme]) {
        var output = ""
        var phonemes: [Phoneme] = []
        let chars = Array(input.lowercased())
        var i = 0

        // Current syllable under construction, plus the Latin it consumed.
        // The final's Latin is tracked separately so it can carry to the next syllable.
        var L: Int? = nil, V: Int? = nil, T: Int? = nil
        var latin = ""
        var finalLatin = ""

        func flush() {
            guard let v = V else {
                // A bare consonant with no vowel: emit the Latin as-is (mid-typing state).
                if !latin.isEmpty {
                    output += latin
                    phonemes.append(Phoneme(latin: latin, native: latin))
                }
                L = nil; T = nil; latin = ""; finalLatin = ""
                return
            }
            let l = L ?? 11  // ㅇ silent initial
            let t = T ?? 0
            let scalar = 0xAC00 + (l * 21 + v) * 28 + t
            let syllable = String(UnicodeScalar(scalar)!)
            output += syllable
            phonemes.append(Phoneme(latin: latin + finalLatin, native: syllable))
            L = nil; V = nil; T = nil; latin = ""; finalLatin = ""
        }

        func nextIsVowel(_ at: Int) -> Bool {
            at < chars.count && vowelStarts.contains(chars[at])
        }

        while i < chars.count {
            let c = chars[i]

            if c == " " || !(c.isLetter || c == "-") {
                flush()
                output += String(c)
                if c != " " { phonemes.append(Phoneme(latin: String(c), native: String(c))) }
                i += 1
                continue
            }
            if c == "-" {  // RR syllable separator: force a boundary, consume silently
                flush()
                i += 1
                continue
            }

            // Vowel token.
            if vowelStarts.contains(c),
               let (tok, idx) = vowels.first(where: { chars[i...].starts(with: $0.0) }) {
                if V != nil {
                    // Vowel after a completed vowel: any pending final becomes the next
                    // syllable's initial (ha·n+a → 하나).
                    let carried = T
                    let carriedLatin = finalLatin
                    T = nil
                    finalLatin = ""
                    flush()
                    if let carried {
                        L = initialIndex(forFinal: carried)
                        latin = carriedLatin
                    }
                }
                V = idx
                latin += tok
                i += tok.count
                continue
            }

            // Consonant token. "ng" only binds as one unit when no vowel follows it
            // (han·geul needs the g back as the next initial).
            var consonant: (String, Int)? = nil
            if chars[i...].starts(with: "ng"), !nextIsVowel(i + 2), V != nil {
                consonant = ("ng", -1)  // final-only marker
            } else {
                consonant = initials.first { chars[i...].starts(with: $0.0) }
            }

            guard let (tok, idx) = consonant else {
                flush()
                output += String(c)
                phonemes.append(Phoneme(latin: String(c), native: String(c)))
                i += 1
                continue
            }

            if V == nil {
                if L != nil { flush() }  // two bare consonants in a row: flush the first
                L = idx == -1 ? nil : idx
                latin += tok
            } else if T == nil, let finalIdx = (idx == -1 ? finals["ng"] : finals[tok]) {
                T = finalIdx
                finalLatin = tok
            } else {
                // No final slot available: start the next syllable.
                flush()
                L = idx == -1 ? nil : idx
                latin += tok
            }
            i += tok.count
        }
        flush()
        return (output, phonemes)
    }

    /// Maps a final-consonant index back to the matching initial index for carry-over.
    private static func initialIndex(forFinal final: Int) -> Int? {
        let map: [Int: Int] = [1: 0, 2: 1, 4: 2, 7: 3, 8: 5, 16: 6, 17: 7, 19: 9, 20: 10, 22: 12, 23: 14, 24: 15, 25: 16, 26: 17, 27: 18]
        return map[final]
    }
}
