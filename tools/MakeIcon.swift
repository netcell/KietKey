// Vẽ icon KietKey: chữ K trên nền bo góc, gần như phẳng.
// Vẽ bằng CoreGraphics nên sắc nét ở mọi kích thước, không phụ thuộc file ảnh.
//
//   swift tools/MakeIcon.swift <thư mục .iconset>
//
// Chủ ý thiết kế:
//  - squircle thật (superellipse), không phải bo góc bằng cung tròn
//  - một màu nền, chỉ chuyển sắc rất nhẹ để không bị bệt
//  - chữ K vẽ bằng đường, không phụ thuộc font cài trên máy

import AppKit
import CoreGraphics
import Foundation

func rgb(_ r: Int, _ g: Int, _ b: Int, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: a)
}

/// Superellipse — dáng góc liên tục kiểu Apple, khác bo góc bằng cung tròn.
func squircle(in rect: CGRect, n: CGFloat = 5) -> CGPath {
    let path = CGMutablePath()
    let a = rect.width / 2, b = rect.height / 2
    let cx = rect.midX, cy = rect.midY
    let steps = 720
    for i in 0...steps {
        let t = CGFloat(i) / CGFloat(steps) * 2 * .pi
        let ct = cos(t), st = sin(t)
        let x = cx + a * pow(abs(ct), 2 / n) * (ct < 0 ? -1 : 1)
        let y = cy + b * pow(abs(st), 2 / n) * (st < 0 ? -1 : 1)
        if i == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
    }
    path.closeSubpath()
    return path
}

/// Chữ K lấy từ font hệ thống rồi căn giữa theo hộp bao thật của glyph.
/// Tự vẽ bằng đường thì các tay chéo dễ tự cắt nhau và thủng lỗ — đã thử.
func letterK(unit u: CGFloat, center: CGPoint) -> CGPath {
    let fontSize = 560 * u
    var descriptor = NSFont.systemFont(ofSize: fontSize, weight: .bold).fontDescriptor
    //SF Pro Rounded nếu máy có, hợp với dáng squircle hơn
    if let rounded = descriptor.withDesign(.rounded) { descriptor = rounded }
    let font = CTFontCreateWithFontDescriptor(descriptor as CTFontDescriptor, fontSize, nil)

    var glyph = CGGlyph(0)
    var ch: UniChar = 0x004B // "K"
    guard CTFontGetGlyphsForCharacters(font, &ch, &glyph, 1),
          let raw = CTFontCreatePathForGlyph(font, glyph, nil)
    else { fatalError("không lấy được glyph K") }

    let box = raw.boundingBoxOfPath
    var move = CGAffineTransform(translationX: center.x - box.midX, y: center.y - box.midY)
    return raw.copy(using: &move) ?? raw
}

func drawIcon(size S: CGFloat, into ctx: CGContext) {
    let u = S / 1024.0
    ctx.setShouldAntialias(true)
    ctx.interpolationQuality = .high

    let pad: CGFloat = 88 * u
    let tile = CGRect(x: pad, y: pad, width: S - pad * 2, height: S - pad * 2)
    let tilePath = squircle(in: tile)

    // bóng đổ của chính icon
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -12 * u), blur: 30 * u, color: rgb(10, 24, 60, 0.34))
    ctx.addPath(tilePath)
    ctx.setFillColor(rgb(37, 99, 235))
    ctx.fillPath()
    ctx.restoreGState()

    // nền: gần như phẳng, chỉ sáng hơn chút ở trên cho đỡ bệt
    ctx.saveGState()
    ctx.addPath(tilePath)
    ctx.clip()
    let bg = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                        colors: [rgb(56, 118, 246), rgb(30, 86, 214)] as CFArray,
                        locations: [0, 1])!
    ctx.drawLinearGradient(bg,
                           start: CGPoint(x: tile.midX, y: tile.maxY),
                           end: CGPoint(x: tile.midX, y: tile.minY),
                           options: [])
    ctx.restoreGState()

    // viền sáng mảnh ở mép, kiểu vật liệu của macOS
    ctx.saveGState()
    ctx.addPath(tilePath)
    ctx.clip()
    ctx.addPath(tilePath)
    ctx.setStrokeColor(rgb(255, 255, 255, 0.3))
    ctx.setLineWidth(max(1, 6 * u))
    ctx.strokePath()
    ctx.restoreGState()

    // chữ K
    let k = letterK(unit: u, center: CGPoint(x: S / 2, y: S / 2))
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -5 * u), blur: 14 * u, color: rgb(10, 32, 90, 0.26))
    ctx.addPath(k)
    ctx.setFillColor(rgb(255, 255, 255))
    ctx.fillPath()
    ctx.restoreGState()
}

func writePNG(size: Int, to url: URL) {
    guard let ctx = CGContext(data: nil, width: size, height: size,
                              bitsPerComponent: 8, bytesPerRow: 0,
                              space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { fatalError("không tạo được context \(size)") }
    drawIcon(size: CGFloat(size), into: ctx)
    guard let image = ctx.makeImage(),
          let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
    else { fatalError("không render được \(size)") }
    try! data.write(to: url)
}

let outDir = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

let iconset: [(Int, String)] = [
    (16, "icon_16x16.png"), (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"), (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"), (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"), (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"), (1024, "icon_512x512@2x.png"),
]
for (size, name) in iconset { writePNG(size: size, to: outDir.appendingPathComponent(name)) }
writePNG(size: 1024, to: outDir.appendingPathComponent("../icon-1024.png"))
print("xong: \(iconset.count) ảnh trong \(outDir.path)")
