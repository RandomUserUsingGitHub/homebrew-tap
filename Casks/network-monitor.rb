cask "network-monitor" do
  version "2.1.0"
  sha256 "acc112725706ccfa8bde58f211d31c05a3bf67478a095e39b6687671236b915b"

  url "https://github.com/RandomUserUsingGitHub/NetworkMonitoring/releases/download/v2.1.0/NetworkMonitor-release.zip"
  name "Network Monitor"
  desc "Lightweight macOS network monitoring app with live ping graph and IP tracking"
  homepage "https://github.com/RandomUserUsingGitHub/NetworkMonitoring"

  depends_on macos: ">= :ventura"

  app "dist/NetworkMonitor.app"

  postflight do
    # Write default config if none exists
    cfg_dir = File.expand_path("~/.config/network-monitor")
    FileUtils.mkdir_p(cfg_dir)
    cfg_file = "#{cfg_dir}/settings.json"
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

    # Clean up old daemon-style LaunchAgent if present
    old_plist = File.expand_path("~/Library/LaunchAgents/com.user.network-monitor.plist")
    if File.exist?(old_plist)
      system_command "/bin/launchctl", args: ["unload", old_plist]
      File.delete(old_plist)
    end
  end

  uninstall delete: [
              File.expand_path("~/Library/LaunchAgents/com.armin.network-monitor.login.plist"),
              File.expand_path("~/Library/LaunchAgents/com.user.network-monitor.plist"),
            ]

  zap trash: [
    "~/.config/network-monitor",
    "~/.network_monitor.log",
    "/tmp/.netmon_*",
  ]
end
