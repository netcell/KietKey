//
//  SettingsWindow.swift
//  KietKey
//
//  Cửa sổ chứa giao diện SwiftUI. Phía Objective-C gọi qua KKSettingsWindow.
//

import AppKit
import SwiftUI

@objc(KKSettingsWindow)
@MainActor
final class SettingsWindow: NSObject {

    private static var shared: SettingsWindow?

    private let model = SettingsModel()
    private var window: NSWindow?

    /// Mở cửa sổ Settings, tạo mới nếu chưa có.
    @objc static func show() {
        let instance = shared ?? SettingsWindow()
        shared = instance
        instance.present()
    }

    private func present() {
        if window == nil {
            let hosting = NSHostingController(rootView: SettingsRootView(model: model))
            let window = NSWindow(contentViewController: hosting)
            window.title = "KietKey"
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
            window.titlebarAppearsTransparent = false
            window.isReleasedWhenClosed = false
            window.setContentSize(NSSize(width: 820, height: 600))
            window.center()
            self.window = window
        }

        model.refresh()

        //App chạy dạng agent (LSUIElement) nên phải tự kích hoạt, nếu không
        //cửa sổ hiện ra mà không nhận bàn phím. KHÔNG đổi activationPolicy:
        //đổi sang .regular sẽ làm hiện icon trên Dock ngoài ý muốn.
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
