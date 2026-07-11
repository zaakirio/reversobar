import SwiftUI
import AppKit

enum PickerSide { case source, target }
enum Mode { case search, bookmarks }

/// Root popover view. Owns the search/bookmark state and composes the header, search field,
/// results, and footer; individual pieces live in their own files.
struct ContentView: View {
    @StateObject private var vm = SearchViewModel()
    @ObservedObject private var bookmarks = BookmarkStore.shared
    @FocusState private var searchFocused: Bool
    @State private var copiedToast: String?
    @State private var toastTask: Task<Void, Never>?
    @State private var pickerSide: PickerSide?
    @State private var mode: Mode = .search
    @State private var bookmarkFilter = ""

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                header
                searchField
                if vm.phonetic && vm.canPhonetic {
                    PhoneticPreview(cyrillic: vm.cyrillicPreview,
                                    phonemes: vm.phonemes,
                                    language: vm.sourceLang,
                                    onCopy: { copy($0, label: "\(vm.sourceLang.name) copied") })
                }
                Divider().opacity(0.5)
                results
                FooterBar()
            }

            if let side = pickerSide {
                Color.black.opacity(0.04)
                    .contentShape(Rectangle())
                    .onTapGesture { closePicker() }
                    .transition(.opacity)

                LanguageDropdown(
                    selected: side == .source ? vm.sourceLang : vm.targetLang,
                    other: side == .source ? vm.targetLang : vm.sourceLang
                ) { lang in
                    if side == .source { vm.setSource(lang) } else { vm.setTarget(lang) }
                    closePicker()
                }
                .padding(.top, 46)
                .padding(.leading, side == .source ? 14 : 108)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(width: Theme.popoverSize.width, height: Theme.popoverSize.height)
        .background(VisualEffectView(material: .popover))
        .overlay(alignment: .bottom) { toast }
        .onAppear {
            focusSoon()
            applyLaunchDebugFlags()
        }
        .onReceive(NotificationCenter.default.publisher(for: .popoverDidOpen)) { _ in focusSoon() }
        .onExitCommand(perform: handleEscape)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 6) {
            LangPill(lang: vm.sourceLang, isOpen: pickerSide == .source) { togglePicker(.source) }

            Button(action: { withAnimation(.snappy) { vm.swap() } }) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(6)
                    .background(.quaternary.opacity(0.5), in: Circle())
            }
            .buttonStyle(.plain)
            .pointingHand()
            .help("Swap languages")

            LangPill(lang: vm.targetLang, isOpen: pickerSide == .target) { togglePicker(.target) }

            Spacer(minLength: 6)

            if vm.canPhonetic {
                Toggle(isOn: $vm.phonetic.animation(.snappy)) {
                    HStack(spacing: 5) {
                        Image(systemName: "keyboard")
                        Text("Phonetic")
                    }
                    .font(.system(size: 12, weight: .medium))
                }
                .toggleStyle(.button)
                .pointingHand()
                .help("Type Latin letters to build \(vm.sourceLang.name) (Cyrillic) words")
                .transition(.scale.combined(with: .opacity))
            }

            bookmarksToggle
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var bookmarksToggle: some View {
        Button(action: toggleBookmarksMode) {
            HStack(spacing: 4) {
                Image(systemName: mode == .bookmarks ? "bookmark.fill" : "bookmark")
                if !bookmarks.items.isEmpty {
                    Text("\(bookmarks.items.count)").font(.system(size: 11, weight: .semibold))
                }
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(mode == .bookmarks ? Color.accentColor : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.tint.opacity(mode == .bookmarks ? 0.18 : 0), in: Capsule())
        }
        .buttonStyle(.plain)
        .pointingHand()
        .help("Saved bookmarks")
    }

    // MARK: - Search field

    private var searchField: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            TextField(searchPrompt, text: mode == .bookmarks ? $bookmarkFilter : $vm.query)
                .textFieldStyle(.plain)
                .font(.system(size: 18))
                .focused($searchFocused)
                .onSubmit { copyPrimaryIfAny() }
            if mode == .search && vm.isLoading {
                ProgressView().controlSize(.small)
            } else if !currentFieldText.isEmpty {
                Button(action: clearField) {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .pointingHand()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: Theme.Radius.field))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.field).stroke(.quaternary, lineWidth: 0.5))
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }

    private var currentFieldText: String {
        mode == .bookmarks ? bookmarkFilter : vm.query
    }

    private var searchPrompt: String {
        if mode == .bookmarks { return "Filter bookmarks…" }
        return (vm.phonetic && vm.canPhonetic) ? "privet → привет…" : "Translate \(vm.sourceLang.name)…"
    }

    // MARK: - Results

    @ViewBuilder private var results: some View {
        if mode == .bookmarks { bookmarksList } else { searchResults }
    }

    private var searchResults: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 11) {
                if let error = vm.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .padding(.top, 24)
                        .frame(maxWidth: .infinity)
                } else if let output = vm.output {
                    if let corrected = output.correctedText, !corrected.isEmpty {
                        Label("Did you mean: \(corrected)", systemImage: "text.badge.checkmark")
                            .font(.system(size: 12))
                            .foregroundStyle(.orange)
                    }

                    if !output.primary.isEmpty {
                        let mark = makeBookmark(output.primary)
                        PrimaryCard(
                            text: output.primary,
                            language: vm.effectiveTo,
                            isBookmarked: bookmarks.contains(mark),
                            onBookmark: { toggleBookmark(mark) },
                            onCopy: { copy($0, label: "Copied") }
                        )
                    }

                    if !output.alternatives.isEmpty {
                        Text("OTHER TRANSLATIONS")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(0.6)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 2)
                        ForEach(output.alternatives) { alt in
                            let mark = makeBookmark(alt.translation, transliteration: alt.transliteration)
                            AlternativeRow(
                                alternative: alt,
                                targetLanguage: vm.effectiveTo,
                                isBookmarked: bookmarks.contains(mark),
                                onBookmark: { toggleBookmark(mark) },
                                onCopy: { copy($0, label: "Copied") }
                            )
                        }
                    }
                } else {
                    searchEmptyState
                }
            }
            .padding(14)
        }
        .scrollContentBackground(.hidden)
    }

    private var searchEmptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "character.bubble")
                .font(.system(size: 36))
                .foregroundStyle(.tint.opacity(0.55))
            Text("Search a word or sentence")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            VStack(spacing: 3) {
                Text("Click any result to copy · ▶ to hear it · ☆ to save")
                Text("Toggle **Phonetic** to type Cyrillic with Latin letters")
            }
            .font(.system(size: 11))
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
    }

    // MARK: - Bookmarks

    private var filteredBookmarks: [Bookmark] {
        let q = bookmarkFilter.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return bookmarks.items }
        return bookmarks.items.filter {
            $0.source.lowercased().contains(q)
                || $0.translation.lowercased().contains(q)
                || ($0.transliteration?.lowercased().contains(q) ?? false)
        }
    }

    private var bookmarksList: some View {
        ScrollView {
            if bookmarks.items.isEmpty {
                bookmarksEmptyState
            } else if filteredBookmarks.isEmpty {
                Text("No bookmarks match \u{201C}\(bookmarkFilter)\u{201D}")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            } else {
                VStack(spacing: 8) {
                    ForEach(filteredBookmarks) { bm in
                        BookmarkRow(bookmark: bm,
                                    onCopy: { copy($0, label: "Copied") },
                                    onRemove: { bookmarks.remove(bm) })
                    }
                }
                .padding(14)
            }
        }
        .scrollContentBackground(.hidden)
    }

    private var bookmarksEmptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "bookmark")
                .font(.system(size: 36))
                .foregroundStyle(.tint.opacity(0.55))
            Text("No bookmarks yet")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            Text("Tap the ☆ on any translation to save it here")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
    }

    // MARK: - Toast

    @ViewBuilder private var toast: some View {
        if let text = copiedToast {
            Label(text, systemImage: toastIcon(for: text))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.accentColor, in: Capsule())
                .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
                .padding(.bottom, 48)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Actions

    private func togglePicker(_ side: PickerSide) {
        withAnimation(Theme.Anim.snappy) { pickerSide = (pickerSide == side) ? nil : side }
    }

    private func closePicker() {
        withAnimation(Theme.Anim.snappy) { pickerSide = nil }
        focusSoon()
    }

    private func toggleBookmarksMode() {
        withAnimation(Theme.Anim.snappy) {
            mode = (mode == .bookmarks) ? .search : .bookmarks
            pickerSide = nil
        }
        focusSoon()
    }

    private func handleEscape() {
        if pickerSide != nil { closePicker() }
        else if mode == .bookmarks { withAnimation(Theme.Anim.snappy) { mode = .search }; focusSoon() }
        else { NotificationCenter.default.post(name: .requestClose, object: nil) }
    }

    private func makeBookmark(_ translation: String, transliteration: String? = nil) -> Bookmark {
        Bookmark(source: vm.effectiveSource,
                 sourceLang: vm.effectiveFrom.code,
                 translation: translation,
                 targetLang: vm.effectiveTo.code,
                 transliteration: transliteration)
    }

    private func toggleBookmark(_ mark: Bookmark) {
        let added = !bookmarks.contains(mark)
        bookmarks.toggle(mark)
        flashToast(added ? "Bookmarked" : "Removed")
    }

    private func copyPrimaryIfAny() {
        if let primary = vm.output?.primary, !primary.isEmpty {
            copy(primary, label: "Copied")
        } else if vm.phonetic && vm.canPhonetic, !vm.cyrillicPreview.isEmpty {
            copy(vm.cyrillicPreview, label: "\(vm.sourceLang.name) copied")
        }
    }

    private func clearField() {
        if mode == .bookmarks { bookmarkFilter = "" } else { vm.clear() }
        focusSoon()
    }

    private func copy(_ text: String, label: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        flashToast(label)
    }

    private func toastIcon(for label: String) -> String {
        switch label {
        case "Bookmarked": return "star.fill"
        case "Removed": return "star.slash.fill"
        default: return "checkmark.circle.fill"
        }
    }

    private func flashToast(_ label: String) {
        toastTask?.cancel()
        withAnimation(Theme.Anim.toast) { copiedToast = label }
        toastTask = Task {
            try? await Task.sleep(for: .seconds(1.1))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) { copiedToast = nil }
        }
    }

    private func focusSoon() {
        Task {
            try? await Task.sleep(for: .milliseconds(60))
            searchFocused = true
        }
    }

    /// Dev-only launch flags used by the `--window` preview build for screenshots.
    private func applyLaunchDebugFlags() {
        let args = CommandLine.arguments
        if args.contains("--bookmarks") { mode = .bookmarks }
        if args.contains("--open-picker-target") { pickerSide = .target }
        else if args.contains("--open-picker") { pickerSide = .source }
    }
}
