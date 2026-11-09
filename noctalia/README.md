# Try the Nix Noctalia look

This was written on Windows and has not been launched. Waybar, SwayNC, SwayOSD, and the Hyprland autostart block are unchanged. The new binds and the window look are already in `hypr/hyprland.lua` on the `nix-like-look-noctalia` branch.

## Install

On CachyOS:

```sh
sudo pacman -S noctalia inter-font hyprland-plugins hyprpicker
```

| Package | Why |
|---|---|
| `noctalia` | The shell. It is in Arch `extra`. |
| `inter-font` | The bar and shell font. |
| `hyprland-plugins` | hyprexpo, the 3x3 workspace overview on Super+O. |
| `hyprpicker` | The color picker plugin. |

Noctalia downloads the official and community plugins itself. Those are not pacman packages.

If `brave-browser-nightly` is not the command that launches Brave, change the Super+B bind in `hypr/hyprland.lua`.

## Apply

From this repo, on the Cachy machine:

```sh
mkdir -p ~/.config/noctalia
cp noctalia/config.toml ~/.config/noctalia/config.toml
cp -a noctalia/plugins ~/.config/noctalia/plugins
cp hypr/hyprland.lua ~/.config/hypr/hyprland.lua
```

`config.toml` points the local plugin source at `~/.config/noctalia/plugins`. The cheatsheet will not be found if only the toml file is copied.

Then comment these lines in `~/.config/hypr/hyprland.lua` and add Noctalia. This repo leaves them running so Waybar does not disappear until you do this:

```lua
-- hl.exec_cmd("waybar")
-- hl.exec_cmd("swayosd-server --top-margin 0.92")
-- hl.exec_cmd("swaync")
hl.exec_cmd("noctalia")
```

Reload Hyprland after the copy. If a setting in this file seems ignored, delete `~/.local/state/noctalia/settings.toml`. Noctalia writes GUI changes there, and that file wins.

A blank Brave icon on the dock means the desktop id is different. Check `/usr/share/applications` for the Brave file name and replace `brave-browser-nightly` in `config.toml`.

If Hyprland reports an error on `hl.plugin.load`, the plugin path is different on that build. Enable it with `hyprpm enable hyprexpo` and remove the `hl.plugin.load` line.

## What you get

- A top bar inset 400px from each side, thickness 36, radius 12, Inter, capsules, opacity 0.9.
- A bottom dock, icon size 28, with Brave and Ghostty pinned. Open windows show next to the pins. The launcher button uses `~/.config/waybar/Mafty-new-new.svg`.
- Wallpaper colors, scheme `m3-monochrome`. Noctalia wallpaper is off so it does not fight `swww`. Set `[wallpaper].directory`, then `enabled = true`, and comment the `swww` lines in autostart.
- Screen-corner masks at size 22, a carousel window switcher, a compact control center, top-right notifications, and a top-center OSD.
- Window gaps 4/8, rounding 12, blur, shadow, Aurora borders (`#CEB9E8` active, `#91B987` inactive), and slow slide animations.
- The lock screen settings are in the toml with `enabled = false`, so Super+Shift+L still locks with hyprlock. Set `[lockscreen] enabled = true` to hand the lock to Noctalia. The Nix lock widgets were laid out for 1920x1080 and were not copied.

## Plugins that may not load

`syaikhu/hypr-cheatsheet` is the local plugin from the Nix repo. Its manifest asks for plugin API 9. Current Noctalia documents support for API levels 3 through 51, so the id is allowed, but these scripts were not run here. If the panel errors, disable `syaikhu/hypr-cheatsheet`.

`oldirtty/color_picker` and `k4n4t4/hypr-submap` are the community ids from the Nix config. If either is missing from the v5 catalog, `noctalia msg plugins list` shows the current names. Remove the missing id from `[plugins].enabled` and, for the submap widget, from the bar `start` list.

## Keybinds

Nix keys replaced the colliding Cachy keys. Arrows still move focus. Super+W still closes a window. Super+T is still the tmux scratchpad.

| Key | Now | Was |
|---|---|---|
| Super+Space | Noctalia launcher | Rofi |
| Super+S | Control center | Magic scratchpad, now Super+Alt+S |
| Super+Alt+Shift+S | Move window to the magic scratchpad | Super+Shift+S |
| Super+O | hyprexpo overview | Obsidian, now Super+Shift+O |
| Super+F | Fullscreen | Float and center, now Super+Alt+F |
| Super+V | Float | cliphist paste, now Super+Alt+V |
| Super+Shift+V | Noctalia clipboard | |
| Super+N | Next window | SwayNC, now Super+Alt+N |
| Super+Shift+N | Previous window | |
| Super+R | Reload config only | |
| Super+Shift+R | Full Hyprland reload | Waybar restart, now Super+Alt+R |
| Super+Escape | Noctalia session menu | wlogout, now Super+Alt+Escape |
| Super+J | Focus down | togglesplit, now Super+Alt+J |
| Super+B | Brave | |
| Super+Tab | Window switcher | |
| Super+Comma | Noctalia settings | |
| Super+/ | Keybind cheatsheet | |
| Super+HJKL | Focus | |
| Super+Shift+HJKL | Swap windows | |
| Super+Ctrl+HJKL | Resize | |

Volume, mute, and brightness keys call `noctalia msg` (`volume-up`, `volume-down`, `volume-mute`, `brightness-up`, `brightness-down`). Mic mute calls `noctalia msg mic-mute`. If that key does nothing, run `noctalia msg` and use the mic command it lists. These popups show up after Noctalia is running. Until you comment `swayosd-server`, SwayOSD can also pop up.

## Left alone

Tailscale, the VPN menu, and the memory module stay in Waybar. Monitors, VRR, touchpad scroll, picture-in-picture rules, and Ghostty's 0.8 opacity rule are unchanged. Zen mode is not bound. The Nix config calls a custom helper for it, not a Hyprland dispatcher.
