<div align="center">

# 📦 pick.nvim

**基于 Neovim 内置 `vim.pack` 的轻量封装，提供声明式的配置体验。**

[English](./README.md)

[![Neovim](https://img.shields.io/badge/Neovim-0.12+-blue.svg?style=flat-square&logo=neovim)](https://neovim.io/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](./LICENSE)

</div>

---

## ✨ 特性

- **原生驱动：** 完全基于 Neovim 原生的 `vim.pack` API，不重复造轮子。
- **熟悉语法：** 提供类似 `lazy.nvim` 的声明式配置写法。
- **延迟加载：** 原生支持基于 `event`、`ft` 和 `cmd` 的延迟加载触发器。
- **零依赖：** 纯 Lua 实现，仅需要 Neovim 0.12+ 和 Git。
- **自动更新：** 内置周期性更新检查，可自定义检查间隔。
- **命令行操作：** 提供 `:Pick` 命令及子命令，方便管理插件。
- **极度轻量：** 核心代码仅约 270 行。

## 📋 环境要求

- **Neovim >= 0.12**（需要 `vim.pack` 支持）
- 系统已安装 **git** 并在 `$PATH` 中可用

## 🚀 安装

将仓库克隆到任意目录，在调用 `setup()` **之前**添加到 `runtimepath`：

```lua
-- init.lua
vim.opt.rtp:prepend("~/.config/nvim/pack/pick/start/pick.nvim")
-- 或者你克隆到的其他路径
```

也可以用 `vim.pack` 自身来引导安装：

```lua
local pick_path = vim.fn.stdpath("data") .. "/site/pack/core/opt/pick.nvim"
if not vim.uv.fs_stat(pick_path) then
  vim.system({ "git", "clone", "https://github.com/xhconceit/pick.nvim", pick_path }):wait()
end
vim.cmd.packadd("pick.nvim")
```

## ⚡ 快速开始

```lua
require("pick").setup({
  add = { confirm = false },
  plugins = {
    -- 1. 立即加载
    {
      "folke/tokyonight.nvim",
      config = function()
        vim.cmd.colorscheme("tokyonight")
      end,
    },
    
    -- 2. 依据事件延迟加载
    {
      "lewis6991/gitsigns.nvim",
      event = "BufReadPost",
      config = function()
        require("gitsigns").setup()
      end,
    },
    
    -- 3. 依据命令延迟加载
    {
      "folke/which-key.nvim",
      cmd = "WhichKey",
      config = function()
        require("which-key").setup()
      end,
    },

    -- 4. 带依赖的插件
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

## 🛠️ 插件声明字段

`plugins` 列表中的每一项支持以下字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| `[1]` | `string` | 插件源简写，例如 `"folke/tokyonight.nvim"`。 |
| `src` | `string` | 插件源。若与 `[1]` 同时存在，`src` 优先。 |
| `name` | `string?` | 可选插件名。 |
| `version` | `string?` | 版本约束（分支、标签、commit 或 `vim.version.range()`）。 |
| `data` | `any?` | 透传给 `vim.pack.Spec.data`。 |
| `lazy` | `boolean?` | 是否延迟加载。设置了 `event`、`ft` 或 `cmd` 时默认为 `true`。 |
| `event` | `string\|string[]?` | 由自动命令事件触发加载。 |
| `ft` | `string\|string[]?` | 由文件类型触发加载。 |
| `cmd` | `string\|string[]?` | 由用户命令触发加载。 |
| `dependencies` | `(string\|table)[]?` | 前置依赖插件列表。每项可以是 `"author/repo"` 字符串或完整的声明表。 |
| `build` | `string\|fun()?` | 安装或更新后执行。字符串作为 vim 命令运行，函数则直接调用。 |
| `init` | `fun()?` | 在插件加载**之前**执行。适合设置 `vim.g.*` 或 `vim.opt.*`。 |
| `config` | `fun()?` | 在插件加载**之后**执行。适合调用 `require("plugin").setup()`。 |

## ⚙️ 全局选项

顶层的 `add` 表会透传给每次 `vim.pack.add()` 调用：

```lua
require("pick").setup({
  add = {
    confirm = false,  -- 跳过安装确认
    -- load: boolean|function（详见 :help vim.pack.add()）
  },
  plugins = { ... },
})
```

### 自动更新检查

`checker` 表用于开启自动周期性更新检查：

```lua
require("pick").setup({
  checker = {
    enabled = true,       -- 开启自动更新检查（默认 false）
    frequency = 86400,    -- 检查间隔，单位秒（默认 86400 = 1 天）
    force = false,        -- true: 静默更新；false: 弹出确认窗口（默认 false）
  },
  plugins = { ... },
})
```

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `enabled` | `boolean?` | `false` | 是否开启自动更新检查。 |
| `frequency` | `number?` | `86400` | 检查间隔（秒）。 |
| `force` | `boolean?` | `false` | 为 `true` 时静默更新；为 `false` 时弹出确认窗口。 |

上次检查时间持久化在 `stdpath("state")/pick.json` 中，跨会话保留。当 `force = true` 时，长运行会话中会循环调度检查；当 `force = false` 时，每次启动只触发一次（避免反复弹出确认窗口）。

## ⏳ 延迟加载

当指定了 `event`、`ft` 或 `cmd`（或显式设置 `lazy = true`）时，插件会先以 `vim.pack.add(..., { load = false })` 注册，再通过触发器延迟加载：

- **`event`** — 创建一次性 `autocmd`，事件触发时加载插件。
- **`ft`** — 创建一次性 `FileType` 自动命令，匹配指定文件类型时加载。
- **`cmd`** — 注册占位用户命令，首次调用时加载插件并重新执行原始命令。

多个触发条件可以共存（如 `event` + `cmd`），无论哪个先触发，插件只会加载一次。

## 🔗 依赖管理

`dependencies` 字段确保依赖插件在主插件**之前**安装并加载：

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

每个依赖项可以是简单的 `"author/repo"` 字符串，也可以是一个包含 `name`、`version`、`config` 等字段的表。

> **注意：** pick.nvim **不会**解析嵌套或传递性依赖，请保持依赖列表扁平。

## 🔨 构建

`build` 字段在插件安装或更新后执行（通过 `PackChanged` 事件触发）：

- **字符串** — 作为 vim 命令执行（如 `":TSUpdate"`）
- **函数** — 直接调用

### 示例

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

## 💻 命令

pick.nvim 提供了 `:Pick` 命令及以下子命令：

| 命令 | 说明 |
|------|------|
| `:Pick` | 更新所有插件（等同于 `:Pick update`）。 |
| `:Pick update [name ...]` | 更新全部或指定插件，弹出确认窗口。 |
| `:Pick del <name ...>` | 删除指定插件。 |
| `:Pick list` | 列出所有已管理的插件及其状态。 |
| `:Pick check` | 手动触发一次更新检查（重置检查计时器）。 |

所有子命令均支持 Tab 补全（子命令名称和插件名称）。

## 📖 API

### `require("pick").setup(opts)`
主入口。注册所有插件并建立延迟加载触发器。

### `require("pick").update(name?, opts?)`
`vim.pack.update()` 的薄封装。

### `require("pick").del(name, opts?)`
`vim.pack.del()` 的薄封装。

### `require("pick").get(name?)`
`vim.pack.get()` 的薄封装。

## ⚠️ 与 lazy.nvim 混用

如果你想同时使用 pick.nvim 和 lazy.nvim，需要注意 lazy.nvim 默认会通过 `performance.reset_packpath` 重置 `packpath`，这会移除 `vim.pack` 依赖的 `site/pack` 目录。

要避免冲突，请在 lazy.nvim 配置中关闭此选项：

```lua
require("lazy").setup({
  -- 你的插件 ...
}, {
  performance = {
    reset_packpath = false,
  },
})
```

或者将两者的插件完全分开管理——用 lazy.nvim 管理需要其高级功能的插件，用 pick.nvim 管理简单的、由 `vim.pack` 托管的插件。

## 📄 许可证

MIT
