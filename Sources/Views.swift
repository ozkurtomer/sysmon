import SwiftUI
import AppKit

// MARK: - Helpers

/// macOS keeps RAM and disk fairly full by design, so only warn when it's genuinely tight.
func levelColor(_ v: Double) -> Color { v < 0.8 ? .mint : (v < 0.92 ? .orange : .red) }

private func gb(_ bytes: Double, decimals: Int = 1) -> String {
    String(format: "%.\(decimals)f", bytes / 1_000_000_000)
}

private func gib(_ bytes: Double) -> String {
    String(format: "%.1f", bytes / 1_073_741_824)
}

func runningApp(for p: Proc) -> NSRunningApplication? {
    guard let a = NSRunningApplication(processIdentifier: p.id),
          a.activationPolicy == .regular,
          a.processIdentifier != getpid(),
          a.bundleIdentifier != "com.apple.finder" else { return nil }
    return a
}

func confirmAndQuit(_ p: Proc) {
    guard let app = runningApp(for: p) else { return }
    let alert = NSAlert()
    alert.messageText = String(format: t("quit_title"), app.localizedName ?? p.name)
    alert.informativeText = t("quit_info")
    alert.addButton(withTitle: t("quit_btn"))
    alert.addButton(withTitle: t("cancel"))
    NSApp.activate(ignoringOtherApps: true)
    if alert.runModal() == .alertFirstButtonReturn { app.terminate() }
}

// MARK: - HUD building blocks

/// Segmented, game-style gauge.
struct SegBar: View {
    let value: Double
    let color: Color
    var segments = 20
    var height: CGFloat = 8

    var body: some View {
        let filled = max(0, min(1, value)) * Double(segments)
        HStack(spacing: 2) {
            ForEach(0..<segments, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill((Double(i) + 0.5 < filled || (i == 0 && value > 0.01)) ? color : Color.primary.opacity(0.10))
                    .frame(height: height)
            }
        }
    }
}

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    let frac: Double
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 14)
                Text(label)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                Spacer()
                Text(value)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }
            SegBar(value: frac, color: color)
        }
    }
}

struct Tabs: View {
    @Binding var selection: Int
    let labels: [String]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<labels.count, id: \.self) { i in
                Text(labels[i])
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(selection == i ? Color.mint.opacity(0.25) : Color.clear))
                    .foregroundColor(selection == i ? .mint : .secondary)
                    .contentShape(Capsule())
                    .onTapGesture { selection = i }
            }
        }
        .padding(2)
        .background(Capsule().fill(Color.primary.opacity(0.07)))
    }
}

// MARK: - Main popover

struct PopoverView: View {
    @ObservedObject var m: Monitor
    var solid = false                       // opaque background (used when rendering README images)
    var onSettings: () -> Void = {}
    @Environment(\.colorScheme) private var scheme

    private let card = Color.primary.opacity(0.05)

