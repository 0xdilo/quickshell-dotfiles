```
                 _      __       __         ____
   ____ _ __  __(_)____/ /__ ___/ /_  ___  / / /
  / __ `// / / / // ___/ //_// __  / / _ \/ / /
 / /_/ // /_/ / // /__/ ,<  / /_/ / /  __/ / /
 \__, / \__,_/_/ \___/_/|_| \__,_/  \___/_/_/
   /_/

      /\_/\
     ( o.o )
      > ^ <
```

# quickshell-dotfiles

a smol quickshell rice for hyprland :3

## features

- **bar** - workspaces, system stats, volume, network, bluetooth, battery
- **launcher** - apps + real command suggestions from PATH
- **clipboard** - history manager (needs `cliphist`)
- **tools** - screenshot, ocr, color picker, yt downloader

## deps

```
quickshell cliphist wl-copy grim slurp hyprpicker tesseract yt-dlp
```

## install

```bash
git clone https://github.com/0xdilo/quickshell-dotfiles ~/Git/quick
quickshell -p ~/Git/quick
```

## keybinds

add to `hyprland.conf`:

```bash
bind = $mod, D, exec, quickshell msg -p ~/Git/quick shell toggleLauncherIpc
bind = $mod, V, exec, quickshell msg -p ~/Git/quick shell toggleClipboardIpc
bind = $mod, X, exec, quickshell msg -p ~/Git/quick shell toggleToolsIpc
```

autostart:
```bash
exec-once = quickshell -p ~/Git/quick
```

## theme

edit `Theme.qml` for colors. works with [iro](https://github.com/0xdilo/iro) for automatic wallpaper-based theming :3

## license

do whatever u want with it lol
