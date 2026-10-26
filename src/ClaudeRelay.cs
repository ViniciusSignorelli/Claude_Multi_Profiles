using System;
using System.Diagnostics;
using System.IO;

internal static class ClaudeRelay
{
    private static readonly TimeSpan WorkWindow = TimeSpan.FromMinutes(15);

    private static int Main(string[] args)
    {
        var baseDir = AppDomain.CurrentDomain.BaseDirectory;
        var flagFile = Path.Combine(baseDir, "work-login.flag");
        var logFile = Path.Combine(baseDir, "relay.log");
        var workProfileFile = Path.Combine(baseDir, "work-profile.txt");
        var launcher = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            @"Microsoft\WindowsApps\claude-desktop.exe");

        var workProfile = File.Exists(workProfileFile)
            ? File.ReadAllText(workProfileFile).Trim()
            : Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "Claude-Work");

        var dryRun = args.Length > 0 && args[0] == "--dry-run";
        var url = args.Length > 0 && !dryRun ? args[args.Length - 1] : "";

        var useWork = File.Exists(flagFile) && DateTime.Now - File.GetLastWriteTime(flagFile) < WorkWindow;
        File.AppendAllText(logFile, string.Format("{0:s} -> {1}{2}", DateTime.Now, useWork ? "work" : "personal", Environment.NewLine));

        if (dryRun) return 0;

        var arguments = "";
        if (useWork) arguments += "\"--user-data-dir=" + workProfile + "\" ";
        if (url.Length > 0) arguments += "\"" + url + "\"";

        Process.Start(new ProcessStartInfo(launcher, arguments.Trim()) { UseShellExecute = false });
        return 0;
    }
}
