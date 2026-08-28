return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    lazy = false,
    opts = {
      flavour = "mocha",
      transparent_background = true,
      color_overrides = {
        all = {
          blue = "#f38ba8", -- Functions / Commands -> Red
          lavender = "#f9e2af", -- Variables / Parameters -> Gold
          sapphire = "#f9e2af", -- Types / Structs -> Gold
          sky = "#f38ba8", -- Operators -> Red
          teal = "#f9e2af", -- Identifiers -> Gold
          cyan = "#f9e2af", -- Constants / Special -> Gold
          green = "#f9e2af", -- Strings -> Gold
        },
      },
      custom_highlights = function(c)
        return {
          -- Base Normal & Line Numbers
          Normal = { fg = "#cdd6f4", bg = "NONE" },
          NormalNC = { fg = "#cdd6f4", bg = "NONE" },
          CursorLineNr = { fg = "#f9e2af", bold = true },
          LineNr = { fg = "#585b70" },

          -- Floating Windows & Telescope (Mafty Gold Borders)
          NormalFloat = { bg = "NONE" },
          FloatBorder = { fg = "#f9e2af", bg = "NONE" },
          FloatTitle = { fg = "#f38ba8", bg = "NONE", bold = true },
          TelescopeBorder = { fg = "#f9e2af", bg = "NONE" },
          TelescopeTitle = { fg = "#f38ba8", bold = true },

          -- Syntax Overrides (Mafty Red & Gold)
          ["@function"] = { fg = "#f38ba8", bold = true },
          ["@function.builtin"] = { fg = "#f38ba8" },
          ["@function.call"] = { fg = "#f38ba8" },
          ["@method"] = { fg = "#f38ba8" },
          ["@type"] = { fg = "#f9e2af" },
          ["@type.builtin"] = { fg = "#f9e2af" },
          ["@variable"] = { fg = "#cdd6f4" },
          ["@variable.builtin"] = { fg = "#f9e2af" },
          ["@variable.parameter"] = { fg = "#f9e2af" },
          ["@keyword"] = { fg = "#f38ba8", bold = true },
          ["@property"] = { fg = "#f9e2af" },
          ["@constant"] = { fg = "#f9e2af" },
          ["@string"] = { fg = "#f9e2af" },
          ["@comment"] = { fg = "#6c7086", italic = true },

          -- Diagnostics
          DiagnosticError = { fg = "#f38ba8" },
          DiagnosticWarn = { fg = "#f9e2af" },
          DiagnosticInfo = { fg = "#f9e2af" },

          -- Visual & Search
          Visual = { bg = "#45475a" },
          Search = { fg = "#11111b", bg = "#f9e2af" },
          IncSearch = { fg = "#11111b", bg = "#f38ba8" },
        }
      end,
    },
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-mocha", -- Explicitly target catppuccin-mocha
    },
  },
}
