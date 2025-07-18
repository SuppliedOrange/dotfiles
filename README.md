# Dotfiles

Files that I use for configuration of software.

Follow `filemap.json` to know where to put what files. They're currently localised to my system, but you can make out what yours would be.

## Sync Scripts

+ Run `.\sync_files.ps1` to automatically sync all files from filemap.
+ Run `.\auto_sync_and_pr.ps1 -Run` to sync files and automatically create a pull request if changes are detected.

### Auto Sync and PR Script

Automatically syncs your scripts and opens a PR if things have changed. **Requires either -Run or -DryRun flag to run (mutually exclusive).**

**Usage:**

```powershell
# Dry run (shows what would happen without making changes)
.\auto_sync_and_pr.ps1 -DryRun
.\auto_sync_and_pr.ps1 -dr

# Run the script and make changes
.\auto_sync_and_pr.ps1 -Run
.\auto_sync_and_pr.ps1 -r

# Custom branch prefix and commit message with aliases
.\auto_sync_and_pr.ps1 -r -b "config-update" -c "Updated system configs"

# Show help
.\auto_sync_and_pr.ps1 -Help
.\auto_sync_and_pr.ps1 -h
```

**Parameter Aliases:**

+ `-Run` or `-r`: Run the script and make actual changes
+ `-DryRun` or `-dr`: Dry run mode (mutually exclusive with -Run)
+ `-BranchPrefix` or `-b`: Custom branch prefix
+ `-CommitMessage` or `-c`: Custom commit message
+ `-Help` or `-h`: Show help message

> This automatically creates a PR on changes just so you know!

**Requirements:**

+ Github CLI `gh`
+ Git `git`
+ Python (3.x) `python`

## Komorebi

+ Install komorebi with scoop for windows. Follow their guide for the appropriate commands (there's 2 packages).
+ Do `komorebic quickstart`
+ Run with `komorebic start --whkd --bar` ( This start the hotkey daemon and the bar on top, you can include --masir if you'd like mouse-following focus too)
+ Additionally, hide the windows taskbar and add a startup script to task manager for this. `powershell.exe` with params being the startup script.
+ You may also choose to do `komorebic enable-autostart` but that has problems for my system.
+ My wallpaper is [lain_bliss](https://steamcommunity.com/sharedfiles/filedetails/?id=2686491283) by [deicha torar](https://steamcommunity.com/id/neveirissimo/) running on wallpaper engine. The video is available on [youtube](https://youtu.be/atMcPxyksGM) if you'd like to load it on your own animated wallpaper client.
+ Additionally, I use [komorebi-loader](https://github.com/SuppliedOrange/komorebi-loading) with this system but that's a completely optional reqirement.

### Preview

![A preview of my system running komorebi](./komorebic/screenshot.png)

## Vesktop

+ Install [Vesktop](https://github.com/Vencord/Vesktop) from their github repo.
+ Open up the "themes" page in your Vesktop (Discord) settings and click on "Open Themes Folder". You can google how to do so if this changes in the future.
+ Put in your desired themes/plugins from the "vesktop" category in this repo.

### Preview

![A preview of my vesktop discord client with a custom theme](./vesktop/screenshot.png)