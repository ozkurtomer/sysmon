import SwiftUI
import AppKit
import ServiceManagement

let repoURL = "https://github.com/ozkurtomer/sysmon"

/// NSMenuItem that runs a closure.
final class ActionItem: NSMenuItem {
    private var handler: (() -> Void)?

    convenience init(_ title: String, checked: Bool = false, handler: @escaping () -> Void) {
        self.init(title: title, action: #selector(fire), keyEquivalent: "")
        self.target = self
        self.handler = handler
        self.state = checked ? .on : .off
    }

    @objc private func fire() { handler?() }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    let monitor = Monitor()
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let popover = NSPopover()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let host = NSHostingController(rootView: PopoverView(m: monitor, onSettings: { [weak self] in self?.showSettings() }))
        host.sizingOptions = .preferredContentSize
        popover.contentViewController = host
        popover.behavior = .transient          // follows the system's light / dark appearance automatically
        popover.delegate = self

        if let b = item.button {
            b.target = self
            b.action = #selector(togglePopover)
        }
        monitor.onUpdate = { [weak self] in self?.updateBar() }
        monitor.start()
    }

    // MARK: Menu bar title

    private func updateBar() {
        let critical = monitor.cpu >= 80 || monitor.ramFraction >= 0.92
        let num = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        let tag = NSFont.systemFont(ofSize: 9, weight: .bold)
        let s = NSMutableAttributedString()
        func add(_ text: String, _ font: NSFont) {
            s.append(NSAttributedString(string: text, attributes: [.font: font]))
        }
        add("\(t("cpu")) ", tag); add(String(format: "%.0f%%", monitor.cpu), num)
        add("   \(t("ram")) ", tag); add(String(format: "%.0f%%", monitor.ramFraction * 100), num)
        if critical {
            s.addAttribute(.foregroundColor, value: NSColor.systemRed, range: NSRange(location: 0, length: s.length))
        }
        item.button?.attributedTitle = s
        item.button?.toolTip = "SysMon"
    }

    // MARK: Popover

    @objc private func togglePopover() {
        guard let b = item.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            monitor.popoverVisible = true
            monitor.refreshProcesses()
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: b.bounds, of: b, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    func popoverDidClose(_ notification: Notification) { monitor.popoverVisible = false }

    // MARK: Settings menu

    private func open(_ url: String) { if let u = URL(string: url) { NSWorkspace.shared.open(u) } }

    private func setLanguage(_ l: Lang) {
        Loc.override = l
        UserDefaults.standard.set(l.rawValue, forKey: "lang")
        monitor.objectWillChange.send()
        updateBar()
    }

    private func showSettings() {
        let menu = NSMenu()
        menu.addItem(ActionItem(t("star")) { [weak self] in self?.open(repoURL) })
        menu.addItem(ActionItem(t("issue")) { [weak self] in self?.open(repoURL + "/issues/new/choose") })
        menu.addItem(.separator())

        let login = SMAppService.mainApp.status == .enabled
        menu.addItem(ActionItem(t("login"), checked: login) {
            do {
                if login { try SMAppService.mainApp.unregister() } else { try SMAppService.mainApp.register() }
            } catch {
                let a = NSAlert(); a.messageText = error.localizedDescription; a.runModal()
            }
        })

        let langItem = NSMenuItem(title: t("language"), action: nil, keyEquivalent: "")
        let sub = NSMenu()
        sub.addItem(ActionItem(t("system"), checked: Loc.override == .system) { [weak self] in self?.setLanguage(.system) })
        sub.addItem(ActionItem("English", checked: Loc.override == .en) { [weak self] in self?.setLanguage(.en) })
        sub.addItem(ActionItem("Türkçe", checked: Loc.override == .tr) { [weak self] in self?.setLanguage(.tr) })
        langItem.submenu = sub
        menu.addItem(langItem)

        menu.addItem(ActionItem(t("activity")) {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"))
        })
        menu.addItem(.separator())
        menu.addItem(ActionItem(t("quit_app")) { NSApp.terminate(nil) })

        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }
}
