---@diagnostic disable: undefined-global
-- #######################################################################################
-- HYPRLAND CONFIGURATION (LUA REFACTOR)
-- #######################################################################################

--###############
--## MONITORS ###
--###############

hl.monitor({
	output = "eDP-1",
	mode = "2880x1800@60",
	-- mode = "2880x1800@90",
	position = "0x0",
	scale = "1.5",
})

hl.monitor({
	output = "HDMI-A-1",
	mode = "1920x1080@75",
	position = "1920x0",
	scale = "1",
})

--##################
--## MY PROGRAMS ###
--##################

local terminal = "ghostty"
local fileManager = "dolphin"

--################
--## AUTOSTART ###
--################

hl.on("hyprland.start", function()
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

	-- Launch KDE Polkit Agent in background
	hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1 &")

	-- UI, Notifications, and Daemons
	hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")
	-- hl.exec_cmd("waybar")
	hl.exec_cmd("hypridle")
	-- hl.exec_cmd("swayosd-server")
	-- hl.exec_cmd("swayosd-server --top-margin 0.92")
	-- hl.exec_cmd("swaync")
	hl.exec_cmd("sleep 1 && noctalia")
	-- hl.exec_cmd("swww-daemon || awww-daemon")
	-- hl.exec_cmd("sleep 0.5 && (swww restore || awww restore)")
	hl.exec_cmd("wl-paste --type text --watch cliphist -max-items 500 store")
	hl.exec_cmd("wl-paste --type image --watch cliphist -max-items 100 store")
	-- hl.exec_cmd("easyeffects --gapplication-service")
end)

--############################
--## ENVIRONMENT VARIABLES ###
--############################

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Dual GPU setup
hl.env("AQ_DRM_DEVICES", "/dev/dri/card2:/dev/dri/card1")

-- Desktop integration & Dark Mode fallback
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("GDK_BACKEND", "wayland,x11")

-- Force GTK & Qt Dark Theme
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- Let Hyprland compositor handle scaling naturally for Qt apps
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "0")
hl.env("QT_SCALE_FACTOR_ROUNDING_POLICY", "PassThrough")

-- Prevent Qt from forcing desktop-DPI multiplier on top of Wayland
hl.env("QT_ENABLE_HIGHDPI_SCALING", "0")
hl.env("QT_SCALE_FACTOR", "1")

-- Browser & Electron Wayland support
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Core Compositor Settings
hl.config({
	xwayland = {
		force_zero_scaling = true,
	},
	cursor = {
		no_hardware_cursors = 2,
		enable_hyprcursor = true,
	},
})

--####################
--## LOOK AND FEEL ###
--####################

hl.config({
	general = {
		gaps_in = 4,
		gaps_out = { top = 3, right = 4, bottom = 4, left = 4 },
		border_size = 2,
		col = {
			active_border = "rgba(ceb9e8ee)",
			inactive_border = "rgba(91b987aa)",
		},
		resize_on_border = true,
		allow_tearing = false,
		layout = "dwindle",
	},
	decoration = {
		rounding = 12,
		rounding_power = 2,
		active_opacity = 1.0,
		inactive_opacity = 1.0,
		dim_modal = true,
		shadow = {
			enabled = false,
		},
		blur = {
			enabled = false,
		},
	},
})

--###################
--## LAYER RULES ####
--###################

hl.layer_rule({
	name = "waybar-layer-effects",
	match = { namespace = "waybar" },
	blur = false,
	ignore_alpha = 0.1,
	animation = "fade",
})

hl.layer_rule({
	name = "noctalia-layer-effects",
	match = { namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$" },
	blur = true,
	ignore_alpha = 0.5,
	-- no_anim = true,
})

--###################
--## ANIMATIONS #####
--###################

hl.config({
	animations = {
		enabled = true,
	},
})

-- hl.curve("smooth", { type = "bezier", points = { { 0.22, 1 }, { 0.36, 1 } } })
hl.curve("snap", { type = "bezier", points = { { 0.1, 1 }, { 0.3, 1 } } })

hl.animation({
	leaf = "windows",
	enabled = true,
	speed = 2,
	bezier = "snap",
	style = "slide",
})

hl.animation({
	leaf = "windowsOut",
	enabled = true,
	speed = 2,
	bezier = "snap",
	style = "popin 80%",
})

hl.animation({
	leaf = "workspaces",
	enabled = true,
	speed = 3,
	bezier = "snap",
	style = "slide",
})

hl.animation({
	leaf = "fade",
	enabled = true,
	speed = 2,
	bezier = "snap",
})

--###########################################
--## WORKSPACE RULES & LAYOUT ENGINE ########
--###########################################

hl.window_rule({
	name = "fullscreen-no-gaps",
	match = {
		fullscreen = true,
	},
	border_size = 0,
	rounding = 0,
})

hl.config({
	dwindle = {
		preserve_split = true,
		smart_split = false,
		smart_resizing = true,
	},
	master = {
		new_status = "master",
		mfact = 0.55,
	},
})

--###########################################
--## MISCELLANEOUS & COMPOSITOR BEHAVIOR ###
--###########################################

hl.config({
	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
		animate_mouse_windowdragging = false,
		vrr = 1,
		mouse_move_enables_dpms = true,
		key_press_enables_dpms = true,
		always_follow_on_dnd = true,
	},
})