    var body: some View {
        VStack(spacing: 12) {
            header
            banner
            VStack(spacing: 11) { stats }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(card))
            enemies
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(card))
        }
        .padding(14)
        .frame(width: 332)
        .background(solid ? (scheme == .dark ? Color(white: 0.13) : Color(white: 0.97)) : Color.clear)
    }

    // Player card
    private var header: some View {
        VStack(spacing: 9) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(LinearGradient(colors: [.mint, .teal], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("SysMon").font(.system(size: 14, weight: .bold, design: .rounded))
                        Text("Lv. \(m.level)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.mint)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(Color.mint.opacity(0.18)))
                    }
                    Text("\(t("playtime")) · \(m.uptimeText)")
                        .font(.system(size: 11)).foregroundColor(.secondary)
                }
                Spacer()
                Button(action: onSettings) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .frame(width: 26, height: 26)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            // XP bar: progress through the current day of uptime
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.08))
                    Capsule().fill(LinearGradient(colors: [.mint, .teal], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(4, g.size.width * m.xp))
                }
            }
            .frame(height: 4)
        }
    }

    // Status banner
    private var banner: some View {
        let (icon, key, color): (String, String, Color) = {
            switch m.mood {
            case .calm: return ("checkmark.shield.fill", "mood_calm", .mint)
            case .busy: return ("exclamationmark.triangle.fill", "mood_busy", .orange)
            case .boss: return ("flame.fill", "mood_boss", .red)
            case .low:  return ("cross.case.fill", "mood_low", .orange)
            }
        }()
        return HStack(spacing: 8) {
            Image(systemName: icon).foregroundColor(color)
            Text(t(key)).font(.system(size: 12, weight: .bold, design: .rounded)).foregroundColor(color)
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(color.opacity(0.14)))
        .animation(.easeOut(duration: 0.3), value: m.mood == .calm)
    }

    // Gauges
    @ViewBuilder private var stats: some View {
        StatRow(icon: "bolt.fill", label: t("cpu"),
                value: String(format: "%.0f%%", m.cpu),
                frac: m.cpu / 100, color: levelColor(m.cpu / 100))
        StatRow(icon: "memorychip.fill", label: t("ram"),
                value: "\(gib(m.ramUsed)) / \(gib(m.ramTotal)) GB",
                frac: m.ramFraction, color: levelColor(m.ramFraction))
        StatRow(icon: "internaldrive.fill", label: t("disk"),
                value: "\(gb(m.diskUsed, decimals: 0)) / \(gb(m.diskTotal, decimals: 0)) GB",
                frac: m.diskTotal > 0 ? m.diskUsed / m.diskTotal : 0,
                color: levelColor(m.diskTotal > 0 ? m.diskUsed / m.diskTotal : 0))
        if let pct = m.batteryPct {
            StatRow(icon: m.charging ? "battery.100.bolt" : "battery.75",
                    label: t("battery"),
                    value: m.charging ? "\(pct)% · \(t("charging"))" : "\(pct)%",
                    frac: Double(pct) / 100,
                    color: m.charging ? .mint : levelColor(1 - Double(pct) / 100))
        }
    }

    // Top processes as "enemies"
    private var enemies: some View {
        let list = m.tab == 0 ? m.topCPU : m.topMem
        return VStack(spacing: 8) {
            HStack {
                Text(t("enemies"))
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundColor(.secondary)
                Spacer()
                Tabs(selection: $m.tab, labels: [t("cpu"), t("ram")])
            }
            ForEach(0..<4, id: \.self) { i in
                if i < list.count { row(list[i], rank: i) } else { Color.clear.frame(height: 22) }
            }
        }
    }

    private func row(_ p: Proc, rank: Int) -> some View {
        let threat = m.tab == 0 ? min(1, p.cpu / 100) : min(1, (p.memMB * 1_048_576 / max(1, m.ramTotal)) / 0.25)
        let isBoss = rank == 0 && (m.tab == 0 ? p.cpu >= 30 : threat >= 0.6)
        let value = m.tab == 0 ? String(format: "%.1f%%", p.cpu) : String(format: "%.0f MB", p.memMB)
        let canQuit = m.isDemo ? (p.name != "WindowServer" && p.name != "Finder") : runningApp(for: p) != nil
        return HStack(spacing: 8) {
            Text("\(rank + 1)")
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundColor(isBoss ? .red : .secondary)
                .frame(width: 16, height: 16)
                .background(Circle().fill((isBoss ? Color.red : Color.primary).opacity(0.12)))
            Text(p.name)
                .font(.system(size: 12))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            if isBoss {
                Text(t("boss"))
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(Capsule().fill(Color.red))
            }
            SegBar(value: threat, color: isBoss ? .red : levelColor(threat), segments: 8, height: 6)
                .frame(width: 52)
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .frame(width: 58, alignment: .trailing)
            if canQuit {
                Button { confirmAndQuit(p) } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help(t("quit_tip"))
            } else {
                Color.clear.frame(width: 13, height: 13)
            }
        }
        .frame(height: 22)
    }
}
