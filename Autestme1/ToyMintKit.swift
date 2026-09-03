// ToyMintKit — Autestme's Toy Mint design layer.
//
// One-file design system: semantic tokens + reusable SwiftUI components.
// No game, Firebase, Web3, timer or audio logic lives here — this file is
// intentionally decoupled so a visual change never risks the mechanics.

import SwiftUI

// MARK: - Colour tokens

extension Color {
    static let mintPetrol       = Color("MintPetrol")
    static let mintPetrolDeep   = Color("MintPetrolDeep")
    static let mintPetrolSoft   = Color("MintPetrolSoft")
    static let mintCream        = Color("MintCream")
    static let mintCreamBright  = Color("MintCreamBright")
    static let mintCoral        = Color("MintCoral")
    static let mintCoralDark    = Color("MintCoralDark")
    static let mintGreen        = Color("MintGreen")
    static let mintYellow       = Color("MintYellow")
    static let mintLilac        = Color("MintLilac")
    static let mintChrome       = Color("MintChrome")
}

// MARK: - Game palette
//
// A curated Toy Mint palette used only for in-game shape/letter/number
// tinting during play. Kept here so the game screen never has to reach for
// system reds/blues/oranges, and so the mapping can be tuned without
// touching GameLogic.

enum ToyMintPalette {
    /// Coral, mint-green, yellow, lilac, cream, petrol-soft — the six
    /// on-brand colours listed in the design brief for the play surface.
    static let playful: [Color] = [
        .mintCoral,
        .mintGreen,
        .mintYellow,
        .mintLilac,
        .mintCream,
        .mintPetrolSoft,
    ]

    /// Pick a random colour from `playful`. Used for the "random" colour
    /// mode; falls back to cream so we never render invisible.
    static func randomPlayful() -> Color {
        playful.randomElement() ?? .mintCream
    }

    /// Stable colour for a `ShapeType` based on its raw value.
    static func color(for shape: ShapeType) -> Color {
        playful[shape.rawValue % playful.count]
    }

    /// Stable colour for a letter A…Z, cycling through the palette.
    static func color(for letter: Character) -> Color {
        let base = Int(Character("A").asciiValue ?? 65)
        let idx  = Int(letter.asciiValue ?? UInt8(base)) - base
        return playful[abs(idx) % playful.count]
    }

    /// Stable colour for an integer index.
    static func color(for number: Int) -> Color {
        playful[abs(number) % playful.count]
    }
}

// MARK: - Spacing / radii / strokes / shadows

enum ToyMint {
    enum Spacing {
        static let xs: CGFloat  = 4
        static let s:  CGFloat  = 8
        static let m:  CGFloat  = 12
        static let l:  CGFloat  = 16
        static let xl: CGFloat  = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let s:  CGFloat = 8
        static let m:  CGFloat = 14
        static let l:  CGFloat = 22
        static let pill: CGFloat = 999
    }

    enum Stroke {
        static let hair: CGFloat = 1
        static let panel: CGFloat = 1.5
        static let heavy: CGFloat = 2.5
    }

    enum Layout {
        static let controlHeight: CGFloat = 56
        static let touchTarget:   CGFloat = 44
        static let panelPaddingV: CGFloat = 16
        static let panelPaddingH: CGFloat = 18
    }
}

// MARK: - Type scale

enum ToyMintFont {
    static var display: Font   { .system(.largeTitle, design: .serif).weight(.semibold) }
    static var title: Font     { .system(.title2,     design: .serif).weight(.semibold) }
    static var section: Font   { .system(.headline,   design: .rounded).weight(.semibold) }
    static var body: Font      { .system(.body) }
    static var caption: Font   { .system(.caption) }
    static var counter: Font   { .system(.title2,     design: .monospaced).weight(.semibold) }
    static var counterXL: Font { .system(size: 44, weight: .semibold, design: .monospaced) }
    static var actionLabel: Font { .system(.headline, design: .rounded).weight(.semibold) }
}

