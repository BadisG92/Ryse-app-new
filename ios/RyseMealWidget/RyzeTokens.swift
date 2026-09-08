//
//  RyzeTokens.swift
//  RyseMealWidget
//
//  The Ryze design system as the widgets see it. Mirrors lib/design/tokens.dart
//  and lib/design/type.dart: a value changed there is changed here.
//

import CoreText
import SwiftUI

/// Colours. The rule of the app holds in the widget: ink is what the user
/// chooses or presses, amber is what Ryze gives back, and one variable, the
/// fill, carries the state of a slot.
enum RyzeColor {
    static let paper = Color(rgb: 0xF5F6F8)
    static let paper2 = Color(rgb: 0xEEF0F4)
    static let surf = Color(rgb: 0xFFFFFF)
    static let ink = Color(rgb: 0x0B132B)
    static let ink2 = Color(rgb: 0x1B2A5B)

    /// 5.2:1 on paper, above AA for the small print it carries.
    static let mute = Color(rgb: 0x5F6779)

    /// Decorative only (dashes, borders): too light for text.
    static let mute2 = Color(rgb: 0x9AA1B2)
    static let line = Color(rgb: 0x0B132B).opacity(0.10)
    static let line2 = Color(rgb: 0x0B132B).opacity(0.06)

    /// The idle fill of a free slot and of the gauge's track.
    static let idle = Color(rgb: 0xD5DAE1)

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

/// The palette the user chose in the settings (lib/design/palette.dart): the
/// ink and its accent vary, paper and the greys do not. The app sends it
/// with its data; before the first write the widget wears the original one.
struct RyzePalette {
    let key: String
    let ink: Color
    let ink2: Color
    let acc: Color
    let accInk: Color

    var line: Color { ink.opacity(0.10) }
    var line2: Color { ink.opacity(0.06) }

    static let nuit = RyzePalette(key: "nuit", ink: RyzeColor.ink, ink2: RyzeColor.ink2, acc: RyzeColor.acc, accInk: RyzeColor.accInk)

    static func from(_ json: [String: Any]?) -> RyzePalette {
        guard let json else { return .nuit }
        func color(_ key: String, _ fallback: Color) -> Color {
            (json[key] as? String).flatMap { Color(hexString: $0) } ?? fallback
        }
        return RyzePalette(
            key: json["key"] as? String ?? "nuit",
            ink: color("ink", RyzePalette.nuit.ink),
            ink2: color("ink2", RyzePalette.nuit.ink2),
            acc: color("acc", RyzePalette.nuit.acc),
            accInk: color("accInk", RyzePalette.nuit.accInk)
        )
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

    /// "#RRGGBB", as the app writes its palette.
    init?(hexString: String) {
        let digits = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard digits.count == 6, let rgb = UInt32(digits, radix: 16) else { return nil }
        self.init(rgb: rgb)
    }
}

/// The gauge under the figure: the track is the idle grey, the fill is the
/// one accent element of the widget.
struct AmberGauge: View {
    let fraction: Double
    var color: Color = RyzeColor.acc
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(RyzeColor.idle)
                Capsule()
                    .fill(color)
                    .frame(width: max(0, geometry.size.width * min(max(fraction, 0), 1)))
            }
        }
        .frame(height: height)
    }
}
