# Dotfiles

Files that I use for configuration of software.

## Komorebi

+ Install komorebi with scoop for windows. Follow their guide for the appropriate commands (there's 2 packages).
+ Do `komorebic quickstart`
+ Run with `komorebic start --whkd --bar` ( This start the hotkey daemon and the bar on top)
+ Additionally, hide the windows taskbar and add a startup script to task manager for this. `powershell.exe` with params being the startup script.
+ You may also choose to do `komorebic enable-autostart` but that has problems for my system.

### File map

[Path] Must have [Filenames]

C:/Users/YourName/

+ `komorebi.json` & `komorebi.bar.json`

C:/Users/YourName/.config/

+ `whkdrc`

### Preview
![test](./komorebic/screenshot.png)