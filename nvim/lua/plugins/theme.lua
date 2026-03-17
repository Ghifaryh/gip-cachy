return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      flavour = "mocha", -- Matches your tmux!
      transparent_background = true, -- Matches your Hyprland blur!
      integrations = {
        telescope = true,
        mason = true,
        which_key = true,
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