--############
--## INPUT ###
--############

hl.config({
	input = {
		kb_layout = "us",
		follow_mouse = 1,
		sensitivity = 0,
		touchpad = {
			natural_scroll = true,
			scroll_factor = 0.5,
			tap_to_click = true,
			clickfinger_behavior = true,
		},
	},
})

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

--##################
--## HYPREXPO ######
--##################

local mainMod = "SUPER"
local noctalia = "noctalia msg "

-- hyprland-plugins ships this .so. If Hyprland errors on hl.plugin.load,
-- run `hyprpm enable hyprexpo` and remove the load line.
-- hl.plugin.load("/usr/lib/hyprland/plugins/hyprexpo.so")

-- hl.config({
-- 	plugin = {
-- 		hyprexpo = {
-- 			columns = 3,
-- 			rows = 3,
-- 			gaps_in = 8,
-- 			gaps_out = 4,
-- 			workspace_method = "center current",
-- 			tile_rounding_power = 2.0,
-- 			tile_rounding = 12,
-- 			tile_rounding_focus = 12,
-- 			tile_rounding_hover = 12,
-- 			keynav_enable = 1,
-- 			number_key_mode = "workspace",
-- 		},
-- 	},
-- })

-- hl.define_submap("hyprexpo", function()
-- 	hl.bind("H", function()
-- 		hl.plugin.hyprexpo.kb_focus("left")
-- 	end)
-- 	hl.bind("J", function()
-- 		hl.plugin.hyprexpo.kb_focus("down")
-- 	end)
-- 	hl.bind("K", function()
-- 		hl.plugin.hyprexpo.kb_focus("up")
-- 	end)
-- 	hl.bind("L", function()
-- 		hl.plugin.hyprexpo.kb_focus("right")
-- 	end)
-- 	hl.bind("return", function()
-- 		hl.plugin.hyprexpo.kb_confirm()
-- 	end)
-- 	hl.bind(mainMod .. " + O", function()
-- 		hl.plugin.hyprexpo.expo("toggle")
-- 	end)
-- end)

--##################
--## KEYBINDINGS ###
--##################

-- --- ESSENTIAL APPS & LAUNCHERS ---
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + W", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("brave-browser-nightly"))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd('xdg-open "https://"'))
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd("obsidian"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(noctalia .. "panel-toggle launcher"))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd(noctalia .. "panel-toggle control-center"))
hl.bind(mainMod .. " + COMMA", hl.dsp.exec_cmd(noctalia .. "settings-toggle"))
hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd(noctalia .. "window-switcher hold"))
-- hl.bind(mainMod .. " + SLASH", hl.dsp.exec_cmd(noctalia .. "panel-toggle syaikhu/hypr-cheatsheet:cheatsheet"))
-- hl.bind(mainMod .. " + O", function()
-- 	hl.plugin.hyprexpo.expo("toggle")
-- end)

hl.bind(
	mainMod .. " + PERIOD",
	hl.dsp.exec_cmd(
		'bash -c "rofimoji --action copy --selector-args \\"-theme $HOME/.config/rofi/emoji.rasi\\" && sleep 0.1 && wtype -M ctrl v"'
	)
)

hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd(noctalia .. "panel-toggle clipboard"))
hl.bind(
	mainMod .. " + ALT + V",
	hl.dsp.exec_cmd(
		'bash -c "cliphist list | rofi -dmenu -theme $HOME/.config/rofi/launchers/type-6/style-1.rasi | cliphist decode | wl-copy && wtype -M ctrl v"'
	)
)

hl.bind(
	"SHIFT + Print",
	hl.dsp.exec_cmd(
		'bash -c \'AREA=$(slurp) && grim -g "$AREA" - | wl-copy && notify-send -h int:transient:1 "Screenshot" "Region copied to clipboard"\''
	)
)

