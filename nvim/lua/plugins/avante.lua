return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  lazy = false,
  version = false,
  build = "make BUILD_FROM_SOURCE=true",
  opts = {
    provider = "openai",
    providers = {
      openai = {
        endpoint = "https://ai.sumopod.com/v1",
        -- Fix this string right here:
        model = "deepseek-v4-pro",
        timeout = 30000,
        extra_request_body = {
          temperature = 0,
          max_completion_tokens = 4096,
        },
      },
    },
    auto_suggestions = false,
    hints = { enabled = false },
    input = { provider = "dressing" },
    -- ADD THIS MAPPINGS BLOCK TO ENABLE INLINE FILE MENTIONS:
    mappings = {
      -- Standard text prompt window triggers
      ask = "<leader>aa",
      edit = "<leader>ae",
      refresh = "<leader>ar",
      focus = "<leader>af",
      toggle = {
        default = "<leader>at",
        debug = "<leader>ad",
        hint = "<leader>ah",
      },
      sidebar = {
        switch_windows = "<Tab>",
        add_file = "@",
      },
    },
    behaviour = {
      auto_set_keymaps = true,
      auto_focus_on_diff_view = true,
    },
  },
  -- ADD THIS CONFIG FUNCTION BLOCK TO REVERSE AND FIX THE VISIBILITY:
  config = function(_, opts)
    -- 1. Initialize Avante with baseline configs
    require("avante").setup(opts)

    -- 2. Force the chat answer streams to be crisp, high-visibility solid text
    vim.api.nvim_set_hl(0, "AvantePopupHint", { fg = "#FFFFFF", bold = true, force = true })
    vim.api.nvim_set_hl(0, "NormalFloat", { fg = "#E0E0E0", force = true })

    -- 3. Push the AI thinking blocks down into a clean, muted comment-style aesthetic
    -- Change the hex color code below to match your theme's muted gray/subtle tint
    vim.api.nvim_set_hl(0, "Comment", { fg = "#6e6a86", italic = true, force = true })
  end,
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons",
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = { file_types = { "markdown", "Avante" } },
      ft = { "markdown", "Avante" },
    },
  },
}
