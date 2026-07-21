local autocmd = vim.api.nvim_create_autocmd
local create_cmd = vim.api.nvim_create_user_command
local lang_indentation = require("utils").lang_identation

autocmd({ "VimEnter" }, {
  callback = function()
    require("nvim-tree.api").tree.open()
    vim.cmd "wincmd p"
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

vim.api.nvim_create_autocmd("FileType", {
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

-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = {
--     "help",
--     "alpha",
--     "dashboard",
--     "NvimTree",
--     "Trouble",
--     "lazy",
--     "mason",
--     "notify",
--     "toggleterm",
--     "gitcommit",
--   },
--   callback = function ()
--     vim.b.miniindentscope_disable = true
--   end
-- })

vim.api.nvim_create_autocmd("ColorScheme", {
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
