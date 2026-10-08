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

        dumpSnapshotIfRequested()
    }

    /// Chụp chính cửa sổ này ra PNG, dùng để đối chiếu giao diện.
    ///
    ///   defaults write com.tuyenmai.openkey vDumpSettingsPNG -string /tmp/kk.png
    ///
    /// Render cây layer của cửa sổ.
    /// KHÔNG dùng cacheDisplay(in:to:) — đã thử, nó bỏ qua phần lớn nội dung
    /// SwiftUI nên ảnh ra gần như trắng.
    /// KHÔNG dùng CGWindowListCreateImage — macOS 26 đã gỡ hẳn API này.
    /// Hệ quả: phần nền mờ (vibrancy) của sidebar sẽ không có trong ảnh,
    /// còn nội dung thì đúng.
    private func dumpSnapshotIfRequested() {
        guard let path = UserDefaults.standard.string(forKey: "vDumpSettingsPNG"),
              !path.isEmpty else { return }

        //đợi SwiftUI bố cục và vẽ xong
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let window = self?.window else { return }
            let image = Self.captureLayer(window)
            guard let image,
                  let data = NSBitmapImageRep(cgImage: image)
                                .representation(using: .png, properties: [:]) else { return }
            try? data.write(to: URL(fileURLWithPath: path))
        }
    }

    private static func captureLayer(_ window: NSWindow) -> CGImage? {
        guard let view = window.contentView, let layer = view.layer else { return nil }
        let scale = window.backingScaleFactor
        let width = Int(view.bounds.width * scale)
        let height = Int(view.bounds.height * scale)
        guard width > 0, height > 0,
              let context = CGContext(data: nil, width: width, height: height,
                                      bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
                                                | CGBitmapInfo.byteOrder32Little.rawValue)
        else { return nil }
        let background = (window.backgroundColor.usingColorSpace(.sRGB) ?? .windowBackgroundColor)
        context.setFillColor(red: background.redComponent,
                             green: background.greenComponent,
                             blue: background.blueComponent,
                             alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: scale, y: -scale)
        layer.render(in: context)
        return context.makeImage()
    }
}
