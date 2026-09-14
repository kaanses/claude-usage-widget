# claude-usage-widget

A tiny macOS menu bar widget that shows how much of your **weekly Claude plan limit** you've used, and whether you're on pace for the week.

No dependencies, no Xcode project — two Swift files compiled with `swiftc`.

## What you see

**Menu bar:** seven blocks, one per day of your weekly limit window. The fill is how much you've used; today's block is shortened with a dot underneath, so it reads like `!`. The color tells you where you are against pace:

| Color | Meaning |
|---|---|
| 🔵 blue | way under pace (more than 7 points) — use a lot more |
| 🩵 cyan | under pace (5–7) |
| 🌿 mint | slightly under (3–4) |
| 🟢 green | on track (within 2) |
| 🟡 yellow | slightly over (3–4) |
| 🟠 orange | over pace (5–7) |
| 🔴 red | way over (more than 7) — slow down |

**Click it:** a larger day bar with a line at exactly where you should be, plus:

- **Used / pace** — your usage vs. where you'd be if you spread the week evenly
- **Left today** — how much you can use before passing the end of today's 1/7 slice
- **Daily budget** — what's left divided by the days remaining
- **Resets** — when the weekly window resets

"Pace" is linear: with 3 of 7 days elapsed, you should be at ~43%.

## Requirements

- macOS 12 or later, with the Swift toolchain (`xcode-select --install`)
- [Claude Code](https://claude.com/claude-code) installed and logged in with a Pro or Max plan

## Install

```sh
git clone https://github.com/kaanses/claude-usage-widget.git
cd claude-usage-widget
./build.sh
```

`build.sh` runs the tests, builds `ClaudeUsage.app`, copies it to `~/Applications`, adds it as a login item, and launches it. Re-run it after any change. To remove it: quit from the menu, delete `~/Applications/ClaudeUsage.app`, and remove it from System Settings → General → Login Items.

The first launch may ask for Keychain access — choose **Always Allow**.

## How it works

- It reads the OAuth token Claude Code already stores in your macOS Keychain (`Claude Code-credentials`). There is no separate login.
- Every 5 minutes it calls `https://api.anthropic.com/api/oauth/usage` — the same data Claude Code's `/usage` shows. The token is sent only to Anthropic and is never written to disk.
- If the token has expired, open Claude Code once to refresh it.

**Caveat:** that usage endpoint is undocumented and may change without notice. If it does, the menu bar shows `⚠︎`.

## Development

```sh
swiftc tests/main.swift Pace.swift -o /tmp/pace-tests && /tmp/pace-tests
```

- `Pace.swift` — pacing math (target %, pace level, left today, daily budget). Tested.
- `main.swift` — menu bar item, icon drawing, popup view, API fetch.
- `tests/main.swift` — plain assertion tests, no framework needed.

## Disclaimer

Unofficial and not affiliated with or endorsed by Anthropic. "Claude" is a trademark of Anthropic.

## License

[MIT](LICENSE)
