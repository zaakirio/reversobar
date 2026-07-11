# Reversobar

A fast macOS **menu-bar translator**. Click the menu-bar icon (or press **⌥Space**), type, and
get instant translations across 18 languages — powered by Reverso. Click any result to copy it,
▶ to hear it, ☆ to save it. Includes a **phonetic** mode: type Latin letters and watch them
become Cyrillic in real time, with a per-phoneme breakdown.

<p align="center"><em>EN ⇄ RU · ES · FR · DE · IT · PT · NL · PL · UK · TR · AR · HE · JA · KO · ZH · RO · CS</em></p>

## Features

- **Lives in the status bar** — no Dock icon (`LSUIElement`). **⌥Space** toggles it from
  anywhere (Carbon hotkey, no Accessibility permission). **Esc** closes.
- **Real-time translation** — debounced 220 ms live search; in-flight requests are cancelled as
  you type, so only the latest query matters.
- **Caching** — results are cached (in-memory LRU + on-disk), so repeat lookups are instant and
  skip the network entirely; pronunciations are cached in-memory per session.
- **18 languages** with rounded-rectangle country flags ([flag-icons](https://github.com/lipis/flag-icons), MIT).
  Pick source/target from two flag dropdowns, ⇄ to swap; your last pair is remembered.
- **Phonetic typing (Latin → Cyrillic)** — for Cyrillic source languages (Russian, Ukrainian) a
  **Phonetic** toggle appears: type `privet mir` → **привет мир**, with chips showing each phoneme
  (`sh → ш`, `zh → ж`, `shch → щ`…).
- **Click to copy · ▶ to hear · ☆ to bookmark** — context translations include part of speech,
  a frequency badge, transliteration, and expandable real-world examples.
- **Bookmarks** — a personal phrasebook persisted to disk, with a live filter.

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 16 / Swift 6 toolchain (to build)

## Build & run

```bash
make run        # build and run from the terminal
make preview    # open the UI in a window for inspection
make app        # build a universal, signed Reversobar.app in build/
```

`make app` produces `build/Reversobar.app`. To use it day-to-day:

```bash
cp -R build/Reversobar.app /Applications/
open /Applications/Reversobar.app
```

To launch at login: System Settings → General → Login Items → add Reversobar.

## Project structure

```
Sources/Reversobar/
  App/          main.swift, AppDelegate (status item + popover), HotKeyManager (⌥Space)
  Models/       Language registry, Translation response/output, Bookmark
  Services/     ReversoClient (HTTP), AudioPlayer (TTS), TranslationCache, BookmarkStore, Transliterator
  ViewModels/   SearchViewModel (debounce, cancellation, phonetics)
  Views/        ContentView + focused component views, Theme (constants/modifiers)
  Support/      AppInfo (identity, defaults, notification names)
  Resources/Flags/  bundled flag PNGs
scripts/        build_app · make_dmg · notarize · release · preview
tools/          make_flags · make_icon (regeneration helpers)
```

### Architecture notes

- **UI** is SwiftUI hosted in an `NSPopover` off an `NSStatusItem` (`AppDelegate`). The
  `ContentView` coordinator owns state; every reusable piece (cards, pills, dropdown, rows,
  controls) is its own `View`. Styling constants and shared modifiers live in `Theme`.
- **Caching** — `TranslationCache` is an LRU (in-memory, capped at 400 entries) backed by a
  debounced JSON file in Application Support; `SearchViewModel` consults it before debouncing or
  hitting the network, so cached lookups are instant and work offline. `AudioPlayer` keeps an
  in-memory cache of fetched MP3s.
- **Reverso** — `ReversoClient` calls `api.reverso.net/translate/v1/translation` and the
  `voice.reverso.net` pronunciation endpoint. ⚠️ These are **unofficial** endpoints behind
  Cloudflare bot protection that blocks `curl` (TLS fingerprint) but passes Apple's `URLSession`.
  Test the API from a small Swift `URLSession` script, not `curl`.
- **Concurrency** — the package builds in **Swift 6 language mode** (full data-race checking).
  UI/state types are `@MainActor`; the Carbon hotkey callback hops to the main actor via `Task`.

## Distribution (Developer ID, notarized ZIP + DMG)

The indie-Mac-app model (à la [Itsycal](https://www.mowglii.com/itsycal/)): a signed, notarized app
you download directly — a ZIP as the primary artifact, plus a drag-to-Applications DMG.
One-time setup:

1. **Signing certificate** — a *Developer ID Application* certificate in your keychain
   (auto-detected; override with `REVERSOBAR_SIGN_ID="Developer ID Application: …"`).
2. **Notary credentials** — store an App Store Connect / Apple ID profile once:
   ```bash
   xcrun notarytool store-credentials reversobar \
     --apple-id "you@example.com" --team-id <your-team-id> \
     --password <app-specific-password>      # appleid.apple.com → App-Specific Passwords
   ```

Then, to cut a release:

```bash
make release    # build → notarize app → ZIP → DMG → notarize DMG → staple
```

This runs the full pipeline and leaves two signed, **notarized, stapled** artifacts in `build/`:
`Reversobar-<version>.zip` (the primary download — the stapled app inside) and
`Reversobar-<version>.dmg`. Both open on any Mac with no Gatekeeper warning.
Individual steps are also available:
`make app`, `make dmg`, `make notarize`. The release version lives in the `VERSION` file;
override per-run via `REVERSOBAR_VERSION`, `REVERSOBAR_BUILD`, `REVERSOBAR_SIGN_ID`,
`REVERSOBAR_NOTARY_PROFILE`.

The app uses **hardened runtime** with no special entitlements — it is not sandboxed, and a
non-sandboxed network client needs none.

## Regenerating assets

```bash
make flags    # re-rasterize flag PNGs from flag-icons (edit the country list in tools/make_flags.sh)
make icon     # regenerate AppIcon.icns
```

## Credits & licenses

- Flags: [flag-icons](https://github.com/lipis/flag-icons) by Panayiotis Lipiridis — MIT.
- Translations & pronunciation: [Reverso](https://www.reverso.net) (unofficial endpoints; for
  personal use — respect their terms).
- Menu-bar / icon glyph: Apple SF Symbols.
