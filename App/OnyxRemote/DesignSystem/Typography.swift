import SwiftUI

/// IBM Plex Sans for UI text, IBM Plex Mono for addresses/IDs/command line —
/// bundled locally (OFL), never a system font substitute, since the design
/// spec calls out specific weights at specific sizes.
enum Typography {
    static func sans(_ size: CGFloat, weight: SansWeight = .regular) -> Font {
        .custom(weight.postScriptName, size: size)
    }

    static func mono(_ size: CGFloat, weight: MonoWeight = .regular) -> Font {
        .custom(weight.postScriptName, size: size)
    }

    enum SansWeight {
        case regular, medium, semibold, bold

        var postScriptName: String {
            switch self {
            case .regular: return "IBMPlexSans-Regular"
            case .medium: return "IBMPlexSans-Medium"
            case .semibold: return "IBMPlexSans-SemiBold"
            case .bold: return "IBMPlexSans-Bold"
            }
        }
    }

    enum MonoWeight {
        case regular, medium, semibold

        var postScriptName: String {
            switch self {
            case .regular: return "IBMPlexMono-Regular"
            case .medium: return "IBMPlexMono-Medium"
            case .semibold: return "IBMPlexMono-SemiBold"
            }
        }
    }

    // Common text roles used across screens.
    static let title = sans(20, weight: .semibold)
    static let sectionHeader = sans(13, weight: .semibold)
    static let body = sans(15)
    static let caption = sans(12)
    static let bigMonoReadout = mono(48, weight: .medium)
    static let monoID = mono(15, weight: .medium)
    static let commandLine = mono(18)
}
