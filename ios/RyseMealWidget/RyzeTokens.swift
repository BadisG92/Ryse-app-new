//
//  RyzeTokens.swift
//  RyseMealWidget
//
//  The Ryze design system as the widgets see it. Mirrors lib/design/tokens.dart,
//  lib/design/palette.dart and lib/design/type.dart: a value changed there is
//  changed here.
//

import CoreText
import SwiftUI

/// The original edition, Nuit: navy and amber on grey paper. What a widget
/// wears before the app has ever written an edition, and the values every
/// other edition is read against.
enum RyzeColor {
    static let paper0 = Color(rgb: 0xF8F9FB)
    static let paper = Color(rgb: 0xF5F6F8)
    static let paper2 = Color(rgb: 0xEEF0F4)
    static let surf = Color(rgb: 0xFFFFFF)
    static let text = Color(rgb: 0x0B132B)
    static let mute = Color(rgb: 0x5F6779)
    static let mute2 = Color(rgb: 0x9AA1B2)
    static let idle = Color(rgb: 0xD5DAE1)
    static let ink = Color(rgb: 0x0B132B)
    static let ink2 = Color(rgb: 0x1B2A5B)
    static let acc = Color(rgb: 0xF2A93B)
    static let accInk = Color(rgb: 0x9A5F0C)
}

/// Corner radii. Cards are large, controls medium, tiles small.
enum RyzeRadius {
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let pill: CGFloat = 999
}

enum RyzeSpace {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
}

/// An edition of Ryze, as the user chose it in the settings.
///
/// An edition owns its ground — paper, card, greys, text — and not only its
/// mark: that is what makes it read as another app rather than as a colour
/// option. The rule of the app holds on the widget: ink is what the user
/// chooses or presses, the accent is what Ryze gives back, and on a dark
/// edition what is written on ink is the card, not white. The app sends
/// the edition with its data; before the first write the widget wears Nuit.
struct RyzePalette {
    let key: String
    let dark: Bool
    let paper0: Color
    let paper: Color
    let paper2: Color
    let surf: Color
    let text: Color
    let mute: Color
    let mute2: Color
    let idle: Color
    let ink: Color
    let ink2: Color
    let acc: Color
    let accInk: Color

    /// The light edge of a free slot and of a card: the text at 11 %, as
    /// the tokens derive it, so it stays visible on a dark ground.
    var line: Color { text.opacity(0.11) }
    var line2: Color { text.opacity(0.06) }

    /// What is written on an ink surface. The card follows the ground, so
    /// "surf on ink" reads right on a light edition and on a dark one.
    var onInk: Color { surf }

    static let nuit = RyzePalette(
        key: "theme_nuit",
        dark: false,
        paper0: RyzeColor.paper0,
        paper: RyzeColor.paper,
        paper2: RyzeColor.paper2,
        surf: RyzeColor.surf,
        text: RyzeColor.text,
        mute: RyzeColor.mute,
        mute2: RyzeColor.mute2,
        idle: RyzeColor.idle,
        ink: RyzeColor.ink,
        ink2: RyzeColor.ink2,
        acc: RyzeColor.acc,
        accInk: RyzeColor.accInk
    )

    static func from(_ json: [String: Any]?) -> RyzePalette {
        guard let json else { return .nuit }
        func color(_ key: String, _ fallback: Color) -> Color {
            (json[key] as? String).flatMap { Color(hexString: $0) } ?? fallback
        }
        let base = RyzePalette.nuit
        return RyzePalette(
            key: json["key"] as? String ?? base.key,
            dark: json["dark"] as? Bool ?? false,
            paper0: color("paper0", base.paper0),
            paper: color("paper", base.paper),
            paper2: color("paper2", base.paper2),
            surf: color("surf", base.surf),
            text: color("text", base.text),
            mute: color("mute", base.mute),
            mute2: color("mute2", base.mute2),
            idle: color("idle", base.idle),
            ink: color("ink", base.ink),
            ink2: color("ink2", base.ink2),
            acc: color("acc", base.acc),
            accInk: color("accInk", base.accInk)
        )
    }
}

/// Archivo for the figure, Instrument Sans for everything else: the two
/// variable files the app bundles, registered by the extension's Info.plist.
///
/// The weight is set on the font's own axis, the only way a variable font
/// gives a weight it has no named instance for. If a file is missing the
/// system face steps in, so a build never shows blank text.
enum RyzeFont {
    static func display(_ size: CGFloat, weight: CGFloat = 800) -> Font {
        variable("Archivo-SemiBold", size: size, weight: weight,
                 fallback: .system(size: size, weight: .heavy, design: .rounded))
    }

    static func body(_ size: CGFloat, weight: CGFloat = 400) -> Font {
        variable("InstrumentSans-Regular", size: size, weight: weight,
                 fallback: .system(size: size, weight: weight >= 600 ? .semibold : .regular))
    }

    /// Archivo's tracking in the app: -0.028 em.
    static func tracking(_ size: CGFloat) -> CGFloat { -0.028 * size }

    /// The 'wght' axis, as CoreText names it.
    private static let weightAxis = 0x7767_6874

    private static func variable(_ postScriptName: String, size: CGFloat, weight: CGFloat, fallback: Font) -> Font {
        guard UIFont(name: postScriptName, size: size) != nil else { return fallback }
        let variation: [Int: Any] = [weightAxis: weight]
        let descriptor = UIFontDescriptor(fontAttributes: [
            .name: postScriptName,
            UIFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String): variation,
        ])
        return Font(UIFont(descriptor: descriptor, size: size) as CTFont)
    }
}

extension Color {
    init(rgb: UInt32) {
        self.init(
            .sRGB,
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255,
            opacity: 1
        )
    }

    /// "#RRGGBB", as the app writes its edition.
    init?(hexString: String) {
        let digits = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard digits.count == 6, let rgb = UInt32(digits, radix: 16) else { return nil }
        self.init(rgb: rgb)
    }
}

/// The gauge under the figure: the track is the edition's idle grey, the
/// fill is the one accent element of the widget.
struct AmberGauge: View {
    let fraction: Double
    var color: Color = RyzeColor.acc
    var track: Color = RyzeColor.idle
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule()
                    .fill(color)
                    .frame(width: max(0, geometry.size.width * min(max(fraction, 0), 1)))
            }
        }
        .frame(height: height)
    }
}
