# 🌌 Gip's Dotfiles: The Latest CachyOS ricing Workstation.

Personal configuration files for a high-performance, aesthetically driven development environment on **CachyOS**.

## 🛠️ The Tech Stack
* **OS:** CachyOS (Arch-based)
* **WM:** Hyprland (Wayland)
* **Terminal:** Kitty (with transparency & blur)
* **Shell:** Zsh + Oh My Zsh + Starship
* **Multiplexer:** tmux (Prefix: `Ctrl + a`)
* **Editor:** Neovim (LazyVim Distro)
* **Theme:** Catppuccin Mocha (Unified across all tools)

---

## ⌨️ tmux Keybinds
Customized for ergonomics and seamless integration with Neovim.

| Action | Keybind |
| :--- | :--- |
| **Prefix** | `Ctrl + a` |
| **Go to start of line** | `Ctrl + a` (twice) |
| **Split Vertical** | `Prefix` + `\|` |
| **Split Horizontal** | `Prefix` + `-` |
| **Navigate Panes** | `Ctrl + h/j/k/l` |
| **Zoom Pane** | `Prefix` + `z` |
| **Close Pane** | `Prefix` + `x` |
| **New Window (Tab)** | `Prefix` + `c` |
| **Switch Windows** | `Prefix` + `0-9` |
| **Detach Session** | `Prefix` + `d` |
| **Session List** | `Prefix` + `s` |
| **Save Session** | `Prefix` + `Ctrl + s` |
| **Restore Session** | `Prefix` + `Ctrl + r` |

---

## ⚡ Neovim (LazyVim) Keybinds
**Leader Key:** `Space`

### Navigation & Files
| Action | Keybind |
| :--- | :--- |
| **File Explorer** | `Leader` + `e` |
| **Find Files** | `Leader` + `f` + `f` |
| **Live Grep (Search Text)**| `Leader` + `s` + `g` |
| **Teleport (Flash)** | `s` + `[2 chars]` |
| **Jump to Start/End** | `0` / `$` |
| **Jump to First Letter** | `^` |

### Editing & LSP
| Action | Keybind |
| :--- | :--- |
| **Change Inner Word** | `c` + `i` + `w` |
| **Repeat Last Action** | `.` |
| **Code Actions** | `Leader` + `l` + `a` |
| **Global Replace** | `:%s/old/new/g` |
| **Hover Docs** | `K` |
| **Format File** | `Leader` + `c` + `f` |

---

## 🐚 Custom Shell Aliases
Power commands added to `~/.zshrc`.

| Command | Function |
| :--- | :--- |
| `dots` | Auto-sync all configs to GitHub: `dots "commit message"` |
| `ta` | Attach to the last active tmux session |
| `update` | Full system update using `paru` |
| `bat80` | Limit battery charge to 80% (Conservation Mode) |
| `rb` | Hard reset Waybar and Hyprland components |

---

## 📁 Repository Structure
Linked via symbolic links (`ln -s`) to maintain a live-sync with the system.

```bash
~/dotfiles/
├── hypr/       # Hyprland window manager config
├── kitty/      # Terminal emulator settings
├── nvim/       # LazyVim configuration & plugins
├── waybar/     # Status bar CSS and JSONC
├── .tmux.conf  # Tmux prefix and plugin logic
└── .zshrc      # Shell aliases and environment variables
```

---

## 🚀 Installation
```zsh
git clone git@github.com:Ghifaryh/gip-cachy.git ~/dotfiles
# Use the linking script or manually link:
ln -s ~/dotfiles/.tmux.conf ~/.tmux.conf
```

***

### 🛠️ Maintenance Note
Whenever a change is made to any configuration:
1. Edit the file (changes are live due to symlinks).
2. Run `dots "updated [feature]"` to push to the cloud.
