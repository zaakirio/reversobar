import SwiftUI

/// The compact header pill that opens the language dropdown.
struct LangPill: View {
    let lang: Language
    let isOpen: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                FlagImage(code: lang.flag, width: 22)
                Text(lang.short)
                    .font(.system(size: 13, weight: .semibold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isOpen ? 180 : 0))
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .pillBackground(active: isOpen)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .pointingHand()
        .help(lang.name)
    }
}

/// The flag-rich dropdown list shown when a pill is open.
struct LanguageDropdown: View {
    let selected: Language
    let other: Language          // the opposite side, disabled to keep sides distinct
    let onSelect: (Language) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 2) {
                ForEach(Language.all) { lang in
                    LanguageRow(lang: lang, isSelected: lang == selected, isDisabled: lang == other) {
                        onSelect(lang)
                    }
                }
            }
            .padding(6)
        }
        .frame(width: 232)
        .frame(maxHeight: 340)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.dropdown, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.dropdown, style: .continuous).stroke(.black.opacity(0.12)))
        .shadow(color: .black.opacity(0.28), radius: 16, y: 8)
    }
}

struct LanguageRow: View {
    let lang: Language
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                FlagImage(code: lang.flag, width: 26)
                VStack(alignment: .leading, spacing: 1) {
                    Text(lang.name).font(.system(size: 13, weight: .medium))
                    Text(lang.native).font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.tint)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                (hover && !isDisabled) ? AnyShapeStyle(.tint.opacity(0.16)) : AnyShapeStyle(.clear),
                in: RoundedRectangle(cornerRadius: 7, style: .continuous)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.35 : 1)
        .onHover { hover = $0 }
        .pointingHand()
    }
}
