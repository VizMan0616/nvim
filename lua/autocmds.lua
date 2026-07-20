local autocmd = vim.api.nvim_create_autocmd
local create_cmd = vim.api.nvim_create_user_command

autocmd({ "VimEnter" }, {
  callback = function()
    require("nvim-tree.api").tree.open()
    vim.cmd "wincmd p"
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

create_cmd("TSInstallAll", function()
  local spec = require("lazy.core.config").plugins["nvim-treesitter"]
  local opts = type(spec.opts) == "table" and spec.opts or {}
  require("nvim-treesitter").install(opts.ensure_installed)
end, {})
