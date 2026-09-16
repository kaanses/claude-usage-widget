import Foundation

struct Window {
    let used: Double      // percent 0...100
    let resetsAt: Date
    let length: TimeInterval
}

// Linear pacing: by now you "should" have used the fraction of the window that has elapsed.
func targetPercent(_ w: Window, now: Date) -> Double {
    let elapsed = w.length - w.resetsAt.timeIntervalSince(now)
    return min(max(elapsed / w.length, 0), 1) * 100
}

func paceDelta(_ w: Window, now: Date) -> Double { w.used - targetPercent(w, now: now) }

func formatRemaining(_ s: TimeInterval) -> String {
    let m = max(Int(s) / 60, 0)
    return m >= 1440 ? "\(m / 1440)d \(m % 1440 / 60)h" : "\(m / 60)h \(m % 60)m"
}

// Off pace in either direction is bad: under means wasted allowance, over means running out early.
// -3...3, sign = direction; bands at 2 / 4 / 7 points from pace.
func paceLevel(_ w: Window, now: Date) -> Int {
    let d = paceDelta(w, now: now).rounded()
    let steps = abs(d) <= 2 ? 0 : abs(d) <= 4 ? 1 : abs(d) <= 7 ? 2 : 3
    return d < 0 ? -steps : steps
}

// Today = the 1/7 slice of the window pace is currently in; this is what's left before passing its end.
func leftToday(_ w: Window, now: Date) -> Double {
    let dayEnd = (floor(targetPercent(w, now: now) / 100 * 7) + 1) / 7 * 100
    return max(min(dayEnd, 100) - w.used, 0)
}

func dailyBudget(_ w: Window, now: Date) -> Double {
    (100 - w.used) / max(w.resetsAt.timeIntervalSince(now) / 86400, 1)
}

// The session window is not paced — you don't ration five hours evenly, you just watch it drain.
// 0 fine, 1 low, 2 nearly spent; bands on the displayed integer.
func sessionLevel(_ used: Double) -> Int {
    let u = used.rounded()
    return u >= 90 ? 2 : u >= 75 ? 1 : 0
}
