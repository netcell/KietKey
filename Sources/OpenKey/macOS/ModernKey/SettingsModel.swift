//
//  SettingsModel.swift
//  KietKey
//
//  Trạng thái cho cửa sổ Settings. Mọi thay đổi đẩy xuống KKSettingsActions
//  (Objective-C) để engine nhận được, chứ không ghi thẳng vào NSUserDefaults.
//

import SwiftUI

@MainActor
final class SettingsModel: ObservableObject {

    // MARK: gõ tiếng Việt

    @Published var vietnamese: Bool {
        didSet {
            guard vietnamese != KKSettingsActions.vietnameseEnabled() else { return }
            KKSettingsActions.setVietnameseEnabled(vietnamese)
        }
    }

    @Published var inputType: Int {
        didSet { KKSettingsActions.setInputType(inputType) }
    }

    @Published var codeTable: Int {
        didSet { KKSettingsActions.setCodeTable(codeTable) }
    }

    @Published var spelling: Bool {
        didSet { KKSettingsActions.setFlag(spelling, forKey: "Spelling") }
    }

    @Published var modernOrthography: Bool {
        didSet { KKSettingsActions.setFlag(modernOrthography, forKey: "ModernOrthography") }
    }

    @Published var freeMark: Bool {
        didSet { KKSettingsActions.setFlag(freeMark, forKey: "FreeMark") }
    }

    @Published var quickTelex: Bool {
        didSet { KKSettingsActions.setFlag(quickTelex, forKey: "QuickTelex") }
    }

    @Published var upperCaseFirstChar: Bool {
        didSet { KKSettingsActions.setFlag(upperCaseFirstChar, forKey: "UpperCaseFirstChar") }
    }

    /// 0 không can thiệp · 1 nhường bộ gõ hệ thống · 2 khoá ở ABC
    @Published var systemInputSourceMode: Int {
        didSet {
            KKSettingsActions.setSystemInputSourceMode(
                KKSystemInputSourceMode(rawValue: systemInputSourceMode) ?? .ignore)
        }
    }

    // MARK: phím chuyển & báo hiệu

    @Published var showHUD: Bool {
        didSet { KKSettingsActions.setFlag(showHUD, forKey: "vShowSwitchHUD") }
    }

    // MARK: nhớ theo ứng dụng

    @Published var rememberLanguagePerApp: Bool {
        didSet { KKSettingsActions.setFlag(rememberLanguagePerApp, forKey: "UseSmartSwitchKey") }
    }

    @Published var rememberCodeTablePerApp: Bool {
        didSet { KKSettingsActions.setFlag(rememberCodeTablePerApp, forKey: "vRememberCode") }
    }

    // MARK: dữ liệu chỉ đọc

    let inputTypeNames: [String]
    let codeTableNames: [String]
    let versionString: String

    init() {
        vietnamese = KKSettingsActions.vietnameseEnabled()
        inputType = KKSettingsActions.inputType()
        codeTable = KKSettingsActions.codeTable()
        spelling = KKSettingsActions.flag(forKey: "Spelling")
        modernOrthography = KKSettingsActions.flag(forKey: "ModernOrthography")
        freeMark = KKSettingsActions.flag(forKey: "FreeMark")
        quickTelex = KKSettingsActions.flag(forKey: "QuickTelex")
        upperCaseFirstChar = KKSettingsActions.flag(forKey: "UpperCaseFirstChar")
        systemInputSourceMode = KKSettingsActions.systemInputSourceMode().rawValue
        showHUD = KKSettingsActions.flag(forKey: "vShowSwitchHUD")
        rememberLanguagePerApp = KKSettingsActions.flag(forKey: "UseSmartSwitchKey")
        rememberCodeTablePerApp = KKSettingsActions.flag(forKey: "vRememberCode")

        inputTypeNames = KKSettingsActions.inputTypeNames()
        codeTableNames = KKSettingsActions.codeTableNames()
        versionString = KKSettingsActions.versionString()
    }

    /// Đọc lại từ engine — gọi khi cửa sổ hiện ra, vì trạng thái có thể đã đổi
    /// bằng phím chuyển hoặc theo ứng dụng/website trong lúc cửa sổ đóng.
    func refresh() {
        let current = KKSettingsActions.vietnameseEnabled()
        if vietnamese != current { vietnamese = current }
        let type = KKSettingsActions.inputType()
        if inputType != type { inputType = type }
        let table = KKSettingsActions.codeTable()
        if codeTable != table { codeTable = table }
    }
}