// MARK: - Background canvas

struct ToyMintBackground: View {
    var body: some View {
        Color.mintPetrol
            .ignoresSafeArea()
    }
}

// MARK: - Panel modifier (cream/petrol machine card)

struct MintPanel: ViewModifier {
    enum Style { case cream, petrol, coral }
    var style: Style = .petrol
    var padding: CGFloat = ToyMint.Layout.panelPaddingV

    private var background: Color {
        switch style {
        case .cream:  return .mintCream
        case .petrol: return .mintPetrolSoft
        case .coral:  return .mintCoral
        }
    }

    private var stroke: Color {
        switch style {
        case .cream:  return .mintChrome.opacity(0.55)
        case .petrol: return .mintChrome.opacity(0.35)
        case .coral:  return .mintCoralDark
        }
    }

    func body(content: Content) -> some View {
        content
            .padding(.vertical, padding)
            .padding(.horizontal, ToyMint.Layout.panelPaddingH)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: ToyMint.Radius.m, style: .continuous)
                    .strokeBorder(stroke, lineWidth: ToyMint.Stroke.panel)
            )
            .clipShape(RoundedRectangle(cornerRadius: ToyMint.Radius.m, style: .continuous))
    }
}

extension View {
    func mintPanel(_ style: MintPanel.Style = .petrol, padding: CGFloat = ToyMint.Layout.panelPaddingV) -> some View {
        modifier(MintPanel(style: style, padding: padding))
    }
}

// MARK: - Button styles

struct MintPrimaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ToyMintFont.actionLabel)
            .foregroundColor(.mintCreamBright)
            .frame(maxWidth: .infinity)
            .frame(minHeight: ToyMint.Layout.controlHeight)
            .padding(.horizontal, ToyMint.Spacing.l)
            .background(
                RoundedRectangle(cornerRadius: ToyMint.Radius.l, style: .continuous)
                    .fill(isEnabled
                          ? (configuration.isPressed ? Color.mintCoralDark : Color.mintCoral)
                          : Color.mintCoral.opacity(0.45))
            )
            .overlay(
                RoundedRectangle(cornerRadius: ToyMint.Radius.l, style: .continuous)
                    .strokeBorder(Color.mintCreamBright.opacity(0.15), lineWidth: ToyMint.Stroke.hair)
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1.0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct MintSecondaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ToyMintFont.actionLabel)
            .foregroundColor(.mintCream)
            .padding(.vertical, ToyMint.Spacing.s)
            .padding(.horizontal, ToyMint.Spacing.l)
            .frame(minHeight: ToyMint.Layout.touchTarget)
            .background(
                RoundedRectangle(cornerRadius: ToyMint.Radius.l, style: .continuous)
                    .fill(configuration.isPressed
                          ? Color.mintPetrolDeep.opacity(0.6)
                          : Color.mintPetrolDeep.opacity(0.35))
            )
            .overlay(
                RoundedRectangle(cornerRadius: ToyMint.Radius.l, style: .continuous)
                    .strokeBorder(Color.mintCream.opacity(0.4), lineWidth: ToyMint.Stroke.panel)
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1.0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct MintGhostButtonStyle: ButtonStyle {
    var tint: Color = .mintCream

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ToyMintFont.caption.weight(.semibold))
            .foregroundColor(tint.opacity(configuration.isPressed ? 0.6 : 1.0))
            .padding(.vertical, ToyMint.Spacing.xs)
            .padding(.horizontal, ToyMint.Spacing.s)
            .frame(minHeight: ToyMint.Layout.touchTarget)
            .contentShape(Rectangle())
    }
}

// MARK: - Mechanical counter

struct MintCounter: View {
    let title: String
    let value: String
    var accent: Color = .mintYellow
    var size: Size = .medium

    enum Size { case medium, large }

