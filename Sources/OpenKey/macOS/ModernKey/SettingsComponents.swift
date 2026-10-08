//
//  SettingsComponents.swift
//  KietKey
//
//  Các khối dùng chung cho cửa sổ Settings.
//
//  Tự dựng thay vì dùng Form(.grouped)/GroupBox: mỗi loại có inset riêng nên
//  trộn chúng lại thì các khối không thẳng hàng với nhau.
//

import SwiftUI

enum SettingsMetrics {
    static let cardRadius: CGFloat = 10
    static let rowHeight: CGFloat = 38
    static let rowPaddingH: CGFloat = 14
    static let blockSpacing: CGFloat = 18
    static let contentPadding: CGFloat = 22
}

// MARK: - tiêu đề nhóm

struct SettingsSectionHeader: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .textCase(.uppercase)
            .tracking(0.4)
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
            .padding(.bottom, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - thẻ chứa các hàng

struct SettingsCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary,
                    in: RoundedRectangle(cornerRadius: SettingsMetrics.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SettingsMetrics.cardRadius, style: .continuous)
                .strokeBorder(.separator.opacity(0.8), lineWidth: 1)
        )
    }
}

/// Một hàng trong thẻ: nhãn bên trái, điều khiển bên phải.
struct SettingsRow<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            trailing
        }
        .padding(.horizontal, SettingsMetrics.rowPaddingH)
        .frame(minHeight: SettingsMetrics.rowHeight)
        .padding(.vertical, 2)
    }
}

/// Vạch ngăn giữa hai hàng, thụt vào cho khớp kiểu macOS.
struct SettingsDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, SettingsMetrics.rowPaddingH)
    }
}

// MARK: - hộp ghi chú

struct SettingsNotice: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
                .font(.system(size: 13))
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.35),
                    in: RoundedRectangle(cornerRadius: SettingsMetrics.cardRadius, style: .continuous))
    }
}
