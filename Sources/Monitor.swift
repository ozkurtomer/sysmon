import Foundation
import IOKit.ps

// MARK: - Low-level readings

private func cpuTicks() -> [UInt32] {
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

private func memoryUsedBytes() -> Double {
    var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
    var stats = vm_statistics64()
    let r = withUnsafeMutablePointer(to: &stats) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
            host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &size)
        }
    }
    guard r == KERN_SUCCESS else { return 0 }
    let page = Double(vm_kernel_page_size)
    return Double(stats.active_count + stats.wire_count + stats.compressor_page_count) * page
}

private func readBattery() -> (pct: Int, charging: Bool)? {
    let info = IOPSCopyPowerSourcesInfo().takeRetainedValue()
    let list = IOPSCopyPowerSourcesList(info).takeRetainedValue() as [CFTypeRef]
    for ps in list {
        guard let d = IOPSGetPowerSourceDescription(info, ps)?.takeUnretainedValue() as? [String: Any],
              let cap = d[kIOPSCurrentCapacityKey] as? Int,
              let max = d[kIOPSMaxCapacityKey] as? Int, max > 0 else { continue }
        let charging = (d[kIOPSIsChargingKey] as? Bool) ?? false
        return (cap * 100 / max, charging)
    }
    return nil
}

private func readDisk() -> (used: Double, total: Double) {
    let keys: Set<URLResourceKey> = [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]
    guard let v = try? URL(fileURLWithPath: "/").resourceValues(forKeys: keys),
          let total = v.volumeTotalCapacity,
          let avail = v.volumeAvailableCapacityForImportantUsage else { return (0, 1) }
    return (Double(total) - Double(avail), Double(total))
}

private func bootDate() -> Date {
    var tv = timeval()
    var size = MemoryLayout<timeval>.stride
    var mib = [CTL_KERN, KERN_BOOTTIME]
    if sysctl(&mib, 2, &tv, &size, nil, 0) == 0 { return Date(timeIntervalSince1970: Double(tv.tv_sec)) }
    return Date(timeIntervalSinceNow: -ProcessInfo.processInfo.systemUptime)
}

private func readTopProcesses(sort flag: String) -> [Proc] {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/bin/ps")
    p.arguments = ["-Aco", "pid,pcpu,rss,comm", flag]
    let pipe = Pipe()
    p.standardOutput = pipe
    p.standardError = Pipe()
    do { try p.run() } catch { return [] }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    let lines = (String(data: data, encoding: .utf8) ?? "").split(separator: "\n").dropFirst().prefix(6)
    return lines.compactMap { line in
        let f = line.split(separator: " ", maxSplits: 3, omittingEmptySubsequences: true)
        guard f.count == 4, let pid = Int32(f[0]), let cpu = Double(f[1]), let rss = Double(f[2]) else { return nil }
        return Proc(id: pid, name: String(f[3]), cpu: cpu, memMB: rss / 1024)
    }
}

// MARK: - Model

struct Proc: Identifiable {
    let id: Int32
    let name: String
    let cpu: Double
    let memMB: Double
}

enum Mood { case calm, busy, boss, low }

final class Monitor: ObservableObject {
    @Published var cpu = 0.0
    @Published var ramUsed = 0.0
    @Published var ramTotal = Double(ProcessInfo.processInfo.physicalMemory)
    @Published var diskUsed = 0.0
    @Published var diskTotal = 1.0
    @Published var batteryPct: Int? = nil
    @Published var charging = false
    @Published var uptime: TimeInterval = 0
    @Published var topCPU: [Proc] = []
    @Published var topMem: [Proc] = []
    @Published var tab = 0              // 0 = CPU enemies, 1 = RAM enemies
    var isDemo = false

    var popoverVisible = false
    var onUpdate: (() -> Void)?

    private var prevTicks = cpuTicks()
    private let boot = bootDate()
    private var timer: Timer?
    private var count = 0

