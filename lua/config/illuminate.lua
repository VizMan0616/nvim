require("illuminate").configure {
  providers = { "lsp", "treesitter" },
  delay = 150, -- Delay in milliseconds before highlighting
  disable_keymaps = true,
  filetypes_denylist = {
    "NvimTree",
    "lazy",
    "mason",
    "TelescopePrompt",
  },
}
