#!/bin/bash
# Generates AppIcon.icns from a programmatically-drawn 1024px master:
# transit-signage motif — flat signal-blue tile, "A ⇄ Я" wayfinding between scripts.
set -euo pipefail
cd "$(dirname "$0")/.."
TMP="$(mktemp -d)"
MASTER="$TMP/icon_1024.png"

cat > "$TMP/IconGen.swift" <<'SWIFT'
import AppKit

let size: CGFloat = 1024
let img = NSImage(size: NSSize(width: size, height: size))
img.lockFocus()

func glyph(_ s: String, size fs: CGFloat, weight: NSFont.Weight, color: NSColor, center: NSPoint) {
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: fs, weight: weight),
        .foregroundColor: color
    ]
    let a = NSAttributedString(string: s, attributes: attrs)
    let sz = a.size()
    a.draw(at: NSPoint(x: center.x - sz.width / 2, y: center.y - sz.height / 2))
}

// Rounded app tile, flat signal blue — no gradient, no shadows (signage, not decoration).
let inset: CGFloat = 100
let rect = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
NSBezierPath(roundedRect: rect, xRadius: rect.width * 0.2237, yRadius: rect.width * 0.2237).addClip()
NSColor(srgbRed: 0.115, green: 0.30, blue: 0.85, alpha: 1).setFill()
rect.fill()

// Wayfinding mark: Latin A ⇄ Cyrillic Я, swap arrows drawn as chunky signage shapes.
let yellow = NSColor(srgbRed: 0.97, green: 0.78, blue: 0.20, alpha: 1)
glyph("A", size: 400, weight: .heavy, color: .white, center: NSPoint(x: 342, y: 640))
glyph("Я", size: 400, weight: .heavy, color: .white, center: NSPoint(x: 682, y: 640))

func arrow(centerY: CGFloat, pointingRight: Bool) {
    let left: CGFloat = 300, right: CGFloat = 724
    let bar: CGFloat = 52, headW: CGFloat = 120, headH: CGFloat = 150
    let p = NSBezierPath()
    if pointingRight {
        p.move(to: NSPoint(x: left, y: centerY - bar / 2))
        p.line(to: NSPoint(x: right - headW, y: centerY - bar / 2))
        p.line(to: NSPoint(x: right - headW, y: centerY - headH / 2))
        p.line(to: NSPoint(x: right, y: centerY))
        p.line(to: NSPoint(x: right - headW, y: centerY + headH / 2))
        p.line(to: NSPoint(x: right - headW, y: centerY + bar / 2))
        p.line(to: NSPoint(x: left, y: centerY + bar / 2))
    } else {
        p.move(to: NSPoint(x: right, y: centerY - bar / 2))
        p.line(to: NSPoint(x: left + headW, y: centerY - bar / 2))
        p.line(to: NSPoint(x: left + headW, y: centerY - headH / 2))
        p.line(to: NSPoint(x: left, y: centerY))
        p.line(to: NSPoint(x: left + headW, y: centerY + headH / 2))
        p.line(to: NSPoint(x: left + headW, y: centerY + bar / 2))
        p.line(to: NSPoint(x: right, y: centerY + bar / 2))
    }
    p.close()
    yellow.setFill()
    p.fill()
}

arrow(centerY: 395, pointingRight: true)
arrow(centerY: 245, pointingRight: false)

img.unlockFocus()

guard let tiff = img.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else { exit(1) }
try! png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
SWIFT

swift "$TMP/IconGen.swift" "$MASTER"

# Build the .iconset at all required sizes, then compile to .icns.
ICONSET="$TMP/AppIcon.iconset"
mkdir -p "$ICONSET"
for sz in 16 32 128 256 512; do
  sips -z $sz $sz                 "$MASTER" --out "$ICONSET/icon_${sz}x${sz}.png" >/dev/null
  sips -z $((sz*2)) $((sz*2))     "$MASTER" --out "$ICONSET/icon_${sz}x${sz}@2x.png" >/dev/null
done

mkdir -p tools/assets
iconutil -c icns "$ICONSET" -o tools/assets/AppIcon.icns
cp "$MASTER" tools/assets/AppIcon_1024.png
rm -rf "$TMP"
echo "✅ tools/assets/AppIcon.icns ($(du -h tools/assets/AppIcon.icns | cut -f1))"
