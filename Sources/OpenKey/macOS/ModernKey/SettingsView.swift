//
//  SettingsView.swift
//  KietKey
//
//  Cửa sổ Settings: sidebar + các nhóm thẻ, theo kiểu System Settings của macOS.
//

import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable {
    case typing, hotkeys, apps, macro, advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .typing:   return "Gõ tiếng Việt"
        case .hotkeys:  return "Phím chuyển"
        case .apps:     return "Ứng dụng & Website"
        case .macro:    return "Gõ tắt"
        case .advanced: return "Nâng cao"
        }
    }

    var symbol: String {
        switch self {
        case .typing:   return "textformat"
        case .hotkeys:  return "keyboard"
        case .apps:     return "square.grid.2x2"
        case .macro:    return "text.insert"
        case .advanced: return "slider.horizontal.3"
        }
    }

    /// Từ khoá phụ để ô tìm kiếm bắt được cả khi gõ tên tuỳ chọn.
    var keywords: String {
        switch self {
        case .typing:   return "telex vni unicode chính tả bảng mã kiểu gõ dấu"
        case .hotkeys:  return "tổ hợp phím tắt hud báo hiệu fn shift control"
        case .apps:     return "ứng dụng website tên miền ghi nhớ safari chrome"
        case .macro:    return "gõ tắt macro viết tắt"
        case .advanced: return "nâng cao khác"
        }
    }
}

struct SettingsRootView: View {
    @ObservedObject var model: SettingsModel
    @State private var section: SettingsSection = SettingsSection(
        rawValue: UserDefaults.standard.string(forKey: "vSettingsInitialSection") ?? "typing") ?? .typing
    @State private var query: String = ""

    private var sections: [SettingsSection] {
        let needle = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !needle.isEmpty else { return SettingsSection.allCases }
        return SettingsSection.allCases.filter {
            $0.title.lowercased().contains(needle) || $0.keywords.contains(needle)
        }
    }

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 200, ideal: 210, max: 250)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: SettingsMetrics.blockSpacing) {
                    content
                }
                .padding(SettingsMetrics.contentPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(section.title)
        }
        .frame(minWidth: 780, idealWidth: 860, minHeight: 560, idealHeight: 620)
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                TextField("Tìm cài đặt", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12.5))
                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Xoá ô tìm kiếm")
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.quaternary.opacity(0.5),
                        in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 6)

            List(sections, selection: $section) { item in
                Label(item.title, systemImage: item.symbol)
                    .tag(item)
            }
            .listStyle(.sidebar)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text("KietKey \(model.versionString)")
                Text("Không kết nối Internet")
            }
            .font(.system(size: 10.5))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch section {
        case .typing:   TypingSettings(model: model)
        case .hotkeys:  HotkeySettings(model: model)
        case .apps:     AppSettings(model: model)
        case .macro:    MacroSettings(model: model)
        case .advanced: AdvancedSettings(model: model)
        }
    }
}

// MARK: - Gõ tiếng Việt

private struct TypingSettings: View {
    @ObservedObject var model: SettingsModel

    var body: some View {
        StatusCard(model: model)

        SettingsCard {
            SettingsRow(title: "Kiểu gõ") {
                Picker("", selection: $model.inputType) {
                    ForEach(Array(model.inputTypeNames.enumerated()), id: \.offset) { index, name in
                        Text(name).tag(index)
                    }
                }
                .labelsHidden()
                .fixedSize()
            }
            SettingsDivider()
            SettingsRow(title: "Bảng mã") {
                Picker("", selection: $model.codeTable) {
                    ForEach(Array(model.codeTableNames.enumerated()), id: \.offset) { index, name in
                        Text(name).tag(index)
                    }
                }
                .labelsHidden()
                .fixedSize()
            }
            SettingsDivider()
            SettingsRow(title: "Đặt dấu kiểu mới", subtitle: "oà, uý thay vì òa, úy") {
                Toggle("", isOn: $model.modernOrthography).labelsHidden()
            }
            SettingsDivider()
            SettingsRow(title: "Bỏ dấu tự do") {
                Toggle("", isOn: $model.freeMark).labelsHidden()
            }
            SettingsDivider()
            SettingsRow(title: "Gõ nhanh", subtitle: "cc = ch, gg = gi, kk = kh, nn = ng…") {
                Toggle("", isOn: $model.quickTelex).labelsHidden()
            }
            SettingsDivider()
            SettingsRow(title: "Viết hoa chữ cái đầu câu") {
                Toggle("", isOn: $model.upperCaseFirstChar).labelsHidden()
            }
        }

        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionHeader(text: "Chính tả")
            SettingsCard {
                SettingsRow(title: "Kiểm tra chính tả") {
                    Toggle("", isOn: $model.spelling).labelsHidden()
                }
                SettingsDivider()
                SettingsRow(title: "Tự khôi phục phím với từ sai") {
                    Toggle("", isOn: $model.restoreIfInvalidWord).labelsHidden()
                        .disabled(!model.spelling)
                }
                SettingsDivider()
                SettingsRow(title: "Cho phép z, w, j, f làm phụ âm đầu") {
                    Toggle("", isOn: $model.allowZFWJ).labelsHidden()
                        .disabled(!model.spelling)
                }
                SettingsDivider()
                SettingsRow(title: "Tạm tắt chính tả bằng phím ⌃",
                            subtitle: "Dùng khi gõ từ như Đắk Lắk, Krông…") {
                    Toggle("", isOn: $model.tempOffSpelling).labelsHidden()
                }
            }
        }

        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionHeader(text: "Khi bộ gõ của macOS đổi sang tiếng khác")
            SettingsCard {
                ModeRow(title: "Không can thiệp",
                        tag: 0, selection: $model.systemInputSourceMode)
                SettingsDivider()
                ModeRow(title: "Nhường bộ gõ hệ thống",
                        subtitle: "Tự tắt tiếng Việt của KietKey",
                        tag: 1, selection: $model.systemInputSourceMode)
                SettingsDivider()
                ModeRow(title: "Khoá ở ABC",
                        subtitle: "Chỉ áp dụng khi đang gõ tiếng Việt",
                        tag: 2, selection: $model.systemInputSourceMode)
            }
        }
    }
}