    var body: some View {
        HStack(spacing: ToyMint.Spacing.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ToyMintFont.caption)
                    .foregroundColor(.mintCream.opacity(0.75))
                Text(value)
                    .font(size == .large ? ToyMintFont.counterXL : ToyMintFont.counter)
                    .foregroundColor(accent)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, ToyMint.Spacing.s)
        .padding(.horizontal, ToyMint.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: ToyMint.Radius.s, style: .continuous)
                .fill(Color.mintPetrolDeep)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ToyMint.Radius.s, style: .continuous)
                .strokeBorder(Color.mintChrome.opacity(0.3), lineWidth: ToyMint.Stroke.hair)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(title): \(value)"))
    }
}

// MARK: - Segmented control (game mode)

struct MintSegmentedControl<Value: Hashable>: View {
    struct Item: Identifiable {
        let value: Value
        let title: String
        let glyph: Glyph
        let accessibilityLabel: String
        var id: Value { value }
    }

    enum Glyph { case circle, letter(String), digit(String) }

    @Binding var selection: Value
    let items: [Item]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: ToyMint.Spacing.s) {
            ForEach(items) { item in
                Button {
                    if reduceMotion {
                        selection = item.value
                    } else {
                        withAnimation(.easeOut(duration: 0.15)) {
                            selection = item.value
                        }
                    }
                } label: {
                    segmentBody(for: item, selected: selection == item.value)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.accessibilityLabel)
                .accessibilityAddTraits(selection == item.value ? [.isSelected] : [])
            }
        }
    }

    @ViewBuilder
    private func segmentBody(for item: Item, selected: Bool) -> some View {
        VStack(spacing: ToyMint.Spacing.xs) {
            glyphView(item.glyph, selected: selected)
                .frame(height: 42)
            Text(item.title)
                .font(ToyMintFont.section)
                .foregroundColor(selected ? .mintPetrolDeep : .mintCream)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 88)
        .padding(.horizontal, ToyMint.Spacing.s)
        .background(
            RoundedRectangle(cornerRadius: ToyMint.Radius.m, style: .continuous)
                .fill(selected ? Color.mintCream : Color.mintPetrolSoft)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ToyMint.Radius.m, style: .continuous)
                .strokeBorder(selected ? Color.mintCoral : Color.mintChrome.opacity(0.35),
                              lineWidth: selected ? ToyMint.Stroke.heavy : ToyMint.Stroke.panel)
        )
    }

    @ViewBuilder
    private func glyphView(_ glyph: Glyph, selected: Bool) -> some View {
        let fg: Color = selected ? .mintCoral : .mintCream
        switch glyph {
        case .circle:
            Circle()
                .fill(selected ? Color.mintCoral : Color.mintGreen)
                .overlay(
                    Circle()
                        .strokeBorder(selected ? Color.mintCoralDark : Color.mintCream.opacity(0.5),
                                      lineWidth: 2)
                )
                .frame(width: 32, height: 32)
        case .letter(let s):
            Text(s)
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundColor(fg)
        case .digit(let s):
            Text(s)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(fg)
        }
    }
}

// MARK: - Slider row

struct MintSliderRow: View {
    let title: String
    let value: Binding<Double>
    let range: ClosedRange<Double>
    var step: Double = 1
    var valueLabel: String
    var accessibilityValueLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: ToyMint.Spacing.xs) {
            HStack {
                Text(title)
                    .font(ToyMintFont.section)
                    .foregroundColor(.mintCream)
                Spacer()
                Text(valueLabel)
                    .font(ToyMintFont.counter)
                    .foregroundColor(.mintYellow)
                    .monospacedDigit()
            }
            Slider(value: value, in: range, step: step)
                .tint(.mintCoral)
                .accessibilityLabel(title)
                .accessibilityValue(accessibilityValueLabel)
        }
    }
}

// MARK: - Status lamp (colour + text + optional symbol)

