import Cocoa
import ServiceManagement

// MARK: - Veri toplama

func cpuTicks() -> [UInt32] {
    var size = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
    var info = host_cpu_load_info()
    let r = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
            host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
        }
    }
    guard r == KERN_SUCCESS else { return [0, 0, 0, 0] }
    return [info.cpu_ticks.0, info.cpu_ticks.1, info.cpu_ticks.2, info.cpu_ticks.3] // user, system, idle, nice
}

func memoryUsage() -> (used: Double, total: Double) {
    let total = Double(ProcessInfo.processInfo.physicalMemory)
    var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
    var stats = vm_statistics64()
    let r = withUnsafeMutablePointer(to: &stats) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
            host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &size)
        }
    }
    guard r == KERN_SUCCESS else { return (0, total) }
    let page = Double(vm_kernel_page_size)
    let used = Double(stats.active_count + stats.wire_count + stats.compressor_page_count) * page
    return (used, total)
}

struct Proc { let name: String; let cpu: Double; let memMB: Double }

func topProcesses(sortBy flag: String) -> [Proc] {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/bin/ps")
    p.arguments = ["-Aco", "pcpu,rss,comm", flag]
    let pipe = Pipe()
    p.standardOutput = pipe
    p.standardError = Pipe()
    do { try p.run() } catch { return [] }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    let lines = (String(data: data, encoding: .utf8) ?? "").split(separator: "\n").dropFirst().prefix(5)
    return lines.compactMap { line in
        let parts = line.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
        guard parts.count == 3, let cpu = Double(parts[0]), let rss = Double(parts[1]) else { return nil }
        return Proc(name: String(parts[2]), cpu: cpu, memMB: rss / 1024)
    }
}

func gb(_ b: Double) -> String { String(format: "%.1f GB", b / 1_073_741_824) }

// MARK: - Uygulama

final class AppDelegate: NSObject, NSApplicationDelegate {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let menu = NSMenu()
    var prevTicks = cpuTicks()
    var timer: Timer?

    let cpuLine = NSMenuItem(), ramLine = NSMenuItem()
    var cpuProcItems: [NSMenuItem] = [], ramProcItems: [NSMenuItem] = []
    let loginItem = NSMenuItem(title: "Girişte Otomatik Başlat", action: #selector(toggleLogin), keyEquivalent: "")

    func applicationDidFinishLaunching(_ n: Notification) {
        func header(_ t: String) -> NSMenuItem {
            let h = NSMenuItem(title: t, action: nil, keyEquivalent: ""); h.isEnabled = false; return h
        }
        for i in [cpuLine, ramLine] { i.isEnabled = false; menu.addItem(i) }
        menu.addItem(.separator())
        menu.addItem(header("En çok CPU kullananlar"))
        for _ in 0..<5 { let i = NSMenuItem(); i.isEnabled = false; cpuProcItems.append(i); menu.addItem(i) }
        menu.addItem(.separator())
        menu.addItem(header("En çok RAM kullananlar"))
        for _ in 0..<5 { let i = NSMenuItem(); i.isEnabled = false; ramProcItems.append(i); menu.addItem(i) }
        menu.addItem(.separator())
        let openItem = NSMenuItem(title: "Etkinlik Monitörü'nü Aç", action: #selector(openActivityMonitor), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)
        loginItem.target = self
        menu.addItem(loginItem)
        menu.addItem(NSMenuItem(title: "Çık", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in self?.refresh() }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func refresh() {
        let t = cpuTicks()
        let d = zip(t, prevTicks).map { Double($0 &- $1) }
        prevTicks = t
        let total = d.reduce(0, +)
        let cpu = total > 0 ? (1 - d[2] / total) * 100 : 0
        let (used, tot) = memoryUsage()
        let ramPct = used / tot * 100

        item.button?.title = String(format: "CPU %.0f%%  RAM %.0f%%", cpu, ramPct)
        cpuLine.title = String(format: "CPU: %.1f%%", cpu)
        ramLine.title = String(format: "RAM: %@ / %@ (%.0f%%)", gb(used), gb(tot), ramPct)
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off

        DispatchQueue.global(qos: .utility).async {
            let c = topProcesses(sortBy: "-r"), m = topProcesses(sortBy: "-m")
            DispatchQueue.main.async {
                for (i, it) in self.cpuProcItems.enumerated() {
                    it.title = i < c.count ? String(format: "%@  —  %.1f%%", c[i].name, c[i].cpu) : ""
                    it.isHidden = i >= c.count
                }
                for (i, it) in self.ramProcItems.enumerated() {
                    it.title = i < m.count ? String(format: "%@  —  %.0f MB", m[i].name, m[i].memMB) : ""
                    it.isHidden = i >= m.count
                }
            }
        }
    }

    @objc func openActivityMonitor() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"))
    }

    @objc func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
            else { try SMAppService.mainApp.register() }
        } catch {
            let a = NSAlert(); a.messageText = "Otomatik başlatma ayarlanamadı"; a.informativeText = error.localizedDescription; a.runModal()
        }
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory) // Dock'ta görünmez, sadece menü çubuğu
let delegate = AppDelegate()
app.delegate = delegate
app.run()
