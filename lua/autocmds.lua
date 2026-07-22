local autocmd = vim.api.nvim_create_autocmd
local create_cmd = vim.api.nvim_create_user_command

local lang_indentation = require("utils").lang_identation
local get_lockfile_commits = require("utils").get_lockfile_commits

autocmd({ "VimEnter" }, {
  callback = function(data)
    local no_name = data.file == "" and vim.bo[data.buf].buftype == ""
    local is_dir = vim.fn.isdirectory(data.file) == 1

    if is_dir then
      vim.cmd.cd(data.file)
      vim.cmd "enew"
      pcall(vim.api.nvim_buf_delete, data.buf, { force = true })

      require("nvim-tree.api").tree.open()
      vim.cmd "wincmd l"
      return
    end

    if no_name then
      require("nvim-tree.api").tree.open()
      vim.cmd "wincmd l"
      return
    end
  end,
})

autocmd("FileType", {
  pattern = vim.tbl_keys(lang_indentation), -- Dynamically monitors all keys in the table above
  callback = function(args)
    local width = lang_indentation[vim.bo[args.buf].filetype]
    if width then
      vim.bo[args.buf].tabstop = width
      vim.bo[args.buf].softtabstop = width
      vim.bo[args.buf].shiftwidth = width
      vim.bo[args.buf].expandtab = true
    end
  end,
})

autocmd("FileType", {
  pattern = "*",
  callback = function(args)
    local buf = args.buf
    local ft = vim.bo[buf].filetype
    -- enable indentation only for real languages
    if ft ~= "yaml" and ft ~= "markdown" then
      vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      vim.bo[buf].smartindent = false
      vim.bo[buf].cindent = false
    end

    local lang = vim.treesitter.language.get_lang(ft)

    if not lang then
      return
    end

    -- load parser safely
    local ok_add = pcall(vim.treesitter.language.add, lang)
    if not ok_add then
      return
    end

    -- start treesitter safely
    pcall(vim.treesitter.start, buf, lang)
  end,
})

-- vim.api.nvim_set_hl(0, "LspReferenceText", { underline = true, sp = "#56B6C2" })
-- vim.api.nvim_set_hl(0, "LspReferenceRead", { underline = true, sp = "#56B6C2" })
-- vim.api.nvim_set_hl(0, "LspReferenceWrite", { underline = true, sp = "#56B6C2" })
--
-- vim.api.nvim_create_autocmd("LspAttach", {
--   group = vim.api.nvim_create_augroup("UserLspHighlight", { clear = true }),
--   callback = function(event)
--     local client = vim.lsp.get_client_by_id(event.data.client_id)
--
--     if client and client.server_capabilities.documentHighlightProvider then
--       local highlight_augroup = vim.api.nvim_create_augroup("lsp_document_highlight", { clear = false })
--
--       vim.api.nvim_clear_autocmds({ buffer = event.buf, group = highlight_augroup })
--
--       vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
--         buffer = event.buf,
--         group = highlight_augroup,
--         callback = vim.lsp.buf.document_highlight,
--       })
--
--       vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
--         buffer = event.buf,
--         group = highlight_augroup,
--         callback = vim.lsp.buf.clear_references,
--       })
--     end
--   end,
-- })

local before_commits = {}
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  desc = "Trigger auto-updates",
  callback = function()
    vim.schedule(function ()
      before_commits = get_lockfile_commits()
      require("lazy").update { show = false }
    end)
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "LazyUpdate",
  desc = "Notify updated plugins",
  callback = function()
    local after_commits = get_lockfile_commits()
    local updated_plugins = {}

    for name, new_commit in pairs(after_commits) do
      local old_commit = before_commits[name]
      if old_commit and old_commit ~= new_commit then
        table.insert(updated_plugins, name)
      end
    end

    if #updated_plugins > 0 then
      table.sort(updated_plugins)

      local msg = "Updated " .. #updated_plugins .. " plugin(s):\n• " .. table.concat(updated_plugins, "\n• ")
      vim.notify(msg, vim.log.levels.INFO, { title = "Lazy Auto-Update" })
    end

    before_commits = {}
  end
})

autocmd("ColorScheme", {
  pattern = "*",
  callback = function()
    vim.api.nvim_set_hl(0, "IblIndent", { fg = "#3b4252" })
    vim.api.nvim_set_hl(0, "IblScope", { fg = "#88c0d0" })
  end,
})

create_cmd("TSInstallAll", function()
  local spec = require("lazy.core.config").plugins["nvim-treesitter"]
  local opts = type(spec.opts) == "table" and spec.opts or {}
  require("nvim-treesitter").install(opts.ensure_installed)
end, {})
