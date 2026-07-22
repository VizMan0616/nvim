local M = {}
local map = vim.keymap.set
local signs = {
  [vim.diagnostic.severity.ERROR] = " ",
  [vim.diagnostic.severity.WARN] = " ",
  [vim.diagnostic.severity.HINT] = "󰠠 ",
  [vim.diagnostic.severity.INFO] = " ",
}

vim.diagnostic.config {
  signs = { text = signs },
  virtual_text = false,
  underline = true, -- Always on
  update_in_insert = false,
  float = {
    focusable = false,
    style = "minimal",
    border = "single",
    source = true,
  },
}

function M.on_init(client, _)
  if vim.fn.has "nvim-0.11" ~= 1 then
    if client.supports_method "textDocument/semanticTokens" then
      client.server_capabilities.semanticTokensProvider = nil
    end
  else
    if client:supports_method "textDocument/semanticTokens" then
      client.server_capabilities.semanticTokensProvider = nil
    end
  end
end

M.capabilities = vim.lsp.protocol.make_client_capabilities()
local ok, blink = pcall(require, "blink.cmp")
if ok then
  M.capabilities = blink.get_lsp_capabilities(M.capabilities)
end

function M.defaults()
  local root_dir = function(bufnr, cb)
    local root = vim.fs.root(bufnr, { ".git" }) or vim.fn.expand "%:p:h"
    cb(root)
  end
  vim.lsp.config("*", { root_dir = root_dir, capabilities = M.capabilities, on_init = M.on_init })

  -- Lua config
  local root_dir_lua = function(bufnr, cb)
    local root = vim.fs.root(bufnr, {
      "luarc.json",
      ".luarc.json",
      ".git",
    }) or vim.fn.expand "%:p:h"
    cb(root)
  end

  local lua_lsp_settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      completion = {
        -- callSnippet = 'Replace',
        showWord = "Disable",
      },
      diagnostics = {
        globals = { "vim" },
        undefined_global = false,
        disable = {
          "missing-parameter",
          "missing-fields",
          "unused-function",
        },
      },
      workspace = {
        ignoreDir = { ".git" },
        checkThirdParty = false,
        library = {
          vim.fn.expand "$VIMRUNTIME/lua",
          vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy",
          vim.fn.stdpath "config" .. "/lua",
        },
      },
    },
    single_file_support = false,
  }

  vim.lsp.config("lua_ls", {
    cmd = { "lua-language-server" },
    fileypes = { "lua" },
    root_dir = root_dir_lua,
    settings = lua_lsp_settings,
  })
  vim.lsp.enable "lua_ls"
end

