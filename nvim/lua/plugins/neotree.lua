return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        visible = true, -- Ensure hidden things are visible when toggled
        hide_gitignored = true, -- Never hide files just because they are in .gitignore
        hide_dotfiles = false, -- Show standard dotfiles by default
        hide_by_name = {
          -- If .env is explicitly blocked here by LazyVim, this clears it out
        },
        never_show = {
          -- This empties out the strict global blocklist so nothing stays permanently invisible
        },
      },
    },
  },
}
