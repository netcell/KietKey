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

    @Published var restoreIfInvalidWord: Bool {
        didSet { KKSettingsActions.setFlag(restoreIfInvalidWord, forKey: "RestoreIfInvalidWord") }
    }

    @Published var allowZFWJ: Bool {
        didSet { KKSettingsActions.setFlag(allowZFWJ, forKey: "vAllowConsonantZFWJ") }
    }

    @Published var tempOffSpelling: Bool {
        didSet { KKSettingsActions.setFlag(tempOffSpelling, forKey: "vTempOffSpelling") }
    }

    // MARK: phím chuyển

    @Published var beepOnSwitch: Bool {
        didSet { KKSettingsActions.setBeepOnSwitch(beepOnSwitch) }
    }

    @Published var tempOffByCommand: Bool {
        didSet { KKSettingsActions.setFlag(tempOffByCommand, forKey: "vTempOffOpenKey") }
    }

    // MARK: gõ tắt

    @Published var useMacro: Bool {
        didSet { KKSettingsActions.setFlag(useMacro, forKey: "UseMacro") }
    }

    @Published var useMacroInEnglish: Bool {
        didSet { KKSettingsActions.setFlag(useMacroInEnglish, forKey: "UseMacroInEnglishMode") }
    }

    @Published var autoCapsMacro: Bool {
        didSet { KKSettingsActions.setFlag(autoCapsMacro, forKey: "vAutoCapsMacro") }
    }

    @Published var quickStartConsonant: Bool {
        didSet { KKSettingsActions.setFlag(quickStartConsonant, forKey: "vQuickStartConsonant") }
    }

    @Published var quickEndConsonant: Bool {
        didSet { KKSettingsActions.setFlag(quickEndConsonant, forKey: "vQuickEndConsonant") }
    }

    // MARK: nâng cao

    @Published var runOnStartup: Bool {
        didSet { KKSettingsActions.setFlag(runOnStartup, forKey: "RunOnStartup") }
    }

    @Published var showIconOnDock: Bool {
        didSet { KKSettingsActions.setFlag(showIconOnDock, forKey: "vShowIconOnDock") }
    }

    @Published var showSettingsOnStartup: Bool {
        didSet { KKSettingsActions.setFlag(showSettingsOnStartup, forKey: "ShowUIOnStartup") }
    }

    @Published var grayIcon: Bool {
        didSet { KKSettingsActions.setFlag(grayIcon, forKey: "GrayIcon") }
    }

    @Published var sendKeyStepByStep: Bool {
        didSet { KKSettingsActions.setFlag(sendKeyStepByStep, forKey: "SendKeyStepByStep") }
    }

    @Published var fixRecommendBrowser: Bool {
        didSet { KKSettingsActions.setFlag(fixRecommendBrowser, forKey: "FixRecommendBrowser") }
    }

    @Published var fixChromium: Bool {
        didSet { KKSettingsActions.setFlag(fixChromium, forKey: "vFixChromiumBrowser") }
    }

    @Published var performLayoutCompat: Bool {
        didSet { KKSettingsActions.setFlag(performLayoutCompat, forKey: "vPerformLayoutCompat") }
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

    @Published var hijackInputSourceKey: Bool {
        didSet { KKSettingsActions.setFlag(hijackInputSourceKey, forKey: "vHijackInputSourceKey") }
    }

    // MARK: nhớ theo ứng dụng

    @Published var rememberLanguagePerApp: Bool {
        didSet { KKSettingsActions.setFlag(rememberLanguagePerApp, forKey: "UseSmartSwitchKey") }
    }

    @Published var rememberCodeTablePerApp: Bool {
        didSet { KKSettingsActions.setFlag(rememberCodeTablePerApp, forKey: "vRememberCode") }
    }

    // MARK: danh sách

    @Published var switchKeys: [SwitchKeyItem] = []
    @Published var appRules: [AppRule] = []
    @Published var websiteRules: [WebsiteRule] = []
    @Published var pickableApps: [AppRule] = []

    func describe(_ hotKey: Int) -> String {
        KKSettingsActions.describeSwitchKey(hotKey)
    }

    func reloadLists() {
        switchKeys = KKSettingsActions.switchKeys().map {
            SwitchKeyItem(id: UUID(), value: $0.intValue)
        }
        appRules = KKSettingsActions.appRules().map {
            AppRule(id: $0["id"] as? String ?? "",
                    name: $0["name"] as? String ?? "",
                    mode: ($0["mode"] as? NSNumber)?.intValue ?? 2)
        }
        websiteRules = KKSettingsActions.websiteRules().map {
            WebsiteRule(host: $0["host"] as? String ?? "",
                        mode: ($0["mode"] as? NSNumber)?.intValue ?? 0)
        }
    }

    func reloadPickableApps() {
        pickableApps = KKSettingsActions.pickableApps().map {
            AppRule(id: $0["id"] as? String ?? "", name: $0["name"] as? String ?? "", mode: 0)
        }
    }

    // MARK: sửa danh sách

    func addSwitchKey(_ value: Int) {
        guard !switchKeys.contains(where: { $0.value == value }) else { return }
        let keys = switchKeys.map { $0.value } + [value]
        KKSettingsActions.setSwitchKeys(keys.map { NSNumber(value: $0) })
        reloadLists()
    }

    func removeSwitchKey(at index: Int) {
        guard switchKeys.count > 1, switchKeys.indices.contains(index) else { return }
        var keys = switchKeys.map { $0.value }
        keys.remove(at: index)
        KKSettingsActions.setSwitchKeys(keys.map { NSNumber(value: $0) })
        reloadLists()
    }

    func setAppRuleMode(_ mode: Int, for bundleId: String) {
        KKSettingsActions.setAppRuleMode(mode, forBundleId: bundleId)
        reloadLists()
    }

    func removeAppRule(_ bundleId: String) {
        KKSettingsActions.removeAppRule(forBundleId: bundleId)
        reloadLists()
    }

    func setWebsiteRuleMode(_ mode: Int, for host: String) {
        KKSettingsActions.setWebsiteRuleMode(mode, forHost: host)
        reloadLists()
    }

    func removeWebsiteRule(_ host: String) {
        KKSettingsActions.removeWebsiteRule(forHost: host)
        reloadLists()
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
        hijackInputSourceKey = KKSettingsActions.flag(forKey: "vHijackInputSourceKey")
        rememberLanguagePerApp = KKSettingsActions.flag(forKey: "UseSmartSwitchKey")
        rememberCodeTablePerApp = KKSettingsActions.flag(forKey: "vRememberCode")
        restoreIfInvalidWord = KKSettingsActions.flag(forKey: "RestoreIfInvalidWord")
        allowZFWJ = KKSettingsActions.flag(forKey: "vAllowConsonantZFWJ")
        tempOffSpelling = KKSettingsActions.flag(forKey: "vTempOffSpelling")
        beepOnSwitch = KKSettingsActions.beepOnSwitch()
        tempOffByCommand = KKSettingsActions.flag(forKey: "vTempOffOpenKey")
        useMacro = KKSettingsActions.flag(forKey: "UseMacro")
        useMacroInEnglish = KKSettingsActions.flag(forKey: "UseMacroInEnglishMode")
        autoCapsMacro = KKSettingsActions.flag(forKey: "vAutoCapsMacro")
        quickStartConsonant = KKSettingsActions.flag(forKey: "vQuickStartConsonant")
        quickEndConsonant = KKSettingsActions.flag(forKey: "vQuickEndConsonant")
        runOnStartup = KKSettingsActions.flag(forKey: "RunOnStartup")
        showIconOnDock = KKSettingsActions.flag(forKey: "vShowIconOnDock")
        grayIcon = KKSettingsActions.flag(forKey: "GrayIcon")
        showSettingsOnStartup = KKSettingsActions.flag(forKey: "ShowUIOnStartup")
        sendKeyStepByStep = KKSettingsActions.flag(forKey: "SendKeyStepByStep")
        fixRecommendBrowser = KKSettingsActions.flag(forKey: "FixRecommendBrowser")
        fixChromium = KKSettingsActions.flag(forKey: "vFixChromiumBrowser")
        performLayoutCompat = KKSettingsActions.flag(forKey: "vPerformLayoutCompat")

        inputTypeNames = KKSettingsActions.inputTypeNames()
        codeTableNames = KKSettingsActions.codeTableNames()
        versionString = KKSettingsActions.versionString()

        reloadLists()
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
        reloadLists()
    }
}