/// Hàng chọn kiểu radio, chiếm trọn bề ngang để thẳng hàng với các thẻ khác.
private struct ModeRow: View {
    let title: String
    var subtitle: String? = nil
    let tag: Int
    @Binding var selection: Int

    var body: some View {
        Button {
            selection = tag
        } label: {
            HStack(spacing: 10) {
                Image(systemName: selection == tag ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 14))
                    .foregroundStyle(selection == tag ? Color.accentColor : Color.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 13))
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .padding(.horizontal, SettingsMetrics.rowPaddingH)
            .frame(minHeight: SettingsMetrics.rowHeight)
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selection == tag ? [.isSelected] : [])
    }
}

private struct StatusCard: View {
    @ObservedObject var model: SettingsModel

    var body: some View {
        HStack(spacing: 13) {
            Text(model.vietnamese ? "V" : "E")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(model.vietnamese ? Color.accentColor : Color.secondary,
                            in: RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("Gõ tiếng Việt")
                    .font(.system(size: 14, weight: .semibold))
                Text(model.vietnamese
                     ? "Đang bật — dùng phím chuyển để tắt bất cứ lúc nào"
                     : "Đang tắt — gõ English")
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Toggle("", isOn: $model.vietnamese)
                .labelsHidden()
                .toggleStyle(.switch)
                .accessibilityLabel("Gõ tiếng Việt")
        }
        .padding(.horizontal, SettingsMetrics.rowPaddingH)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [Color.accentColor.opacity(model.vietnamese ? 0.20 : 0.08),
                                    Color.accentColor.opacity(0.04)],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.accentColor.opacity(model.vietnamese ? 0.35 : 0.18), lineWidth: 1)
        )
    }
}

// MARK: - Phím chuyển

private struct HotkeySettings: View {
    @ObservedObject var model: SettingsModel

    var body: some View {
        HotkeyListSection(model: model)

        SettingsCard {
            SettingsRow(title: "Hiện báo hiệu giữa màn hình khi chuyển",
                        subtitle: "Thay cho tiếng beep") {
                Toggle("", isOn: $model.showHUD).labelsHidden()
            }
            SettingsDivider()
            SettingsRow(title: "Kêu beep khi chuyển") {
                Toggle("", isOn: $model.beepOnSwitch).labelsHidden()
            }
            SettingsDivider()
            SettingsRow(title: "Dùng phím chuyển bộ gõ của macOS",
                        subtitle: "⌃Space sẽ bật/tắt tiếng Việt thay vì đổi bộ gõ hệ thống") {
                Toggle("", isOn: $model.hijackInputSourceKey).labelsHidden()
            }
            SettingsDivider()
            SettingsRow(title: "Tạm tắt KietKey bằng phím ⌘",
                        subtitle: "Giữ Command thì ngừng gõ tiếng Việt cho tới từ tiếp theo") {
                Toggle("", isOn: $model.tempOffByCommand).labelsHidden()
            }
        }

        SettingsNotice(text: "Phím 🌐 không chiếm được: macOS xử lý nó ở tầng thấp hơn. "
                       + "Nếu muốn dùng fn làm phím chuyển, đặt System Settings → Keyboard → "
                       + "“Press 🌐 key to” thành “Do Nothing”.")
    }
}

// MARK: - Ứng dụng & Website

private struct AppSettings: View {
    @ObservedObject var model: SettingsModel

