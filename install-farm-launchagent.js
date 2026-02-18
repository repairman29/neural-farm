#!/usr/bin/env node
/**
 * Install the neural farm as a macOS LaunchAgent so it starts at login.
 * Runs: /bin/bash -lc 'cd <neural-farm-dir> && ./dev_farm.sh --bg'
 *
 * Run from neural-farm root: node install-farm-launchagent.js
 *
 * After install:
 *   Restart:  launchctl kickstart -k gui/$(id -u)/com.jarvis.neural-farm
 *   Unload:   launchctl unload ~/Library/LaunchAgents/com.jarvis.neural-farm.plist
 */

const fs = require('fs');
const path = require('path');
const os = require('os');
const { execSync } = require('child_process');

const farmRoot = path.resolve(__dirname);
const label = 'com.jarvis.neural-farm';
const plistDir = path.join(os.homedir(), 'Library', 'LaunchAgents');
const plistPath = path.join(plistDir, `${label}.plist`);
const logDir = path.join(os.homedir(), '.jarvis', 'logs');
const stdoutLog = path.join(logDir, 'neural-farm-stdout.log');
const stderrLog = path.join(logDir, 'neural-farm-stderr.log');

const plistContent = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${label}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>-lc</string>
    <string>cd ${farmRoot} &amp;&amp; ./dev_farm.sh --bg</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>StandardOutPath</key>
  <string>${stdoutLog}</string>
  <key>StandardErrorPath</key>
  <string>${stderrLog}</string>
</dict>
</plist>
`;

function main() {
  if (process.platform !== 'darwin') {
    console.error('This script is for macOS (LaunchAgent).');
    process.exit(1);
  }
  const devFarm = path.join(farmRoot, 'dev_farm.sh');
  if (!fs.existsSync(devFarm)) {
    console.error('Not found:', devFarm);
    process.exit(1);
  }
  if (!fs.existsSync(plistDir)) {
    fs.mkdirSync(plistDir, { recursive: true });
  }
  if (!fs.existsSync(logDir)) {
    fs.mkdirSync(logDir, { recursive: true });
  }
  fs.writeFileSync(plistPath, plistContent, 'utf8');
  console.log('Wrote', plistPath);
  try {
    execSync(`launchctl unload "${plistPath}"`, { stdio: 'ignore' });
  } catch (_) {}
  execSync(`launchctl load "${plistPath}"`, { stdio: 'inherit' });
  console.log('Loaded. Neural farm will start at login and has been started now.');
  console.log('Restart: launchctl kickstart -k gui/$(id -u)/com.jarvis.neural-farm');
  console.log('Logs:', stderrLog, stdoutLog);
}

main();
