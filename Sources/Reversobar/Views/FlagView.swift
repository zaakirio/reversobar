import SwiftUI
import AppKit

/// Loads bundled flag PNGs (flag-icons, MIT) from the package resource bundle, with caching.
@MainActor
enum Flags {
    private static var originals: [String: NSImage] = [:]
    private static var resized: [String: NSImage] = [:]

    static func image(_ code: String) -> NSImage? {
        if let cached = originals[code] { return cached }
        guard let url = Bundle.module.url(forResource: code, withExtension: "png", subdirectory: "Flags"),
              let img = NSImage(contentsOf: url) else { return nil }
        originals[code] = img
        return img
    }

    /// A copy whose *point* size is fixed to `width` × `width·¾`, keeping the original hi-res
    /// representation for retina crispness. A non-resizable `Image(nsImage:)` then renders at this
    /// exact intrinsic size — which `.resizable() + .frame()` failed to enforce inside a `Menu`.
    static func sized(_ code: String, width: CGFloat) -> NSImage? {
        let key = "\(code)@\(width)"
        if let cached = resized[key] { return cached }
        guard let base = image(code), let copy = base.copy() as? NSImage else { return nil }
        copy.size = NSSize(width: width, height: (width * 0.75).rounded())
        copy.isTemplate = false
        resized[key] = copy
        return copy
    }
}

/// A rounded-rectangle flag with a hairline border (passport / macOS input-source style).
struct FlagImage: View {
    let code: String
    var width: CGFloat = 22

    var body: some View {
        let height = (width * 0.75).rounded()
        let radius = max(4, (width * 0.26).rounded())
        Group {
            if let img = Flags.sized(code, width: width) {
                Image(nsImage: img)   // non-resizable → renders at the image's fixed point size
            } else {
                Rectangle().fill(.quaternary)
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .stroke(.primary.opacity(0.14), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.22), radius: 1.5, x: 0, y: 0.5)
    }
}
