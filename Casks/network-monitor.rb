cask "network-monitor" do
  version "${VERSION}"
  sha256 "${SHA256}"

  url "https://github.com/RandomUserUsingGitHub/NetworkMonitoring/releases/download/v${VERSION}/NetworkMonitor-release.zip"
  name "Network Monitor"
  desc "Lightweight macOS network monitoring app with live ping graph and IP tracking"
  homepage "https://github.com/RandomUserUsingGitHub/NetworkMonitoring"

  depends_on macos: ">= :ventura"

  app "dist/NetworkMonitor.app"

  postflight do
    # Write default config if none exists
    cfg_dir = File.expand_path("~/.config/network-monitor")
    FileUtils.mkdir_p(cfg_dir)
    cfg_file = "\#{cfg_dir}/settings.json"
    unless File.exist?(cfg_file)
      File.write(cfg_file, <<~JSON)
        {
          "ping": { "host": "8.8.8.8", "interval_seconds": 2, "fail_threshold": 3,
                    "timeout_seconds": 2, "packet_size": 56, "history_size": 60 },
          "ip_check": { "interval_seconds": 10 },
          "notifications": { "sound": "Basso", "enabled": true, "censor_on_change": false },
          "ui": { "theme": "green", "ping_graph_width": 60 },
          "log": { "tail_lines": 7 }
        }
      JSON
    end

    # Install LaunchAgent
    plist_dir = File.expand_path("~/Library/LaunchAgents")
    FileUtils.mkdir_p(plist_dir)
    plist_path = "\#{plist_dir}/com.user.network-monitor.plist"
    File.write(plist_path, <<~PLIST)
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
        "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>             <string>com.user.network-monitor</string>
        <key>ProgramArguments</key>
        <array>
          <string>/Applications/NetworkMonitor.app/Contents/MacOS/NetworkMonitor</string>
          <string>--daemon</string>
        </array>
        <key>RunAtLoad</key>         <true/>
        <key>KeepAlive</key>         <true/>
        <key>StandardOutPath</key>   <string>/tmp/netmon_stdout.log</string>
        <key>StandardErrorPath</key> <string>/tmp/netmon_stderr.log</string>
      </dict>
      </plist>
    PLIST
    system_command "/bin/launchctl", args: ["load", plist_path]
  end

  uninstall launchctl: "com.user.network-monitor",
            delete:    [
              File.expand_path("~/Library/LaunchAgents/com.user.network-monitor.plist"),
              File.expand_path("~/.local/bin/netmon-toggle.sh")
            ]

  zap trash: [
    "~/.config/network-monitor",
    "~/.network_monitor.log",
    "/tmp/.netmon_*",
    "/tmp/netmon_stdout.log",
    "/tmp/netmon_stderr.log",
  ]
end
