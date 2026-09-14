import Foundation

let now = Date(timeIntervalSince1970: 1_000_000)
let fiveH: TimeInterval = 5 * 3600
func check(_ ok: Bool, _ name: String) { print(ok ? "PASS" : "FAIL", name); if !ok { exit(1) } }

check(targetPercent(Window(used: 0, resetsAt: now.addingTimeInterval(fiveH / 2), length: fiveH), now: now) == 50, "halfway -> 50%")
check(targetPercent(Window(used: 0, resetsAt: now.addingTimeInterval(fiveH), length: fiveH), now: now) == 0, "window start -> 0%")
check(targetPercent(Window(used: 0, resetsAt: now.addingTimeInterval(-60), length: fiveH), now: now) == 100, "past reset clamps to 100%")
check(targetPercent(Window(used: 0, resetsAt: now.addingTimeInterval(fiveH * 2), length: fiveH), now: now) == 0, "future clamps to 0%")
check(paceDelta(Window(used: 70, resetsAt: now.addingTimeInterval(fiveH / 2), length: fiveH), now: now) == 20, "ahead of pace +20")
check(formatRemaining(3 * 86400 + 5 * 3600 + 59) == "3d 5h", "days format")
check(formatRemaining(2 * 3600 + 7 * 60) == "2h 7m", "hours format")
let halfway = now.addingTimeInterval(7 * 86400 / 2), week: TimeInterval = 7 * 86400
func lvl(_ used: Double) -> Int { paceLevel(Window(used: used, resetsAt: halfway, length: week), now: now) }
check(lvl(50) == 0 && lvl(52) == 0 && lvl(48) == 0, "within 2 -> 0")
check(lvl(53) == 1 && lvl(54) == 1, "3-4 over -> +1")
check(lvl(55) == 2 && lvl(57) == 2, "5-7 over -> +2")
check(lvl(58) == 3 && lvl(90) == 3, ">7 over -> +3")
check(lvl(47) == -1 && lvl(45) == -2 && lvl(43) == -2 && lvl(42) == -3, "under mirrors over")
check(lvl(52.4) == 0 && lvl(52.6) == 1, "gap rounds like the displayed numbers")
// halfway through the week: pace 50 → today is block 3 (42.9–57.1)
check(abs(leftToday(Window(used: 48, resetsAt: halfway, length: week), now: now) - (400.0 / 7 - 48)) < 0.001, "left today = end of today's block - used")
check(leftToday(Window(used: 70, resetsAt: halfway, length: week), now: now) == 0, "left today never negative")
check(abs(dailyBudget(Window(used: 48, resetsAt: halfway, length: week), now: now) - 52 / 3.5) < 0.001, "daily budget = remaining / days left")
check(dailyBudget(Window(used: 48, resetsAt: now, length: week), now: now) == 52, "last moment: budget is all that remains")