hl.bind(mainMod .. " + N", hl.dsp.window.cycle_next({ next = true }))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.window.cycle_next({ next = false }))
-- hl.bind(mainMod .. " + ALT + N", hl.dsp.exec_cmd("swaync-client -t -sw"))
hl.bind(mainMod .. " + ALT + N", hl.dsp.exec_cmd(noctalia .. "panel-toggle control-center"))

-- --- SESSION & POWER CONTROLS ---
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd(noctalia .. "panel-toggle session"))
-- hl.bind(mainMod .. " + ALT + ESCAPE", hl.dsp.exec_cmd("pkill wlogout || wlogout"))
hl.bind(
	mainMod .. " + M",
	hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit")
)

-- --- WINDOW MANAGEMENT & LAYOUTS ---
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle", layout_aware = true }))
hl.bind(mainMod .. " + ALT + F", function()
	hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
	hl.dispatch(hl.dsp.window.resize({ x = 1600, y = 1000, relative = false }))
	hl.dispatch(hl.dsp.window.center())
end)

hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind(mainMod .. " + C", hl.dsp.window.center())

hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + ALT + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + SHIFT + X", hl.dsp.layout("swapsplit"))

-- Move focus (vim keys, arrows kept)
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))

hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.swap({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.swap({ direction = "d" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.swap({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.swap({ direction = "r" }))

-- Swap windows (Shift + Arrow keys)
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.swap({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.swap({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.swap({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.swap({ direction = "d" }))

hl.bind(mainMod .. " + CTRL + H", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + J", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + L", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })

-- Window Resizing
hl.bind(mainMod .. " + EQUAL", hl.dsp.window.resize({ x = 40, y = 40, relative = true }), { repeating = true })
hl.bind(mainMod .. " + MINUS", hl.dsp.window.resize({ x = -40, y = -40, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + EQUAL", hl.dsp.window.resize({ x = 0, y = -40, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + MINUS", hl.dsp.window.resize({ x = 0, y = 40, relative = true }), { repeating = true })

-- --- WORKSPACES & SCRATCHPADS ---
for i = 1, 10 do
	local ws = tostring(i % 10)
	hl.bind(mainMod .. " + " .. ws, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. ws, hl.dsp.window.move({ workspace = i }))
end

-- General Scratchpad (moved off Super+S, which opens the control center)
hl.bind(mainMod .. " + ALT + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + ALT + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Tmux Scratchpad Keybinds
hl.bind(mainMod .. " + T", hl.dsp.workspace.toggle_special("scratchpad"))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.window.move({ workspace = "special:scratchpad" }))

-- --- HARDWARE & SYSTEM SCRIPTS ---
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("hyprctl reload config-only"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))
-- hl.bind(mainMod .. " + ALT + R", hl.dsp.exec_cmd("~/.config/hypr/scripts/wbrestart.sh"))
hl.bind(mainMod .. " + F11", hl.dsp.exec_cmd("~/.config/hypr/scripts/hz_cycle.sh"))
hl.bind(
	mainMod .. " + F12",
	hl.dsp.exec_cmd(
		'asusctl profile next && notify-send "ASUS Profile" "$(asusctl profile get | grep \'Active profile\')" -i diagnostic'
	)
)

-- Media / Brightness / Volume (Noctalia OSD)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(noctalia .. "volume-up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(noctalia .. "volume-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(noctalia .. "volume-mute"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(noctalia .. "mic-mute"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(noctalia .. "brightness-up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(noctalia .. "brightness-down"), { locked = true, repeating = true })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- --- MOUSE BINDINGS ---
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Window drag (LMB) & resize (RMB)
hl.bind(mainMod .. " + mouse:272", function()
	hl.dispatch(hl.dsp.exec_raw("exec hyprctl dispatch movewindow"))
end)

hl.bind(mainMod .. " + mouse:273", function()
	hl.dispatch(hl.dsp.exec_raw("exec hyprctl dispatch resizewindow"))
end)

--#########################
--## WORKSPACE RULES ######
--#########################

-- hl.workspace_rule({
-- 	workspace = "special:scratchpad",
-- 	on_created_empty = terminal .. " tmux",
-- })

for i = 1, 5 do
	hl.workspace_rule({
		workspace = tostring(i),
		monitor = "eDP-1",
	})
end

for i = 6, 10 do
	hl.workspace_rule({
		workspace = tostring(i),
		monitor = "HDMI-A-1",
		default = (i == 6),
	})
end

--#######################
--## WINDOW RULES #######
--#######################

hl.window_rule({
	name = "suppress-maximize-events",
	match = { class = ".*" },
	suppress_event = "maximize",
})

hl.window_rule({
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},
	no_focus = true,
})

hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },
	move = "20 monitor_h-120",
	float = true,
})

hl.window_rule({
	name = "firefox-pip",
	match = {
		class = "^(firefox)$",
		title = "^Picture-in-Picture$",
	},
	float = true,
	pin = true,
	animation = "none",
	size = "530 300",
	move = "1380 830",
})

hl.window_rule({
	name = "brave-youtube-pip",
	match = { title = "^Picture in picture$" },
	float = true,
	pin = true,
	animation = "none",
	size = "530 300",
	-- size = "unset 300",
	move = "1380 885",
})

hl.window_rule({
	name = "spotify-browser-pip",
	match = {
		class = "^brave-browser-nightly$",
		title = ".* • .*",
	},
	float = true,
	pin = true,
	animation = "none",
	size = "340 340",
	move = "1570 850",
})

hl.window_rule({
	name = "bitwarden-float",
	match = { class = "^brave-nngceckbapebfimnlniiiahkandclblb-Default$" },
	float = true,
	center = true,
	pin = true,
	dim_around = true,
	stay_focused = true,
	size = "480 700",
})

hl.window_rule({
	name = "browser-login-popups",
	match = {
		class = "^(brave-browser.*|Brave-browser.*)$",
		title = "^.*(Sign in|Log in|Authorize|Authentication|Connect|OAuth).*$",
	},
	float = true,
	center = true,
	stay_focused = true,
	dim_around = true,
	size = "500 700",
})

hl.window_rule({
	name = "firefox-no-blur",
	match = { class = "firefox" },
	no_blur = true,
})

hl.window_rule({
	name = terminal .. "-opacity",
	match = { class = terminal },
	opacity = "0.8 0.8",
})

hl.window_rule({
	name = "bluetui-impala-float",
	match = { class = "^(impala-float|bluetui-float)$" },
	float = true,
	size = "900 600",
	center = true,
	pin = true,
	dim_around = true,
	stay_focused = true,
	opacity = "0.8 0.8",
})

hl.window_rule({
	name = "pavucontrol-portal-float",
	match = { class = "^(org.pulseaudio.pavucontrol|xdg-desktop-portal-gtk)$" },
	float = true,
	size = "900 600",
	center = true,
	pin = true,
	dim_around = true,
	stay_focused = true,
})

hl.window_rule({
	name = "polkit-agent-float",
	-- match = { class = "^(polkit-gnome-authentication-agent-1|hyprpolkitagent)$" },
	match = { class = "^(polkit-gnome-authentication-agent-1|hyprpolkitagent|polkit-kde-authentication-agent-1)$" },
	float = true,
	center = true,
	pin = true,
	stay_focused = true,
})

hl.window_rule({
	name = "blueman-manager-float",
	match = { class = "^(blueman-manager)$" },
	float = true,
	size = "800 500",
	center = true,
})

hl.window_rule({
	name = "common-dialog-titles-float",
	match = { title = "^(Confirm to replace files|File Operation Progress|Authentication Required)$" },
	float = true,
})

hl.window_rule({
	name = "zoom-main-tile",
	match = {
		class = "^(zoom)$",
		title = "^(Zoom Meeting|Zoom Workplace)$",
	},
	float = false,
})

hl.window_rule({
	name = "zoom-popups-float",
	match = {
		class = "^(zoom)$",
		title = "^(Settings|Participants|Chat|Meeting Information|Breakout Rooms|Select a window)$",
	},
	float = true,
	center = true,
})

hl.window_rule({
	name = "termius-float",
	match = { class = "^(Termius|termius-app)$" },
	float = true,
	size = "1200 800",
	center = true,
})

for i = 6, 10 do
	hl.window_rule({
		match = { workspace = tostring(i) },
		opacity = "1.0 1.0", -- [active] [inactive]
		opaque = true,
	})
end

--#######################
--## WINDOW GROUPS ######
--#######################

hl.config({
	group = {
		auto_group = true,
		col = {
			border_active = "rgba(ceb9e8ee)",
			border_inactive = "rgba(91b987aa)",
		},
		groupbar = {
			enabled = true,
			font_size = 10,
			gradients = false,
			col = {
				active = "rgba(ceb9e8ee)",
				inactive = "rgba(91b987aa)",
			},
			text_color = "rgba(dce4efff)",
		},
	},
})
