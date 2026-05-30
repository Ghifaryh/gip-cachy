return {
  -- 1. Point to the new official Mason organization repository
  {
    "mason-org/mason.nvim",
    opts = {
      -- Keeps any custom global Mason configurations you want here
    },
  },

  -- 2. Update the lspconfig extension repository bridge
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      -- This ensures LazyVim automatically installs your development tools
      ensure_installed = { "vtsls", "astro" },
    },
  },

  -- 3. Wire them into the core Neovim lspconfig system layer
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- Declare your development servers here inside LazyVim's native registry.
      -- This handles capabilities, dynamic path injection, and prevents early boot crashes.
      servers = {
        vtsls = {},
        astro = {},
      },
    },
  },
}
