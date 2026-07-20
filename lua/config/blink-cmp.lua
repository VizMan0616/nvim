local M = {}

M.opts = {
  keymap = {
    preset = "none",
    ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
    ['<C-e>'] = { 'hide', 'fallback' },

    ['<Tab>'] = {
      function(cmp)
        if cmp.snippet_active() then return cmp.accept()
        else return cmp.select_and_accept() end
      end,
      'snippet_forward',
      'fallback'
    },
    ['<S-Tab>'] = { 'snippet_backward', 'fallback' },

    ['<Up>'] = { 'select_prev', 'fallback' },
    ['<Down>'] = { 'select_next', 'fallback' },
    ['<C-p>'] = { 'select_prev', 'fallback_to_mappings' },
    ['<C-n>'] = { 'select_next', 'fallback_to_mappings' },

    ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
    ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },

    ['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
  },
  appearance = { nerd_font_variant = "mono" },
  completion = {
    menu = {
      auto_show = true,
      border = "single",
      draw = {
        columns = { { "kind_icon" }, { "label", gap = 1 } },
        components = {
          label = {
            text = function(ctx)
              return require("colorful-menu").blink_components_text(ctx)
            end,
            highlight = function(ctx)
              return require("colorful-menu").blink_components_highlight(ctx)
            end,
          },
        },
      },
    },
    documentation = { auto_show = true, window = { border = "single" }, },
    trigger = { show_in_snippet = false }
  },
  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
  },
  fuzzy = { implementation = "lua" },
  signature = { window = { border = "single" } },
  -- snippets = { preset = "default" or "luasnip" },
}
M.opts_extend = { "sources.default" }

-- require("luasnip.loaders.from_vscode").lazy_load()
return M
