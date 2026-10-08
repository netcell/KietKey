//
//  SettingsLists.swift
//  KietKey
//
//  Ba danh sách: tổ hợp phím chuyển, quy tắc theo ứng dụng, quy tắc theo website.
//

import SwiftUI
import AppKit

// MARK: - kiểu dữ liệu

struct AppRule: Identifiable, Equatable {
    let id: String          //bundle id
    let name: String
    var mode: Int           //0 luôn tắt · 1 luôn bật · 2 nhớ lần cuối
}

struct WebsiteRule: Identifiable, Equatable {
    var id: String { host }
    let host: String
    var mode: Int           //0 English · 1 tiếng Việt
}

struct SwitchKeyItem: Identifiable, Equatable {
    let id: UUID
    var value: Int
}

enum RuleMode {
    static let appNames = ["Luôn tắt tiếng Việt", "Luôn bật tiếng Việt", "Nhớ lần cuối"]
    static let siteNames = ["Luôn tắt tiếng Việt", "Luôn bật tiếng Việt"]
}

// MARK: - tổ hợp phím chuyển

struct HotkeyListSection: View {
    @ObservedObject var model: SettingsModel
    @State private var recording = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionHeader(text: "Tổ hợp bật/tắt tiếng Việt")
            SettingsCard {
                ForEach(Array(model.switchKeys.enumerated()), id: \.element.id) { index, item in
                    if index > 0 { SettingsDivider() }
                    HStack(spacing: 10) {
                        Text(model.describe(item.value))
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3)
                            .background(.quaternary.opacity(0.6),
                                        in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                        Spacer(minLength: 8)
                        if model.switchKeys.count > 1 {
                            Button {
                                model.removeSwitchKey(at: index)
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Xoá tổ hợp \(model.describe(item.value))")
                        }
                    }
                    .padding(.horizontal, SettingsMetrics.rowPaddingH)
                    .frame(minHeight: SettingsMetrics.rowHeight)
                }

                SettingsDivider()

                HotkeyRecorderRow(recording: $recording) { encoded in
                    model.addSwitchKey(encoded)
                }
            }

            Text("Phải có ít nhất một tổ hợp. Tổ hợp chỉ gồm phím bổ trợ (ví dụ ⌃⇧) "
                 + "kích hoạt khi bạn thả tay ra.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.top, 6)
                .padding(.leading, 4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Hàng "Thêm tổ hợp": khi đang ghi thì bắt phím thật của người dùng.
private struct HotkeyRecorderRow: View {
    @Binding var recording: Bool
    let onCapture: (Int) -> Void

    @State private var monitor: Any?
    @State private var maxFlags: NSEvent.ModifierFlags = []

    var body: some View {
        HStack(spacing: 8) {
            if recording {
                Text("Đang chờ bạn bấm phím…")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    )
                Spacer(minLength: 8)
                Button("Huỷ") { stop() }
                    .controlSize(.small)
            } else {
                Button {
                    start()
                } label: {
                    Label("Thêm tổ hợp", systemImage: "plus")
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
                Spacer(minLength: 8)
            }
        }
        .padding(.horizontal, SettingsMetrics.rowPaddingH)
        .frame(minHeight: SettingsMetrics.rowHeight)
        .onDisappear { stop() }
    }

    private func start() {
        guard monitor == nil else { return }
        recording = true
        maxFlags = []
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            handle(event)
            return nil //nuốt sự kiện để không lọt vào giao diện
        }
    }

    private func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        recording = false
        maxFlags = []
    }

    private func handle(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        if event.type == .keyDown {
            //Esc huỷ
            if event.keyCode == 53 { stop(); return }
            let encoded = KKSettingsActions.encodeSwitchKey(withFlags: flags.rawValue,
                                                            keyCode: Int(event.keyCode),
                                                            character: event.charactersIgnoringModifiers ?? "")
            stop()
            onCapture(encoded)
            return
        }

        //flagsChanged: nhớ tổ hợp lớn nhất, chốt khi người dùng thả hết tay ra
        let interesting: NSEvent.ModifierFlags = [.control, .option, .command, .shift, .function]
        let current = flags.intersection(interesting)
        if current.rawValue > maxFlags.rawValue {
            maxFlags = current
            return
        }
        if current.isEmpty && !maxFlags.isEmpty {
            let encoded = KKSettingsActions.encodeSwitchKey(withFlags: maxFlags.rawValue,
                                                           keyCode: -1,
                                                           character: "")
            stop()
            onCapture(encoded)
        }
    }
}

// MARK: - quy tắc theo ứng dụng

struct AppRulesSection: View {
    @ObservedObject var model: SettingsModel
    @State private var showPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionHeader(text: "Ứng dụng")
            SettingsCard {
                if model.appRules.isEmpty {
                    Text("Chưa có ứng dụng nào. Thêm để ép tắt hoặc bật tiếng Việt khi dùng app đó.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, SettingsMetrics.rowPaddingH)
                        .frame(maxWidth: .infinity, minHeight: SettingsMetrics.rowHeight,
                               alignment: .leading)
                } else {
                    ForEach(Array(model.appRules.enumerated()), id: \.element.id) { index, rule in
                        if index > 0 { SettingsDivider() }
                        SettingsRow(title: rule.name, subtitle: rule.id) {
                            HStack(spacing: 6) {
                                Picker("", selection: Binding(
                                    get: { rule.mode },
                                    set: { model.setAppRuleMode($0, for: rule.id) })) {
                                    ForEach(0..<RuleMode.appNames.count, id: \.self) { i in
                                        Text(RuleMode.appNames[i]).tag(i)
                                    }
                                }
                                .labelsHidden()
                                .fixedSize()
                                Button {
                                    model.removeAppRule(rule.id)
                                } label: {
                                    Image(systemName: "minus.circle")
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                                .accessibilityLabel("Xoá quy tắc cho \(rule.name)")
                            }
                        }
                    }
                }

                SettingsDivider()

                HStack {
                    Button {
                        model.reloadPickableApps()
                        showPicker = true
                    } label: {
                        Label("Thêm ứng dụng", systemImage: "plus").font(.system(size: 13))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                    .popover(isPresented: $showPicker, arrowEdge: .bottom) {
                        AppPickerList(model: model, isPresented: $showPicker)
                    }
                    Spacer(minLength: 8)
                }
                .padding(.horizontal, SettingsMetrics.rowPaddingH)
                .frame(minHeight: SettingsMetrics.rowHeight)
            }
        }
    }
}

private struct AppPickerList: View {
    @ObservedObject var model: SettingsModel
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Ứng dụng đang chạy")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 6)
            if model.pickableApps.isEmpty {
                Text("Không có ứng dụng nào để thêm.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(12)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(model.pickableApps) { app in
                            Button {
                                model.setAppRuleMode(0, for: app.id)
                                isPresented = false
                            } label: {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(app.name).font(.system(size: 13))
                                    Text(app.id).font(.system(size: 10.5)).foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 260)
            }
        }
        .frame(width: 290)
        .padding(.bottom, 8)
    }
}

// MARK: - quy tắc theo website

struct WebsiteRulesSection: View {
    @ObservedObject var model: SettingsModel
    @State private var newHost = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SettingsSectionHeader(text: "Website")
            SettingsCard {
                if model.websiteRules.isEmpty {
                    Text("Chưa có tên miền nào.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, SettingsMetrics.rowPaddingH)
                        .frame(maxWidth: .infinity, minHeight: SettingsMetrics.rowHeight,
                               alignment: .leading)
                } else {
                    ForEach(Array(model.websiteRules.enumerated()), id: \.element.id) { index, rule in
                        if index > 0 { SettingsDivider() }
                        SettingsRow(title: rule.host, subtitle: "Áp dụng cho cả tên miền con") {
                            HStack(spacing: 6) {
                                Picker("", selection: Binding(
                                    get: { rule.mode },
                                    set: { model.setWebsiteRuleMode($0, for: rule.host) })) {
                                    ForEach(0..<RuleMode.siteNames.count, id: \.self) { i in
                                        Text(RuleMode.siteNames[i]).tag(i)
                                    }
                                }
                                .labelsHidden()
                                .fixedSize()
                                Button {
                                    model.removeWebsiteRule(rule.host)
                                } label: {
                                    Image(systemName: "minus.circle")
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                                .accessibilityLabel("Xoá quy tắc cho \(rule.host)")
                            }
                        }
                    }
                }

                SettingsDivider()

                HStack(spacing: 8) {
                    TextField("Thêm tên miền, ví dụ github.com", text: $newHost)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12.5))
                        .onSubmit(addHost)
                    Button("Thêm", action: addHost)
                        .controlSize(.small)
                        .disabled(newHost.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, SettingsMetrics.rowPaddingH)
                .frame(minHeight: SettingsMetrics.rowHeight + 4)
            }

            SettingsNotice(text: "Chỉ đọc tên miền của tab đang xem, qua Accessibility. "
                           + "Không đọc đường dẫn, không đọc nội dung trang, không gửi đi đâu. "
                           + "Đã thử với Safari; các trình duyệt nền Chromium chưa kiểm chứng.")
                .padding(.top, 10)
        }
    }

    private func addHost() {
        let host = newHost.trimmingCharacters(in: .whitespaces)
        guard !host.isEmpty else { return }
        model.setWebsiteRuleMode(0, for: host)
        newHost = ""
    }
}
