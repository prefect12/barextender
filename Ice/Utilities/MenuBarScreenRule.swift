import Foundation

enum MenuBarScreenRule {
    static func threshold(_ value: Double) -> Double {
        value.isFinite ? min(max(value, 1_000), 8_000) : 3_000
    }

    static func shouldShowAll(enabled: Bool, pixelWidth: Int, threshold: Double) -> Bool {
        enabled && pixelWidth > 0 && Double(pixelWidth) > self.threshold(threshold)
    }
}
