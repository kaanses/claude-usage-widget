#!/bin/zsh
# Builds ClaudeUsage.app, installs it to ~/Applications and registers it as a LaunchAgent.
set -e
cd "$(dirname "$0")"
swiftc -O tests/main.swift Pace.swift -o /tmp/pace-tests && /tmp/pace-tests
APP=ClaudeUsage.app
rm -rf $APP && mkdir -p $APP/Contents/MacOS
swiftc -O main.swift Pace.swift -o $APP/Contents/MacOS/ClaudeUsage
cat > $APP/Contents/Info.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>ClaudeUsage</string>
<key>CFBundleIdentifier</key><string>local.claude-usage</string>
<key>CFBundleName</key><string>ClaudeUsage</string>
<key>LSUIElement</key><true/>
</dict></plist>
EOF
mkdir -p ~/Applications && rm -rf ~/Applications/$APP && cp -R $APP ~/Applications/
# LaunchAgent instead of a login item: starts at login and launchd restarts it if it crashes.
# KeepAlive only on unsuccessful exit, so the Quit menu item still quits (until next login).
osascript -e 'tell application "System Events" to delete login item "ClaudeUsage"' >/dev/null 2>&1 || true
AGENT=~/Library/LaunchAgents/local.claude-usage.plist
mkdir -p ~/Library/LaunchAgents
cat > $AGENT <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict>
<key>Label</key><string>local.claude-usage</string>
<key>Program</key><string>$HOME/Applications/$APP/Contents/MacOS/ClaudeUsage</string>
<key>RunAtLoad</key><true/>
<key>KeepAlive</key><dict><key>SuccessfulExit</key><false/></dict>
<key>ProcessType</key><string>Interactive</string>
</dict></plist>
EOF
launchctl bootout gui/$(id -u)/local.claude-usage 2>/dev/null || true
pkill -x ClaudeUsage || true
launchctl bootstrap gui/$(id -u) $AGENT