struct MintStatusLamp: View {
    enum State { case ok, waiting, warn, off }

    let state: State
    let title: String
    var systemImage: String? = nil

    private var tint: Color {
        switch state {
        case .ok:      return .mintGreen
        case .waiting: return .mintYellow
        case .warn:    return .mintCoral
        case .off:     return .mintChrome
        }
    }

    private var symbolName: String {
        if let systemImage { return systemImage }
        switch state {
        case .ok:      return "checkmark.circle.fill"
        case .waiting: return "hourglass"
        case .warn:    return "exclamationmark.triangle.fill"
        case .off:     return "power.circle"
        }
    }

    var body: some View {
        HStack(spacing: ToyMint.Spacing.s) {
            Image(systemName: symbolName)
                .foregroundColor(tint)
                .font(.system(size: 18, weight: .semibold))
                .accessibilityHidden(true)
            Text(title)
                .font(ToyMintFont.caption.weight(.semibold))
                .foregroundColor(.mintCream)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Wordmark

struct MintWordmark: View {
    var showTagline: Bool = true
    var alignment: HorizontalAlignment = .center

    var body: some View {
        VStack(alignment: alignment, spacing: ToyMint.Spacing.s) {
            Image("MintMark")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .accessibilityHidden(true)
            Text("app_title")
                .font(ToyMintFont.display)
                .foregroundColor(.mintCreamBright)
                .accessibilityAddTraits(.isHeader)
            if showTagline {
                Text("mint_tagline")
                    .font(ToyMintFont.body.weight(.medium))
                    .foregroundColor(.mintCream.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : (alignment == .trailing ? .trailing : .center))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("mint_wordmark_accessibility"))
    }
}

// MARK: - Disclosure lade (expandable AUTEST-rewards drawer)

struct MintDisclosureLade<Content: View>: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey?
    @Binding var isExpanded: Bool
    @ViewBuilder var content: () -> Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: ToyMint.Spacing.s) {
            Button {
                if reduceMotion {
                    isExpanded.toggle()
                } else {
                    withAnimation(.easeOut(duration: 0.18)) { isExpanded.toggle() }
                }
            } label: {
                HStack(spacing: ToyMint.Spacing.m) {
                    Image(systemName: "circle.hexagongrid.fill")
                        .foregroundColor(.mintYellow)
                        .font(.system(size: 20, weight: .semibold))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(ToyMintFont.section)
                            .foregroundColor(.mintCream)
                        if let subtitle {
                            Text(subtitle)
                                .font(ToyMintFont.caption)
                                .foregroundColor(.mintCream.opacity(0.75))
                                .lineLimit(2)
                        }
                    }
                    Spacer(minLength: 0)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.mintCream.opacity(0.7))
                        .accessibilityHidden(true)
                }
                .frame(minHeight: ToyMint.Layout.touchTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isExpanded ? [.isSelected] : [])
            .accessibilityHint(Text(isExpanded ? "disclosure_hint_collapse" : "disclosure_hint_expand"))

            if isExpanded {
                content()
                    .transition(reduceMotion ? .identity : .opacity.combined(with: .move(edge: .top)))
            }
        }
        .mintPanel(.petrol)
    }
}

// MARK: - Field style (text input on petrol)

struct MintFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(ToyMintFont.body)
            .foregroundColor(.mintCreamBright)
            .padding(.vertical, ToyMint.Spacing.m)
            .padding(.horizontal, ToyMint.Spacing.l)
            .frame(minHeight: ToyMint.Layout.controlHeight)
            .background(
                RoundedRectangle(cornerRadius: ToyMint.Radius.m, style: .continuous)
                    .fill(Color.mintPetrolDeep)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ToyMint.Radius.m, style: .continuous)
                    .strokeBorder(Color.mintChrome.opacity(0.35), lineWidth: ToyMint.Stroke.hair)
            )
    }
}
