local M = {}

---@class pick.Spec
---@field [1]? string
---@field src? string
---@field name? string
---@field version? string
---@field data? any
---@field lazy? boolean
---@field event? string|string[]
---@field ft? string|string[]
---@field cmd? string|string[]
---@field dependencies? (string|pick.Spec)[]
---@field build? string|fun()
---@field init? fun()
---@field config? fun()

---@class pick.AddOpts
---@field load? boolean|fun(plug_data: {spec: vim.pack.Spec, path: string})
---@field confirm? boolean

---@class pick.Config
---@field plugins? pick.Spec[]
---@field add? pick.AddOpts

local loaded = {}

local function is_lazy(spec)
  if spec.lazy ~= nil then return spec.lazy end
  return spec.event ~= nil or spec.ft ~= nil or spec.cmd ~= nil
end

local function do_load(spec)
  local src = spec[1] or spec.src
  if loaded[src] then return end
  loaded[src] = true

  if spec.dependencies then
    for _, dep in ipairs(spec.dependencies) do
      if type(dep) == "string" then
        if not loaded[dep] then
          vim.pack.add({ dep })
          loaded[dep] = true
        end
      else
        local dep_src = dep[1] or dep.src
        if not loaded[dep_src] then
          vim.pack.add({ dep_src, name = dep.name, version = dep.version })
          vim.cmd.packadd(dep.name or vim.fn.fnamemodify(dep_src, ":t"))
          loaded[dep_src] = true
          if dep.config then dep.config() end
        end
      end
    end
  end

  vim.cmd.packadd(spec.name or vim.fn.fnamemodify(src, ":t"))

  if spec.config then spec.config() end
end

local function setup_ft(spec)
  local fts = type(spec.ft) == "string" and { spec.ft } or spec.ft
  local group = vim.api.nvim_create_augroup("PICK_FT_" .. (spec[1] or spec.src), { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = fts,
    once = true,
    callback = function() do_load(spec) end,
  })
end

local function setup_event(spec)
  local events = type(spec.event) == "string" and { spec.event } or spec.event
  local group = vim.api.nvim_create_augroup("PICK_EVENT_" .. (spec[1] or spec.src), { clear = true })

  vim.api.nvim_create_autocmd(events, {
    group = group,
    once = true,
    callback = function() do_load(spec) end,
  })
end

local function setup_cmd(spec)
  local cmds = type(spec.cmd) == "string" and { spec.cmd } or spec.cmd

  for _, cmd_name in ipairs(cmds) do
    vim.api.nvim_create_user_command(cmd_name, function(args)
      vim.api.nvim_del_user_command(cmd_name)
      do_load(spec)
      local bang = args.bang and "!" or ""
      vim.cmd(string.format("%s%s %s", cmd_name, bang, args.args or ""))
    end, {
      bang = true,
      nargs = "*",
    })
  end
end

---@param opts? pick.Config
function M.setup(opts)
  if not vim.pack then error("[pick.nvim] 需要 Neovim 0.12+(vim.pick 不可用)，请升级") end
  opts = opts or {}
  local plugins = opts.plugins or {}
  local add_opts = opts.add or {}
  local build_map = {}

  vim.api.nvim_create_autocmd("PackChanged", {
    group = vim.api.nvim_create_augroup("PICK_BUILD", { clear = true }),
    callback = function(ev)
      local name = ev.data.spec.name
      local kind = ev.data.kind
      local build = build_map[name]
      if not build or (kind ~= "install" and kind ~= "update") then return end
      if type(build) == "string" then
        vim.cmd(build)
      elseif type(build) == "function" then
        build()
      end
    end,
  })

  for _, spec in ipairs(plugins) do
    local src = spec[1] or spec.src

    if spec.build then
      local name = spec.name or vim.fn.fnamemodify(src, ":t")
      build_map[name] = spec.build
    end

    if spec.init then spec.init() end

    if not is_lazy(spec) then
      vim.pack.add({ src, name = spec.name, version = spec.version }, add_opts)
      if spec.config then spec.config() end
    else
      vim.pack.add({
        src,
        name = spec.name,
        version = spec.version,
      }, vim.tbl_extend("force", add_opts, { load = false }))

      if spec.event then setup_event(spec) end

      if spec.ft then setup_ft(spec) end

      if spec.cmd then setup_cmd(spec) end
    end
  end
end

function M.update(name, opts)
  if not vim.pack then error("[pick.nvim] 需要 Neovim 0.12+(vim.pick 不可用)，请升级") end
  vim.pack.update(name, opts)
end

function M.del(name, opts)
  if not vim.pack then error("[pick.nvim] 需要 Neovim 0.12+(vim.pick 不可用)，请升级") end
  vim.pack.del(name, opts)
end

function M.get(name)
  if not vim.pack then error("[pick.nvim] 需要 Neovim 0.12+(vim.pick 不可用)，请升级") end
  return vim.pack.get(name)
end

return M
