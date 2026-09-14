import AppKit

struct UsageWindow: Decodable { let utilization: Double; let resets_at: String? }
struct Usage: Decodable { let seven_day: UsageWindow? }

func readToken() -> String? {
    let p = Process(), out = Pipe()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/security")
    p.arguments = ["find-generic-password", "-s", "Claude Code-credentials", "-w"]
    p.standardOutput = out
    p.standardError = FileHandle.nullDevice
    guard (try? p.run()) != nil else { return nil }
    p.waitUntilExit()
    let data = out.fileHandleForReading.readDataToEndOfFile()
    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    return (json?["claudeAiOauth"] as? [String: Any])?["accessToken"] as? String
}

let iso: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f
}()

func toWindow(_ u: UsageWindow?, length: TimeInterval) -> Window? {
    guard let u, let r = u.resets_at, let d = iso.date(from: r) ?? ISO8601DateFormatter().date(from: r) else { return nil }
    return Window(used: u.utilization, resetsAt: d, length: length)
}

func paceColor(_ level: Int) -> NSColor {
    [NSColor.systemBlue, .systemCyan, .systemMint, .systemGreen, .systemYellow, .systemOrange, .systemRed][min(max(level, -3), 3) + 3]
}

// One block per day of the weekly window; the dot sits under where usage should be by now.
// Not a template image, so the fill can carry pace color; labelColor keeps the rest legible in light/dark.
func weekBlocks(used: Double, target: Double, level: Int) -> NSImage {
    let color = paceColor(level)
    let sw: CGFloat = 4.5, gap: CGFloat = 1.5
    let img = NSImage(size: NSSize(width: 7 * sw + 6 * gap + 2, height: 22), flipped: false) { _ in
        // Today's block is shortened with a dot beneath, so it reads as "!" among full-height blocks.
        let today = min(Int(max(target, 0) * 7), 6)
        (0..<7).forEach { i in
            let x = 1 + CGFloat(i) * (sw + gap)
            let r = i == today ? NSRect(x: x, y: 6.5, width: sw, height: 10) : NSRect(x: x, y: 2, width: sw, height: 14.5)
            let block = NSBezierPath(roundedRect: r, xRadius: 1.2, yRadius: 1.2)
            NSColor.labelColor.withAlphaComponent(0.25).setFill()
            block.fill()
            NSGraphicsContext.saveGraphicsState()
            block.addClip()
            color.setFill()
            NSRect(x: r.minX, y: r.minY, width: sw, height: r.height * min(max(used * 7 - Double(i), 0), 1)).fill()
            NSGraphicsContext.restoreGraphicsState()
        }
        color.setFill()
        NSBezierPath(ovalIn: NSRect(x: 1 + CGFloat(today) * (sw + gap) + sw / 2 - 1.5, y: 2, width: 3, height: 3)).fill()
        return true
    }
    return img
}

let statusText = ["Way under pace", "Under pace", "Slightly under pace", "On track", "Slightly over pace", "Over pace", "Way over pace"]

final class WeekView: NSView {
    let w: Window, now: Date
    init(_ w: Window, now: Date) {
        self.w = w; self.now = now
        super.init(frame: NSRect(x: 0, y: 0, width: 280, height: 196))
    }
    required init?(coder: NSCoder) { nil }

    func text(_ s: String, _ size: CGFloat, _ c: NSColor, _ x: CGFloat, _ y: CGFloat, _ weight: NSFont.Weight = .regular, right: Bool = false) {
        let a = NSAttributedString(string: s, attributes: [.font: NSFont.monospacedDigitSystemFont(ofSize: size, weight: weight), .foregroundColor: c])
        a.draw(at: NSPoint(x: right ? x - a.size().width : x, y: y))
    }