    init() {}

    var ramFraction: Double { ramTotal > 0 ? ramUsed / ramTotal : 0 }
    var level: Int { Int(uptime / 86_400) + 1 }
    var xp: Double { let d = uptime / 86_400; return d - d.rounded(.down) }

    var mood: Mood {
        if cpu >= 80 { return .boss }
        if ramFraction >= 0.92 { return .low }
        if cpu >= 45 { return .busy }
        return .calm
    }

    var uptimeText: String {
        let s = Int(uptime), d = s / 86_400, h = (s % 86_400) / 3_600, m = (s % 3_600) / 60
        return d > 0 ? "\(d)\(t("unit_d")) \(h)\(t("unit_h"))" : "\(h)\(t("unit_h")) \(m)\(t("unit_m"))"
    }

    func start() {
        tick()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func refreshProcesses() {
        DispatchQueue.global(qos: .utility).async {
            let c = readTopProcesses(sort: "-r"), m = readTopProcesses(sort: "-m")
            DispatchQueue.main.async { self.topCPU = c; self.topMem = m }
        }
    }

    private func tick() {
        let now = cpuTicks()
        let d = zip(now, prevTicks).map { Double($0 &- $1) }
        prevTicks = now
        let total = d.reduce(0, +)
        cpu = total > 0 ? (1 - d[2] / total) * 100 : 0
        ramUsed = memoryUsedBytes()
        uptime = Date().timeIntervalSince(boot)
        if let b = readBattery() { batteryPct = b.pct; charging = b.charging } else { batteryPct = nil }
        if count % 15 == 0 { let disk = readDisk(); diskUsed = disk.used; diskTotal = disk.total }
        count += 1
        if popoverVisible { refreshProcesses() }
        onUpdate?()
    }

    // MARK: Demo data (used to render README images from the real view)

    init(demoFrame i: Int, of n: Int) {
        isDemo = true
        let phase = Double(i) / Double(n) * 2 * .pi
        let fight = i >= n * 5 / 12 && i < n * 8 / 12
        cpu = fight ? 84 + 4 * sin(phase * 6) : 22 + 8 * sin(phase) + 3 * sin(3 * phase)
        ramTotal = 16 * 1_073_741_824
        ramUsed = ramTotal * (0.72 + 0.01 * sin(phase))
        diskTotal = 494 * 1_000_000_000; diskUsed = 412 * 1_000_000_000
        batteryPct = 78; charging = false
        uptime = 3 * 86_400 + 4 * 3_600 + 12 * 60 + Double(i) * 2
        tab = i >= n * 3 / 4 ? 1 : 0
        let j = 1 + 0.08 * sin(phase * 2)
        topCPU = fight
            ? [Proc(id: 90001, name: "Xcode", cpu: 78 * j, memMB: 897),
               Proc(id: 90002, name: "WindowServer", cpu: 9.4, memMB: 403),
               Proc(id: 90003, name: "Google Chrome Helper", cpu: 6.1, memMB: 993),
               Proc(id: 90004, name: "Spotlight", cpu: 2.3, memMB: 120)]
            : [Proc(id: 90002, name: "WindowServer", cpu: 14 * j, memMB: 403),
               Proc(id: 90003, name: "Google Chrome Helper", cpu: 9.2 * j, memMB: 993),
               Proc(id: 90001, name: "Xcode", cpu: 5.1, memMB: 897),
               Proc(id: 90005, name: "Finder", cpu: 1.8, memMB: 124)]
        topMem = [Proc(id: 90003, name: "Google Chrome Helper", cpu: 9, memMB: 2140),
                  Proc(id: 90001, name: "Xcode", cpu: 5, memMB: 1480),
                  Proc(id: 90006, name: "Slack", cpu: 1.2, memMB: 823),
                  Proc(id: 90007, name: "Figma", cpu: 0.9, memMB: 640)]
    }
}
