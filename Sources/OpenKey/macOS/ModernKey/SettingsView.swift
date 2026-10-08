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
}

struct SettingsRootView: View {
    @ObservedObject var model: SettingsModel
    @State private var section: SettingsSection = .typing

    var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $section) { item in
                Label(item.title, systemImage: item.symbol)
                    .tag(item)
            }
            .navigationSplitViewColumnWidth(min: 196, ideal: 206, max: 240)
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("KietKey \(model.versionString)")
                    Text("Không kết nối Internet")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
            }
        } detail: {
            ScrollView {
                content
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(section.title)
        }
        .frame(minWidth: 760, idealWidth: 820, minHeight: 540, idealHeight: 600)
    }

    @ViewBuilder
    private var content: some View {
        switch section {
        case .typing:   TypingSettings(model: model)
        case .hotkeys:  HotkeySettings(model: model)
        case .apps:     AppSettings(model: model)
        case .macro:    PlaceholderSettings(title: "Gõ tắt",
                                            note: "Phần này vẫn dùng cửa sổ cũ: menu KietKey → Gõ tắt…")
        case .advanced: PlaceholderSettings(title: "Nâng cao",
                                            note: "Các tuỳ chọn còn lại vẫn nằm ở Bảng điều khiển cũ.")
        }
    }
}

// MARK: - Gõ tiếng Việt

private struct TypingSettings: View {
    @ObservedObject var model: SettingsModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {

            StatusCard(model: model)

            Form {
                Picker("Kiểu gõ", selection: $model.inputType) {
                    ForEach(Array(model.inputTypeNames.enumerated()), id: \.offset) { index, name in
                        Text(name).tag(index)
                    }
                }
                Picker("Bảng mã", selection: $model.codeTable) {
                    ForEach(Array(model.codeTableNames.enumerated()), id: \.offset) { index, name in
                        Text(name).tag(index)
                    }
                }
                Toggle("Kiểm tra chính tả", isOn: $model.spelling)
                Toggle("Đặt dấu kiểu mới (oà, uý)", isOn: $model.modernOrthography)
                Toggle("Bỏ dấu tự do", isOn: $model.freeMark)
                Toggle("Gõ nhanh (cc = ch, gg = gi, …)", isOn: $model.quickTelex)
                Toggle("Viết hoa chữ cái đầu câu", isOn: $model.upperCaseFirstChar)
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
            .frame(height: 260)

            GroupBox {
                Picker("", selection: $model.systemInputSourceMode) {
                    Text("Không can thiệp").tag(0)
                    Text("Nhường bộ gõ hệ thống — tự tắt tiếng Việt của KietKey").tag(1)
                    Text("Khoá ở ABC — chỉ khi đang gõ tiếng Việt").tag(2)
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
                .padding(.vertical, 2)
            } label: {
                Text("Khi bộ gõ của macOS đổi sang tiếng khác")
                    .font(.subheadline.weight(.semibold))
            }
        }
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
                Text(model.vietnamese ? "Đang gõ tiếng Việt" : "Đang gõ English")
                    .font(.system(size: 14, weight: .semibold))
                Text("Dùng phím chuyển để bật/tắt bất cứ lúc nào")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Toggle("", isOn: $model.vietnamese)
                .labelsHidden()
                .toggleStyle(.switch)
                .accessibilityLabel("Bật tiếng Việt")
        }
        .padding(14)
        .background(.quaternary.opacity(0.5),
                    in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}

// MARK: - Phím chuyển

private struct HotkeySettings: View {
    @ObservedObject var model: SettingsModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Form {
                Toggle("Hiện báo hiệu giữa màn hình khi chuyển", isOn: $model.showHUD)
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
            .frame(height: 70)

            NoticeBox(
                text: "Phần đặt tổ hợp phím chuyển vẫn nằm ở Bảng điều khiển cũ "
                    + "(menu KietKey → Bảng điều khiển…). Phần nhiều tổ hợp cùng lúc chưa làm.")
        }
    }
}

// MARK: - Ứng dụng & Website

private struct AppSettings: View {
    @ObservedObject var model: SettingsModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Form {
                Toggle("Tự ghi nhớ tiếng Việt / English theo ứng dụng",
                       isOn: $model.rememberLanguagePerApp)
                Toggle("Tự ghi nhớ bảng mã theo ứng dụng",
                       isOn: $model.rememberCodeTablePerApp)
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
            .frame(height: 110)

            NoticeBox(
                text: "Danh sách ứng dụng và website với ba chế độ (luôn tắt / luôn bật / "
                    + "nhớ lần cuối) chưa có giao diện. Quy tắc theo tên miền đang đặt bằng:\n"
                    + "defaults write com.tuyenmai.openkey vWebsiteRules -dict github.com 0")
        }
    }
}

// MARK: - dùng chung

private struct PlaceholderSettings: View {
    let title: String
    let note: String

    var body: some View {
        NoticeBox(text: note)
    }
}

private struct NoticeBox: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.4),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
