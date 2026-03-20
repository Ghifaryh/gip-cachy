# 🚀 CachyOS Optimization Notes (Asus Vivobook M3401QC)

This document tracks the specific hardware and software tunings for the Ryzen 7 + RTX 3050 setup to balance performance, battery longevity, and "snappiness."

---

## 🔋 Battery Health & Power
| Feature | Setting | Command |
| :--- | :--- | :--- |
| **Charge Limit** | 80% (Daily) | `asusctl battery -l 80` |
| **Full Charge** | 100% (Oneshot) | `asusctl battery oneshot` |
| **Idle Goal** | 5W - 7W | Checked via `upower -i ...` |

## 🏎️ Performance Profiles (`asusd.ron`)
**Location:** `/etc/asusd/asusd.ron`

Key changes from default to eliminate "Battery Lag":
- **On Battery Profile:** Set to `Balanced` (was `Quiet`).
- **Balanced EPP:** Set to `BalancePerformance` (was `BalancePower`).
- **Nvidia Power:** `disable_nvidia_powerd_on_battery: true`.

## 🎮 Graphics Management (`supergfxctl`)
To maximize battery, the dGPU (RTX 3050) is toggled based on use case.
- **Office/Dev:** `supergfxctl -m Integrated` (Saves ~14W).
- **External Monitor/Heavy Work:** `supergfxctl -m Hybrid`.
- **User Action:** Requires Logout to apply mode changes.

## 📝 Storage & Sync (Obsidian)
**Method:** Rclone Systemd Service (`~/.config/systemd/user/rclone-gdrive.service`)
- **Remote:** `gdrive:` mounted to `~/Gdrive`.
- **VFS Cache Mode:** `full` (Required for Obsidian SQLite/Workspace writes).
- **Write Back:** 5s (Prevents constant API calls while typing).

---

## 🌙 Sleep & Idle (Hyprland)
**Config:** `hypridle.conf`
- **60s:** Dim brightness to 10%.
- **90s:** Lock session & DPMS off (OLED protection).
- **120s:** `systemctl suspend` (Deep sleep).
- **Nvidia Fix:** `nvidia.NVreg_PreserveVideoMemoryAllocations=1` added to Limine `cmdline`.
