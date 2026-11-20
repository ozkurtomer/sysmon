import SwiftUI
import AppKit

/// Developer tool: renders the real popover view to PNG frames (light + dark) for the README animation.
/// Usage: SysMon --snapshot <outDir> <en|tr>
@MainActor
func runSnapshot(outDir: String, lang: String, frames: Int = 32) {
    _ = NSApplication.shared
    Loc.override = lang == "tr" ? .tr : .en
    try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

    for (name, scheme) in [("dark", ColorScheme.dark), ("light", ColorScheme.light)] {
        for i in 0..<frames {
            let model = Monitor(demoFrame: i, of: frames)
            let renderer = ImageRenderer(content: PopoverView(m: model, solid: true).environment(\.colorScheme, scheme))
            renderer.scale = 2
            guard let tiff = renderer.nsImage?.tiffRepresentation,
                  let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) else {
                print("render failed at \(name) \(i)"); continue
            }
            try? png.write(to: URL(fileURLWithPath: "\(outDir)/\(name)-\(String(format: "%02d", i)).png"))
        }
    }
    print("wrote \(frames * 2) frames to \(outDir)")
}
