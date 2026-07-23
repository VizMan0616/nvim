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
  diagnostics = {
    enable = true,
    show_on_dirs = true,
    show_on_open_dirs = true,
    debounce_delay = 50,
    severity = {
      min = vim.diagnostic.severity.WARN,
      max = vim.diagnostic.severity.ERROR,
    },
    icons = { warning = "●", error = "●" },
  },
  renderer = {
    root_folder_label = false,
    highlight_git = "name",
    highlight_diagnostics = "name",
    indent_markers = { enable = true },
    icons = {
      diagnostics_placement = "before",
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

  -- This is to change colors of git highlights
  vim.api.nvim_set_hl(0, "NvimTreeGitDirty", { link = "DiagnosticWarn" })    -- Yellow
  vim.api.nvim_set_hl(0, "NvimTreeGitUntracked", { link = "DiagnosticOk" })  -- Green
  vim.api.nvim_set_hl(0, "NvimTreeGitNew", { link = "DiagnosticOk" })        -- Green
  vim.api.nvim_set_hl(0, "NvimTreeGitStaged", { link = "DiagnosticInfo" })

  -- This is to set color of underlines in files for errors and warnings
  vim.api.nvim_set_hl(0, "NvimTreeDiagnosticErrorFileHL", { link = "DiagnosticUnderlineError" })
  vim.api.nvim_set_hl(0, "NvimTreeDiagnosticWarnFileHL", { link = "DiagnosticUnderlineWarn" })
  vim.api.nvim_set_hl(0, "NvimTreeDiagnosticErrorFolderHL", { link = "DiagnosticUnderlineError" })
  vim.api.nvim_set_hl(0, "NvimTreeDiagnosticWarnFolderHL", { link = "DiagnosticUnderlineWarn" })
end

return M