    override func draw(_: NSRect) {
        let level = paceLevel(w, now: now), color = paceColor(level)
        let target = targetPercent(w, now: now), today = min(Int(target / 100 * 7), 6)
        let dim = NSColor.secondaryLabelColor, faint = NSColor.labelColor.withAlphaComponent(0.12)
        let L: CGFloat = 16, R = bounds.width - 16

        text("THIS WEEK", 9.5, dim, L, 170, .semibold)
        text(statusText[level + 3], 11, color, R, 169, .semibold, right: true)

        let gap: CGFloat = 3, sw = (R - L - 6 * gap) / 7, barY: CGFloat = 118
        let start = w.resetsAt.addingTimeInterval(-w.length)
        let letter = DateFormatter(); letter.dateFormat = "EEEEE"
        (0..<7).forEach { i in
            let r = NSRect(x: L + CGFloat(i) * (sw + gap), y: barY, width: sw, height: 40)
            let block = NSBezierPath(roundedRect: r, xRadius: 4, yRadius: 4)
            faint.setFill(); block.fill()
            NSGraphicsContext.saveGraphicsState(); block.addClip()
            color.setFill()
            NSRect(x: r.minX, y: r.minY, width: sw * min(max(w.used / 100 * 7 - Double(i), 0), 1), height: r.height).fill()
            NSGraphicsContext.restoreGraphicsState()
            let day = letter.string(from: start.addingTimeInterval(Double(i) * 86400))
            text(day, 9, i == today ? .labelColor : dim, r.midX - 3, barY - 15, i == today ? .bold : .regular)
        }
        let d = target / 100 * 7, px = L + CGFloat(floor(min(d, 6.999))) * (sw + gap) + sw * CGFloat(min(d, 6.999) - floor(min(d, 6.999)))
        NSColor.labelColor.setFill()
        NSBezierPath(roundedRect: NSRect(x: px - 1, y: barY - 3, width: 2, height: 46), xRadius: 1, yRadius: 1).fill()

        text("\(Int(w.used.rounded()))% used", 12, .labelColor, L, 78, .medium)
        text("pace \(Int(target.rounded()))%", 12, dim, R, 78, .medium, right: true)
        faint.setFill(); NSRect(x: L, y: 70, width: R - L, height: 1).fill()

        let reset = DateFormatter(); reset.dateFormat = "EEE HH:mm"
        [("Left today", "\(Int(leftToday(w, now: now).rounded()))%"),
         ("Daily budget", "\(Int(dailyBudget(w, now: now).rounded()))% / day"),
         ("Resets", "\(reset.string(from: w.resetsAt)) · \(formatRemaining(w.resetsAt.timeIntervalSince(now)))")]
            .enumerated().forEach { i, row in
                let y = 48 - CGFloat(i) * 18
                text(row.0, 11, dim, L, y)
                text(row.1, 11, .labelColor, R, y, .medium, right: true)
            }
    }
}

final class App:NSObject, NSApplicationDelegate {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var weekly: Window?, error: String?, updated = Date()

    func applicationDidFinishLaunching(_: Notification) {
        refresh()
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in self?.refresh() }
        // Pace target drifts every minute even when usage doesn't, so redraw between fetches.
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in self?.render() }
    }

    @objc func refresh() {
        guard let token = readToken() else { error = "No Claude Code login in Keychain"; return render() }
        var req = URLRequest(url: URL(string: "https://api.anthropic.com/api/oauth/usage")!)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        URLSession.shared.dataTask(with: req) { data, resp, _ in
            let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
            let usage = data.flatMap { try? JSONDecoder().decode(Usage.self, from: $0) }
            DispatchQueue.main.async {
                switch (status, usage) {
                case (200, let u?):
                    self.weekly = toWindow(u.seven_day, length: 7 * 86400)
                    self.error = nil
                    self.updated = Date()
                case (401, _): self.error = "Token expired — open Claude Code once"
                default: self.error = "Fetch failed (\(status))"
                }
                self.render()
            }
        }.resume()
    }

    func render() {
        let now = Date()
        let menu = NSMenu()
        func line(_ s: String) { menu.addItem(NSMenuItem(title: s, action: nil, keyEquivalent: "")) }
        if let w = weekly {
            let target = Int(targetPercent(w, now: now).rounded())
            item.button?.image = weekBlocks(used: w.used / 100, target: Double(target) / 100, level: paceLevel(w, now: now))
            item.button?.imagePosition = .imageOnly
            item.button?.title = ""
            let viewItem = NSMenuItem()
            viewItem.view = WeekView(w, now: now)
            menu.addItem(viewItem)
        } else {
            item.button?.image = nil
            item.button?.title = "⚠︎"
        }
        error.map { menu.addItem(.separator()); line("⚠︎ \($0)") }
        menu.addItem(.separator())
        let refreshItem = NSMenuItem(title: "Refresh  ·  updated \(Int(now.timeIntervalSince(updated) / 60))m ago", action: #selector(refresh), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
    }
}

let app = NSApplication.shared
let delegate = App()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
