# Dotfiles

Files that I use for configuration of software.

## Komorebi

+ Install komorebi with scoop for windows. Follow their guide for the appropriate commands (there's 2 packages).
+ Do `komorebic quickstart`
+ Run with `komorebic start --whkd --bar` ( This start the hotkey daemon and the bar on top, you can include --masir if you'd like mouse-following focus too)
+ Additionally, hide the windows taskbar and add a startup script to task manager for this. `powershell.exe` with params being the startup script.
+ You may also choose to do `komorebic enable-autostart` but that has problems for my system.
+ My wallpaper is [lain_bliss](https://steamcommunity.com/sharedfiles/filedetails/?id=2686491283) by [deicha torar](https://steamcommunity.com/id/neveirissimo/) running on wallpaper engine. The video is available on [youtube](https://youtu.be/atMcPxyksGM) if you'd like to load it on your own animated wallpaper client.
+ Additionally, I use [komorebi-loader](https://github.com/SuppliedOrange/komorebi-loading) with this system but that's a completely optional reqirement.

### File map

[Path] Must have [Filenames]

C:/Users/YourName/

+ `komorebi.json` & `komorebi.bar.json`

C:/Users/YourName/.config/

+ `whkdrc`

### Preview
![test](./komorebic/screenshot.png)
