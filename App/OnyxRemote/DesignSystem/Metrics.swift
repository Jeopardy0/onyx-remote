import CoreGraphics

/// Spacing scale and the 44pt minimum touch target the spec requires
/// everywhere.
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

enum Metrics {
    static let minTouchTarget: CGFloat = 44
    static let cornerRadius: CGFloat = 10
    static let topBarHeight: CGFloat = 52
}
