local mapx = {}

local mapopts = {
  buffer = { buffer = true },
  nowait = { nowait = true },
  silent = { silent = true },
  script = { script = true },
  expr   = { expr   = true },
  unique = { unique = true },
}

local fns = {}

local setup = false
local globalized = false
local whichkey = nil

local function merge(...)
  local res = {}
  for i = 1, select('#', ...) do
    local arg = select(i, ...)
    if type(arg) == 'table' then
      for k, v in pairs(arg) do
        res[k] = v
      end
    else
      table.insert(res, arg)
    end
  end
  return res
end

local function extract_doc(opts)
  if whichkey == nil then
    return nil
  end
  local doc = nil
  if opts.doc ~= nil then
    doc = opts.doc
    opts.doc = nil
    return doc
  end
  if opts[#opts] ~= nil and mapopts[opts[#opts]] == nil then
    doc = opts[#opts]
    table.remove(opts, #opts)
    return doc
  end
  return nil
end

local function _map(mode, _opts)
  return function(lhs, rhs, ...)
    local opts = merge({}, _opts, ...)
    for i, o in ipairs(opts) do
      if type(o) == 'string' and mapopts[o] ~= nil then
        opts[o] = true
        table.remove(opts, i)
      end
    end
    local lhss = lhs
    if type(lhs) ~= 'table' then
      lhss = {lhs}
    end
    local doc = extract_doc(opts)
    for _, l in ipairs(lhss) do
      if doc ~= nil and whichkey ~= nil then
        local wkopts = opts
        if mode ~= '' then
          wkopts = merge(opts, { mode = mode })
        end
        whichkey.register({
          [l] = { rhs, doc }
        }, wkopts)
      elseif opts.buffer ~= nil then
        local b = 0
        if type(opts.buffer) ~= 'boolean' then
          b = opts.buffer
        end
        opts.buffer = nil
        vim.api.nvim_buf_set_keymap(b, mode, l, rhs, opts)
      else
        vim.api.nvim_set_keymap(mode, l, rhs, opts)
      end
    end
  end
end

local function bind(source, target, force)
  local force = force or false
  for k, v in pairs(source) do
    if target[k] ~= nil then
      local msg = 'mapx.bind: overwriting key ' .. k .. ' on ' .. string.format('%s', target)
      if force then
        print('warning: ' .. msg .. ' {force = true}')
      else
        error(msg)
      end
    end
    target[k] = v
  end
  return target
end

local function try_require(pkg)
  return pcall(function()
    return require(pkg)
  end)
end

function mapx.globalize(...)
  error("mapx.globalize() has been deprecated; use mapx.setup({ global = true })")
end

function mapx.setup(config)
  if setup then
    return mapx
  end
  local config = config or {}
  mapx = merge(mapx, mapopts)

  if config.whichkey then
    local ok, wk = try_require('which-key')
    if not ok then
      error('mapx.setup: config.whichkey == true but module "which-key" not found')
    end
    whichkey = wk
  end

  if config.global then
    local forceGlobal = false
    if config.global == "force" then
      forceGlobal = true
    end
    bind(fns, _G, forceGlobal)
    globalized = true
  end
  setup = true
  return mapx
end

for _, mode in ipairs {'', 'n', 'v', 'x', 's', 'o', 'i', 'l', 'c', 't'} do
  local m = mode .. 'map'
  local n = mode .. 'noremap'
  fns[m] = _map(mode)
  fns[n] = _map(mode, { noremap = true })
end
fns.mapbang     = _map('!')
fns.noremapbang = _map('!', { noremap = true })

bind(fns, mapx)

return mapx
