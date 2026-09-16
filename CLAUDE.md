# claude-usage-widget

## Vision & goals

A tiny, glanceable macOS menu bar widget for the **weekly** Claude plan limit: am I on pace for the week? Built for personal use, open sourced. Stay small: no settings UI, no dependencies, no Xcode project.

The **week** is the paced headline: menu bar icon, pace colors, all of `Pace.swift`'s pacing math. The **5-hour session** is a fuel gauge in the popup only — no pace, no menu bar presence, because you don't ration a session evenly, you just watch it drain.

## Stack & architecture

- Plain AppKit, compiled with `swiftc` by `build.sh` (tests → build `.app` → copy to `~/Applications` → login item → launch).
- `Pace.swift` — pure pacing logic plus `sessionLevel`, the only tested code. `main.swift` — status item, icon drawing, popup `WeekView`, fetch.
- Data: OAuth token from Keychain (`security find-generic-password -s "Claude Code-credentials"`), `GET https://api.anthropic.com/api/oauth/usage` with header `anthropic-beta: oauth-2025-04-20`; uses `seven_day` and `five_hour` (`utilization` + `resets_at` each).
- Pace is linear: target = elapsed / window length, where window start = `resets_at − 7d`.
- `paceLevel` −3…3, bands at 2 / 4 / 7 points off pace; off pace in *either* direction is bad (under = wasted allowance). Colors from −3 to +3: red, orange, yellow, green, mint, cyan, blue. Under pace is the alarm (red) because unused allowance is lost at reset — the user was explicit about this.
- "Left today" = end of today's 1/7 block − used, not distance to current pace.
- Tests: TDD for `Pace.swift` only; UI is verified by rendering views to PNG, not tested.

## Design decisions (settled with the user — don't relitigate)

- Menu bar: 7 day blocks, image only (no number, no text). Today's block is short with a dot under it (`!` look); other blocks full height. Blocks and dot take the pace color.
- Session strip: bottom 64pt of the popup, below a separator — `SESSION` + percent, a slim bar, and its reset time. Colors are its own 3-step scale (neutral / orange at 75 / red at 90), deliberately *not* `paceColor`, so the 7-color pace scale keeps meaning only "the week". Absent `five_hour` drops the strip and the popup returns to 196pt.
- Popup: "Bar hero" layout — header + status, tall 7-day bar with weekday letters and a pace line, used vs. pace, then Left today / Daily budget / Resets. Refresh and Quit are real `NSMenuItem`s below the custom view.

## Planned / In Progress

- [ ] Check green / mint / cyan are distinguishable at menu bar size in real use

## Gotchas & invariants

- Top-level code is only allowed in a file named `main.swift`; that's why tests live in `tests/main.swift`. SourceKit shows "cannot find X in scope" per file — ignore, `swiftc` compiles the files together.
- Status item: set `imagePosition = .imageOnly`, or an empty title still reserves padding next to the icon.
- The icon image must be the full 22pt menu bar height with blocks centered; a shorter image gets centered as a whole and the blocks sit visually high.
- The icon is not a template image (it needs color), so neutral parts use `NSColor.labelColor` to follow light/dark.
- `Int(0.58 * 100)` is 57 — always `.rounded()` before `Int`.
- `open` right after `pkill` in `build.sh` can fail with `-600`; relaunch with `open ~/Applications/ClaudeUsage.app`.
- The usage endpoint is undocumented; on 401 the token has expired and the user must open Claude Code once.
- Dynamic colors (`labelColor`, `secondaryLabelColor`) resolve against `NSAppearance.current`, *not* the view's `appearance`. Calling `view.draw()` yourself in a PNG render harness silently paints them white-on-white — wrap the call in `NSAppearance(named:)!.performAsCurrentDrawingAppearance { }` or you'll debug a layout bug that isn't there.
- Commits in this repo have **no** Claude co-author trailer (user's explicit choice).
