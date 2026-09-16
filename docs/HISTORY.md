# History

## 2026-09-13 — initial build

- Built a menu bar widget reading weekly plan usage from the OAuth usage endpoint via the Claude Code Keychain token.
- Iterated the menu bar look: text → ring → bar → six-concept sheet → 7 day blocks. Added pace coloring (2 colors, then 7 levels with ±2 / ±4 / ±7 bands, off pace either way is bad), removed the number, `!` style for today's block, and fixed vertical alignment and gap.
- Designed the popup from three rendered layouts; shipped "Bar hero" with Left today / Daily budget / Resets.

## 2026-09-14 — open source

- Git repo, README, MIT license, CLAUDE.md; published to GitHub.
- Flipped the pace colors: under pace is now red, over pace is blue.

## 2026-09-16 — session limit added to the popup

- Brought back the 5-hour session limit, dropped at first build as "not useful" — but as a fuel gauge, not a pacing target. Popup only; the menu bar icon is unchanged.
- `sessionLevel` (75 / 90 thresholds, banding on the rounded integer like `paceLevel`) with its own neutral/orange/red scale, kept separate from `paceColor`.
- Popup grows 196 → 260pt when `five_hour` is present, and falls back to the old layout when it isn't. The week is drawn in its original coordinates via a 64pt translate rather than rewriting every y.

## 2026-09-17 — Durable auto-start
Replaced the System Events login item with a LaunchAgent (RunAtLoad + KeepAlive on crash) so the widget starts at login and launchd relaunches it if it dies.
