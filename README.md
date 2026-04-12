<div align="center">

# 📦 pick.nvim

**A thin wrapper around Neovim's built-in `vim.pack` with a declarative, lazy.nvim-style config.**

[中文文档](./README.zh-CN.md)

[![Neovim](https://img.shields.io/badge/Neovim-0.12+-blue.svg?style=flat-square&logo=neovim)](https://neovim.io/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](./LICENSE)

</div>

---

## ✨ Features

- **Built-in Power:** Wraps Neovim's native `vim.pack` without reinventing the wheel.
- **Familiar Syntax:** Declarative `lazy.nvim`-style configuration for plugins.
- **Lazy Loading:** Native support for `event`, `ft`, and `cmd` lazy-load triggers.
- **Zero Dependencies:** Pure Lua, requiring only Neovim 0.12+ and Git.
- **Lightweight:** Tiny codebase (~200 lines).

## 📋 Requirements

- **Neovim >= 0.12** (requires `vim.pack` feature)
- **git** installed and available in `$PATH`

## 🚀 Install

Clone into any directory and add it to your `runtimepath` **before** calling `setup()`:

```lua
-- init.lua
vim.opt.rtp:prepend("~/.config/nvim/pack/pick/start/pick.nvim")
-- or wherever you cloned the repo
```

Or bootstrap using `vim.pack` itself:

```lua
local pick_path = vim.fn.stdpath("data") .. "/site/pack/core/opt/pick.nvim"
if not vim.uv.fs_stat(pick_path) then
  vim.system({ "git", "clone", "https://github.com/xhconceit/pick.nvim", pick_path }):wait()
end
vim.cmd.packadd("pick.nvim")
```

## ⚡ Quick Start

```lua
require("pick").setup({
  add = { confirm = false },
  plugins = {
    -- 1. Load immediately
    {
      "folke/tokyonight.nvim",
      config = function()
        vim.cmd.colorscheme("tokyonight")
      end,
    },
    
    -- 2. Lazy load on event
    {
      "lewis6991/gitsigns.nvim",
      event = "BufReadPost",
      config = function()
        require("gitsigns").setup()
      end,
    },
    
    -- 3. Lazy load on command
    {
      "folke/which-key.nvim",
      cmd = "WhichKey",
      config = function()
        require("which-key").setup()
      end,
    },

    -- 4. With dependencies
    {
      "neovim/nvim-lspconfig",
      ft = { "lua", "python" },
      dependencies = {
        "williamboman/mason.nvim",
        {
          "williamboman/mason-lspconfig.nvim",
          config = function()
            require("mason-lspconfig").setup()
          end,
        },
      },
      config = function()
        require("lspconfig").lua_ls.setup({})
      end,
    },
  },
})
```

## 🛠️ Plugin Spec

Each entry in `plugins` supports the following fields:

| Field | Type | Description |
|-------|------|-------------|
| `[1]` | `string` | Plugin source shorthand, e.g. `"folke/tokyonight.nvim"`. |
| `src` | `string` | Plugin source. Takes precedence over `[1]` if both exist. |
| `name` | `string?` | Optional plugin name. |
| `version` | `string?` | Version constraint (branch, tag, commit, or `vim.version.range()`). |
| `data` | `any?` | Passed through to `vim.pack.Spec.data`. |
| `lazy` | `boolean?` | Lazy-load the plugin. Defaults to `true` when `event`, `ft`, or `cmd` is set. |
| `event` | `string\|string[]?` | Load on autocmd event(s). |
| `ft` | `string\|string[]?` | Load on filetype(s). |
| `cmd` | `string\|string[]?` | Load on user command(s). |
| `dependencies` | `(string\|table)[]?` | Plugins to load before this one. Each entry can be a `"author/repo"` string or a full spec table. |
| `build` | `string\|fun()?` | Run after install/update. String is executed as a vim command; function is called directly. |
| `init` | `fun()?` | Runs **before** the plugin is loaded. Use for `vim.g.*` or `vim.opt.*` settings. |
| `config` | `fun()?` | Runs **after** the plugin is loaded. Use for `require("plugin").setup()`. |

## ⚙️ Global Options

The top-level `add` table is passed through to every `vim.pack.add()` call:

```lua
require("pick").setup({
  add = {
    confirm = false,  -- skip install confirmation
    -- load: boolean|function (see :help vim.pack.add())
  },
  plugins = { ... },
})
```

## ⏳ Lazy Loading

When `event`, `ft`, or `cmd` is specified (or `lazy = true`), the plugin is registered with `vim.pack.add(..., { load = false })` and loaded later via a trigger:

- **`event`** — creates a one-shot `autocmd`; plugin loads when the event fires.
- **`ft`** — creates a one-shot `FileType` autocmd with the given pattern(s).
- **`cmd`** — registers placeholder user commands; the first invocation loads the plugin and re-executes the command.

Multiple triggers can coexist (e.g. `event` + `cmd`). The plugin is loaded only once regardless of which trigger fires first.

## 🔗 Dependencies

The `dependencies` field ensures that required plugins are installed and loaded **before** the main plugin:

```lua
{
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
  },
  config = function()
    require("cmp").setup({ ... })
  end,
}
```

Each dependency can be a simple `"author/repo"` string, or a table with its own `name`, `version`, and `config` fields.

> **Note:** pick.nvim does **not** resolve nested or transitive dependencies. Keep your dependency lists flat.

## 🔨 Build

The `build` field runs after a plugin is installed or updated (via the `PackChanged` event):

- **String** — executed as a vim command (e.g. `":TSUpdate"`)
- **Function** — called directly

### Example

```lua
{
  "nvim-treesitter/nvim-treesitter",
  event = "BufReadPost",
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter.configs").setup({
      ensure_installed = { "lua", "vimdoc" },
    })
  end,
},
{
  "neovim/nvim-lspconfig",
  ft = { "lua", "python" },
  config = function()
    require("lspconfig").lua_ls.setup({})
    require("lspconfig").pyright.setup({})
  end,
}
```

## 📖 API

### `require("pick").setup(opts)`
Main entry point. Registers all plugins and sets up lazy-load triggers.

### `require("pick").update(name?, opts?)`
Thin wrapper around `vim.pack.update()`.

### `require("pick").del(name, opts?)`
Thin wrapper around `vim.pack.del()`.

### `require("pick").get(name?)`
Thin wrapper around `vim.pack.get()`.

## ⚠️ Using with lazy.nvim

If you want to use pick.nvim alongside lazy.nvim, be aware that lazy.nvim resets `packpath` by default via `performance.reset_packpath`. This removes the `site/pack` directory that `vim.pack` relies on.

To avoid conflicts, disable this in your lazy.nvim config:

```lua
require("lazy").setup({
  -- your plugins ...
}, {
  performance = {
    reset_packpath = false,
  },
})
```

Alternatively, keep the two sets of plugins completely separate — use lazy.nvim for plugins that need its advanced features, and pick.nvim for simple ones managed by `vim.pack`.

## 📄 License

MIT