    var body: some View {
        SettingsCard {
            SettingsRow(title: "Tự ghi nhớ tiếng Việt / English theo ứng dụng",
                        subtitle: "Áp dụng cho ứng dụng chưa có trong danh sách") {
                Toggle("", isOn: $model.rememberLanguagePerApp).labelsHidden()
            }
            SettingsDivider()
            SettingsRow(title: "Tự ghi nhớ bảng mã theo ứng dụng") {
                Toggle("", isOn: $model.rememberCodeTablePerApp).labelsHidden()
            }
        }

        AppRulesSection(model: model)

        WebsiteRulesSection(model: model)
    }
}


// MARK: - Gõ tắt

private struct MacroSettings: View {
    @ObservedObject var model: SettingsModel

    var body: some View {
        SettingsCard {
            SettingsRow(title: "Cho phép gõ tắt") {
                Toggle("", isOn: $model.useMacro).labelsHidden()
            }
            SettingsDivider()
            SettingsRow(title: "Gõ tắt cả khi đang tắt tiếng Việt") {
                Toggle("", isOn: $model.useMacroInEnglish).labelsHidden()
                    .disabled(!model.useMacro)
            }
            SettingsDivider()
            SettingsRow(title: "Tự động viết hoa theo phím tắt") {
                Toggle("", isOn: $model.autoCapsMacro).labelsHidden()
                    .disabled(!model.useMacro)
            }
            SettingsDivider()
            SettingsRow(title: "Bảng gõ tắt") {
                Button("Mở…") { KKSettingsActions.openMacroWindow() }
                    .controlSize(.small)
            }
        }

        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionHeader(text: "Gõ tắt phụ âm")
            SettingsCard {
                SettingsRow(title: "Phụ âm đầu", subtitle: "f → ph, j → gi, w → qu…") {
                    Toggle("", isOn: $model.quickStartConsonant).labelsHidden()
                }
                SettingsDivider()
                SettingsRow(title: "Phụ âm cuối", subtitle: "g → ng, h → nh, k → ch…") {
                    Toggle("", isOn: $model.quickEndConsonant).labelsHidden()
                }
            }
        }
    }
}

// MARK: - Nâng cao

private struct AdvancedSettings: View {
    @ObservedObject var model: SettingsModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionHeader(text: "Khởi động & biểu tượng")
            SettingsCard {
                SettingsRow(title: "Khởi động cùng macOS") {
                    Toggle("", isOn: $model.runOnStartup).labelsHidden()
                }
                SettingsDivider()
                SettingsRow(title: "Hiện biểu tượng trên thanh Dock") {
                    Toggle("", isOn: $model.showIconOnDock).labelsHidden()
                }
                SettingsDivider()
                SettingsRow(title: "Biểu tượng hiện đại trên thanh menu",
                            subtitle: "Hợp với chế độ tối") {
                    Toggle("", isOn: $model.grayIcon).labelsHidden()
                }
                SettingsDivider()
                SettingsRow(title: "Mở cửa sổ này khi khởi động") {
                    Toggle("", isOn: $model.showSettingsOnStartup).labelsHidden()
                }
            }
        }

        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionHeader(text: "Tương thích")
            SettingsCard {
                SettingsRow(title: "Sửa lỗi gợi ý",
                            subtitle: "Trình duyệt, Excel và các ô có gợi ý tự động") {
                    Toggle("", isOn: $model.fixRecommendBrowser).labelsHidden()
                }
                SettingsDivider()
                SettingsRow(title: "Sửa lỗi trên Chromium",
                            subtitle: "Chỉ bật khi Chrome/Edge gõ bị sai") {
                    Toggle("", isOn: $model.fixChromium).labelsHidden()
                        .disabled(!model.fixRecommendBrowser)
                }
                SettingsDivider()
                SettingsRow(title: "Tương thích Telex trên layout khác",
                            subtitle: "Dvorak, Colemak…") {
                    Toggle("", isOn: $model.performLayoutCompat).labelsHidden()
                }
                SettingsDivider()
                SettingsRow(title: "Gửi từng phím",
                            subtitle: "Chậm hơn; chỉ bật khi một ứng dụng nào đó gõ bị lỗi") {
                    Toggle("", isOn: $model.sendKeyStepByStep).labelsHidden()
                }
            }
        }

        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionHeader(text: "Công cụ")
            SettingsCard {
                SettingsRow(title: "Chuyển mã clipboard") {
                    Button("Mở…") { KKSettingsActions.openConvertTool() }
                        .controlSize(.small)
                }
                SettingsDivider()
                SettingsRow(title: "Mã nguồn",
                            subtitle: "KietKey dựa trên OpenKey, giấy phép GPL") {
                    Button("Mở GitHub…") { KKSettingsActions.openSourceCodePage() }
                        .controlSize(.small)
                }
            }
        }
    }
}
