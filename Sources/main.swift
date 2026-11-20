import AppKit

let args = CommandLine.arguments
if let i = args.firstIndex(of: "--snapshot"), args.count > i + 2 {
    MainActor.assumeIsolated { runSnapshot(outDir: args[i + 1], lang: args[i + 2]) }
    exit(0)
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)   // menu bar only, no Dock icon
let delegate = AppDelegate()
app.delegate = delegate
app.run()
