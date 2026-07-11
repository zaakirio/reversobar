#!/bin/bash
# Generates AppIcon.icns from a programmatically-drawn 1024px master:
# two overlapping speech bubbles in different scripts (文 / A) — the "translation" motif.
set -euo pipefail
cd "$(dirname "$0")/.."
TMP="$(mktemp -d)"
MASTER="$TMP/icon_1024.png"

cat > "$TMP/IconGen.swift" <<'SWIFT'
import AppKit

let size: CGFloat = 1024
let img = NSImage(size: NSSize(width: size, height: size))
img.lockFocus()
let ctx = NSGraphicsContext.current!

func bubble(_ body: NSRect, radius: CGFloat, tail: [NSPoint], fill: NSColor) {
    ctx.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.20)
    shadow.shadowBlurRadius = 26
    shadow.shadowOffset = NSSize(width: 0, height: -8)
    shadow.set()
    fill.setFill()
    let path = NSBezierPath(roundedRect: body, xRadius: radius, yRadius: radius)
    let t = NSBezierPath()
    t.move(to: tail[0]); t.line(to: tail[1]); t.line(to: tail[2]); t.close()
    path.append(t)
    path.fill()
    ctx.restoreGraphicsState()
}

func glyph(_ s: String, size fs: CGFloat, color: NSColor, center: NSPoint) {
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: fs, weight: .bold),
        .foregroundColor: color
    ]
    let a = NSAttributedString(string: s, attributes: attrs)
    let sz = a.size()
    a.draw(at: NSPoint(x: center.x - sz.width / 2, y: center.y - sz.height / 2))
}

// Rounded app tile with a blue→indigo gradient (Apple icon grid: inset + ~22% radius).
let inset: CGFloat = 100
let rect = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
NSBezierPath(roundedRect: rect, xRadius: rect.width * 0.2237, yRadius: rect.width * 0.2237).addClip()
NSGradient(colors: [
    NSColor(srgbRed: 0.36, green: 0.55, blue: 0.96, alpha: 1),
    NSColor(srgbRed: 0.45, green: 0.36, blue: 0.93, alpha: 1)
])!.draw(in: rect, angle: -90)

let indigo = NSColor(srgbRed: 0.37, green: 0.32, blue: 0.84, alpha: 1)

// Back bubble — the "other" script (文), deep indigo with a white glyph.
let back = NSRect(x: 215, y: 478, width: 372, height: 300)
bubble(back, radius: 82,
       tail: [NSPoint(x: 285, y: 486), NSPoint(x: 372, y: 486), NSPoint(x: 250, y: 420)],
       fill: NSColor(srgbRed: 0.30, green: 0.25, blue: 0.70, alpha: 1))
glyph("文", size: 188, color: .white, center: NSPoint(x: 401, y: 628))

// Front bubble — Latin (A), white with an indigo glyph.
let front = NSRect(x: 440, y: 238, width: 386, height: 318)
bubble(front, radius: 86,
       tail: [NSPoint(x: 520, y: 246), NSPoint(x: 612, y: 246), NSPoint(x: 506, y: 178)],
       fill: .white)
glyph("A", size: 240, color: indigo, center: NSPoint(x: 633, y: 398))

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
