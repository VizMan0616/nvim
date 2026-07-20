local M = {}

M.opts = {
  git = { enable = true, ignore = false },
  filters = { dotfiles = false },
  disable_netrw = true,
  hijack_cursor = true,
  sync_root_with_cwd = true,
  update_focused_file = {
    enable = true,
    update_root = false,
  },
  view = {
    width = 40,
    preserve_window_proportions = true,
  },
  renderer = {
    root_folder_label = false,
    highlight_git = true,
    indent_markers = { enable = true },
    icons = {
      glyphs = {
        default = "󰈚",
        folder = {
          default = "",
          empty = "",
          empty_open = "",
          open = "",
          symlink = "",
        },
        git = { unmerged = "" },
      },
    },
  },
}
M.config = function(_, opts)
  require("nvim-tree").setup(opts)

  vim.cmd [[ highlight NvimTreeGitIgnored guibg=NONE guifg=#5c6370 ]]
  vim.cmd [[ highlight NvimTreeHiddenFile guibg=NONE guifg=#5c6370 ]]
  vim.cmd [[ highlight NvimTreeEmptyFolder guibg=NONE guifg=#5c6370 ]]
end

return M
