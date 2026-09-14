#!/bin/zsh
# Builds ClaudeUsage.app, installs it to ~/Applications and registers it as a login item.
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
osascript -e 'tell application "System Events" to make login item at end with properties {path:(POSIX path of (path to home folder)) & "Applications/ClaudeUsage.app", hidden:true}' >/dev/null 2>&1 || true
pkill -x ClaudeUsage || true
open ~/Applications/$APP
