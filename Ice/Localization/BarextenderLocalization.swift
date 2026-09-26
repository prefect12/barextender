//
//  BarextenderLocalization.swift
//  Barextender
//

import Foundation

enum BarextenderLocalization {
    static let locale = Locale(identifier: "zh-Hans")

    private static let chineseBundle: Bundle = {
        guard
            let url = Bundle.main.url(forResource: "zh-Hans", withExtension: "lproj"),
            let bundle = Bundle(url: url)
        else {
            return .main
        }
        return bundle
    }()

    static func string(_ key: String) -> String {
        chineseBundle.localizedString(forKey: key, value: key, table: "Localizable")
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: locale, arguments: arguments)
    }
}
