local M = {}
local state_file = vim.fn.stdpath("state") .. "/nvim_tree_show_dotfiles"

local function load_show_dotfiles()
  local f = io.open(state_file, "r")
  if f then
    local content = f:read("*all")
    f:close()
    return content:gsub("%s+", "") == "true"
  end
  return false
end

M.opts = {
  git = { enable = true, ignore = false },
  filters = { dotfiles = not load_show_dotfiles() },
  disable_netrw = true,
  hijack_cursor = true,
  hijack_directories = { enable = false },
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
    highlight_git = "name",
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
end

vim.api.nvim_set_hl(0, "NvimTreeGitDirty", { link = "DiagnosticWarn" })    -- Yellow
vim.api.nvim_set_hl(0, "NvimTreeGitUntracked", { link = "DiagnosticOk" })  -- Green
vim.api.nvim_set_hl(0, "NvimTreeGitNew", { link = "DiagnosticOk" })        -- Green
vim.api.nvim_set_hl(0, "NvimTreeGitStaged", { link = "DiagnosticInfo" })

return M
