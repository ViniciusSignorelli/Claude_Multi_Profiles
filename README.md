# claude-desktop-profiles-windows

Run **two Claude Desktop accounts side by side on Windows** (for example personal and work), each with its own login, history and settings, and make the browser sign-in callback land in the right window.

> Unofficial. Not affiliated with or endorsed by Anthropic. It relies on behaviour of the Electron `--user-data-dir` flag and of the Windows protocol handler registration, both of which can change with an app or Windows update.

## The problem

Claude Desktop supports one account at a time. Electron apps accept `--user-data-dir`, so a second profile is easy to open. Signing in is the hard part:

1. The sign-in happens in your browser.
2. The browser returns to the app through a `claude://` link.
3. Windows hands that link to the installed Claude, which always opens the **default** profile.

So you sign in from the work window and the result lands in the personal window. Changing `HKCU\Software\Classes\claude` does not help with the Microsoft Store (MSIX) build: Windows ignores it.

## How this works

- `Claude Personal` and `Claude Work` shortcuts, with a blue and an orange icon, so the two taskbar entries are easy to tell apart. The work shortcut starts Claude with its own data folder.
- `ClaudeRelay.exe`, a tiny windowless program registered as a handler for `claude://` links. By default it forwards the link to the personal profile. While a short-lived marker file exists, it forwards the link to the work profile instead.
- `Claude Work - First login`, a shortcut that creates the marker, opens the work window, and removes the marker when you press Enter. The marker also expires on its own after 15 minutes.

Icons are generated at install time from the logo shipped inside your own Claude package. No Anthropic assets are stored in this repository.

## Requirements

- Windows 11 with the Microsoft Store (MSIX) build of Claude Desktop. The package must expose the `claude-desktop.exe` execution alias.
- Windows PowerShell 5.1 and the .NET Framework compiler (`csc.exe`), both included with Windows.
- Administrator rights for **one** step (registering the handler machine-wide).

Tested with Claude Desktop 3.6556 on Windows 11 Pro.

## Install

1. Clone or download this repository.
2. In a normal PowerShell:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1
   ```

   Optional parameters: `-InstallDir`, `-WorkProfileDir`, `-ShortcutDir`.

3. In an **elevated** PowerShell (Run as administrator):

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\register-relay-machine.ps1
   ```

   On the tested Windows build, a per-user registration (`HKCU`) was not listed in Default apps. A machine-wide one (`HKLM`) was.

4. Open **Settings > Apps > Default apps**, search for `claude` under "Set a default for a file type or link type", open the `claude` link type and choose **Claude Relay**.

## First login on the work profile

1. Close the work Claude window if it is open. The personal one can stay open.
2. Run **Claude Work - First login**.
3. Sign in inside the **work** window.
4. When you are signed in, press Enter in the terminal.

Use **Claude Work** from then on. You only need the first-login shortcut again if the session expires.

## Troubleshooting

- `ClaudeProfiles\relay.log` records only the chosen target (`personal` or `work`) with a timestamp, never the link, which contains sign-in data. If the file does not grow when you sign in, Windows is not calling the relay: check the default app for the `claude` link type.
- If the sign-in still lands in the wrong window, make sure the first-login terminal is still waiting for Enter and that you are not past the 15 minute window.
- Local sessions, preferences and connectors are per profile. Claude Code settings in `%USERPROFILE%\.claude` are shared between both profiles.

## Uninstall

Set the default app for `claude` links back to Claude, then:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\uninstall.ps1
```

Run it elevated to also remove the registry entries. Your work profile data folder is never deleted.

## What it changes on your system

- Files under `%USERPROFILE%\ClaudeProfiles` (relay, icons, scripts).
- Three shortcuts on your desktop.
- With the elevated script: `HKLM\Software\ClaudeRelay`, `HKLM\Software\Classes\ClaudeRelay.Url` and one value under `HKLM\Software\RegisteredApplications`.

## Related projects

Other approaches to running several Claude Desktop instances, found while researching this. They were not tested for this repository:

- [vodongha/claude-desktop-clone](https://github.com/vodongha/claude-desktop-clone)
- [ajc3xc/dual-claude-launcher](https://github.com/ajc3xc/dual-claude-launcher)

## License

MIT. See [LICENSE](LICENSE).
