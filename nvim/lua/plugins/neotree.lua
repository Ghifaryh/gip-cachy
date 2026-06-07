return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        visible = true,
        hide_gitignored = false,
        hide_dotfiles = false,
        hide_by_name = {},
        never_show = {},
      },
      -- ADD THIS BLOCK TO FORCE LIVE UPDATES:
      use_libuv_file_watcher = true, -- Uses system-level events to watch for file changes instantly
    },
    -- Configure the event managers to refresh Git statuses automatically
    event_handlers = {
      {
        event = "git_status_changed",
        handler = function()
          require("neo-tree.sources.manager").refresh("filesystem")
        end,
      },
    },
  },
}