function M.lspconfigs(servers)
  local paths = require "paths"
  local utils = require "utils"

  local function get_python_runtime(odoo_version)
    local workspace = vim.fn.getcwd()
    local default_runner = {
      ruff = { "ruff", "server" },
      basedpyright = {
        cmd = { "basedpyright-langserver", "--stdio" },
        analysis = { typeCheckingMode = "standard" },
      },
      ty = { "ty", "server" },
    }

    local is_running, _ = utils.check_if_odoo_container_is_running()
    local image_path_exists = utils.check_development_image_path_exists()

    if not is_running or not image_path_exists then
      return default_runner
    end

    local image_exist, _ = utils.check_if_odoo_development_image_exists(odoo_version)
    if not image_exist then
      utils.build_odoo_development_image(odoo_version)
    end
    utils.run_odoo_development_image(odoo_version, workspace)

    return {
      ruff = {
        "docker",
        "run",
        "-i",
        "--rm",
        "-v",
        workspace .. ":" .. workspace,
        "odoo-" .. odoo_version .. "-development:latest",
        "ruff",
        "server",
      },
      basedpyright = {
        cmd = {
          "docker",
          "run",
          "-i",
          "--rm",
          "-v",
          workspace .. ":" .. workspace,
          "odoo-" .. odoo_version .. "-development:latest",
          "basedpyright-langserver",
          "--stdio",
        },
        analysis = { typeCheckingMode = "off" },
      },
      ty = {
        "docker",
        "run",
        "-i",
        "--rm",
        "-v",
        workspace .. ":" .. workspace,
        "odoo-" .. odoo_version .. "-development:latest",
        "ty",
        "server",
      },
    }
  end

  local _python_runtime = nil
  local function get_cached_python_runtime()
    if not _python_runtime then
      _python_runtime = get_python_runtime "17" --[cite: 1]
    end
    return _python_runtime
  end

  local root_dir = {
    python = function(bufnr, cb)
      local bufname = vim.api.nvim_buf_get_name(bufnr)
      if string.match(bufname, "site%-packages") or string.match(bufname, "[\\/][Ll]ib[\\/]") then
        return
      end

      local root = vim.fs.root(bufnr, {
        "pyproject.toml",
        "pyrightconfig.json",
        "ruff.toml",
        ".ruff.toml",
        -- "pyrefly.toml",
        ".git",
      }) or vim.fn.expand "%:p:h"

      cb(root)
    end,
    typescript = function(bufnr, cb)
      local root = vim.fs.root(bufnr, {
        "package.json",
        "jsconfig.json",
        "tsconfig.json",
        ".git",
      }) or vim.fn.expand "%p:h"

      cb(root)
    end,
  }

  local ruff_config = paths.lsp.ruff.config_path()
  -- local python_runtime = get_python_runtime "17"

  vim.lsp.config("ruff", {
    cmd = { "ruff", "server" },
    on_new_config = function(new_config, _)
      new_config.cmd = get_cached_python_runtime().ruff
    end,
    before_init = function(params)
      params.processId = vim.NIL
    end,
    filetypes = { "python" },
    root_dir = root_dir.python,
    on_attach = function(client, _)
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
      client.server_capabilities.hoverProvider = false
    end,
    init_options = {
      settings = {
        configuration = ruff_config,
        logFile = paths.lsp.ruff.log_path,
        logLevel = "warn",
        organizeImports = true,
        showSyntaxErrors = true,
        codeAction = {
          disableRuleComment = { enable = false },
          fixViolation = { enable = false },
        },
        format = { preview = false },
        lint = { enable = true },
      },
    },
    single_file_support = false,
  })

  vim.lsp.config("basedpyright", {
    cmd = { "basedpyright-langserver", "--stdio" },
    on_new_config = function(new_config, _)
      local runtime = get_cached_python_runtime()
      new_config.cmd = runtime.basedpyright.cmd
      new_config.settings.basedpyright.analysis.typeCheckingMode = runtime.basedpyright.analysis.typeCheckingMode
    end,
    before_init = function(params)
      params.processId = vim.NIL
    end,
    filetypes = { "python" },
    root_dir = root_dir.python,
    on_attach = function(client, _)
      client.server_capabilities.completionProvider = false
      client.server_capabilities.definitionProvider = false
      client.server_capabilities.documentHighlightProvider = false
      client.server_capabilities.renameProvider = false
      client.server_capabilities.semanticTokensProvider = false
    end,
    settings = {
      basedpyright = {
        disableOrganizeImports = true,
        analysis = {
          typeCheckingMode = "standard",
          inlayHints = {
            variableTypes = true,
            functionReturnTypes = true,
            callArgumentNames = false,
            genericTypes = false,
          },
          autoImportCompletions = true,
          autoSearchPaths = true,
          diagnosticsMode = "openFilesOnly",
          useLibraryCodeForTypes = true,
          diagnosticServerityOverrides = {
            reportUnknownMeberType = "none",
            reportUnusedCallResult = "none",
          },
          exclude = {
            "**/.venv",
            "**/venv",
            "**/__pycache__",
            "**/dist",
            "**/build",
          },
        },
      },
    },
  })

  vim.lsp.config("ty", {
    cmd = { "ty", "server" },
    on_new_config = function(new_config, _)
      new_config.cmd = get_cached_python_runtime().ty
    end,
    before_init = function(params)
      params.processId = vim.NIL
    end,
    filetypes = { "python" },
    root_dir = root_dir.python,
    on_attach = function(client, _)
      client.server_capabilities.codeActionProvider = false
      client.server_capabilities.documentSymbolProvider = false
      client.server_capabilities.hoverProvider = false
      client.server_capabilities.inlayHintProvider = false
      client.server_capabilities.referenceProvider = false
      client.server_capabilities.signatureHelpProvider = false
    end,
    settings = { ty = {} },
  })

  vim.lsp.config("emmet_language_server", {
    filetypes = {
      "css",
      "html",
      "javascript",
      "javascriptreact",
      "less",
      "typescriptreact",
    },
    init_options = {
      includeLanguages = {},
      excludeLanguages = {},
      extensionsPath = {},
      preferences = {},
      showAbbreviationSuggestions = true,
      showExpandedAbbreviation = "always",
      showSuggestionsAsSnippets = false,
      syntaxProfiles = {},
      variables = {},
    },
  })

  vim.lsp.config("cssls", {
    filetypes = { "css", "scss", "less" },
    init_options = { provideFormatter = true },
    single_file_support = true,
    settings = {
      css = {
        lint = { unknownAtRules = "ignore" },
        validate = true,
      },
      scss = {
        lint = { unknownAtRules = "ignore" },
        validate = true,
      },
      less = {
        lint = { unknownAtRules = "ignore" },
        validate = true,
      },
    },
  })

  vim.lsp.config("ts_ls", {
    cmd = { "typescript-language-server", "--stdio" },
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    root_dir = root_dir.typescript,
    workspace_required = false,
    single_file_support = true,
    init_options = {
      preferences = {
        includeCompletionsForModuleExports = true,
        includeCompletionsForImportStatements = true,
      },
    },
    settings = {
      typescript = {
        inlayHints = {
          includeInlayParameterNameHints = "all",
          includeInlayVariableTypeHints = true,
          includeInlayFunctionParameterTypeHints = true,
        },
      },
      javascript = {
        inlayHints = {
          includeInlayParameterNameHints = "none",
          includeInlayVariableTypeHints = false,
          includeInlayFunctionParameterTypeHints = false,
        },
      },
    },
  })

  vim.lsp.config("rust_analyzer", {
    filetypes = { "rust" },
    settings = {
      ["rust-analyzer"] = {
        -- clippy is just better
        check = { command = "clippy" },
        -- off by default (very much needed)
        procMacro = { enable = true },
        cargo = {
          buildScripts = { enable = true },
          allFeatures = true,
        },
      },
    },
  })

  vim.lsp.enable(servers)
end

return M
