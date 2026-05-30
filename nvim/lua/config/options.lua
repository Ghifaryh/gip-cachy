-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--

vim.opt.clipboard = "unnamedplus"

-- Enable soft wrapping to adjust to the code editor panel size
vim.opt.wrap = true

-- Smart breaking: only wrap lines at clean word boundaries (spaces, tabs)
vim.opt.linebreak = true

-- Optional: Adds a clean visual arrow indicator at the start of an overflowed line
vim.opt.showbreak = "↪ "

-- Ensure Neovim doesn't try to inject physical line breaks into your source code files
vim.opt.textwidth = 0
