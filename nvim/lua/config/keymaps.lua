-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Smartly close the current file tab without breaking Neo-tree splits or window layouts
vim.keymap.set("n", "<S-q>", function()
  if Snacks and Snacks.bufdelete then
    -- 1. Grab a list of all currently active open code buffers
    local valid_buffers = vim.tbl_filter(function(buf)
      return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted
    end, vim.api.nvim_list_bufs())

    -- 2. If this is the absolute last open file tab, close it and force the Dashboard open
    if #valid_buffers <= 1 then
      Snacks.bufdelete()
      Snacks.dashboard.open()
    else
      -- 3. Otherwise, just cycle down to the next open file tab normally
      Snacks.bufdelete()
    end
  else
    -- Fallback safety measure
    vim.cmd("bdelete")
  end
end, { desc = "Smart Delete Buffer to Dashboard" })

-- Diagnostic popups for error innline
vim.diagnostic.config({
  -- 1. Configure the right-side inline alerts safely
  virtual_text = {
    spacing = 4,
    source = "if_many", -- Valid enum parameter for virtual text
    format = function(diagnostic)
      -- Truncate trailing messages so they never stretch outside the screen
      if string.len(diagnostic.message) > 60 then
        return string.sub(diagnostic.message, 1, 60) .. "..."
      end
      return diagnostic.message
    end,
  },

  -- 2. Configure the hover popup layout parameters safely
  float = {
    wrap = true, -- Binds text-wrapping inside the floating window frame perfectly!
    border = "rounded",
    source = true, -- Fixes the type error: true accomplishes the exact same behavior as "always"
  },
})

-- 3. Automatically open the wrapped diagnostic float box when hovering over an error line
vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    vim.diagnostic.open_float(nil, { focus = false })
  end,
})
