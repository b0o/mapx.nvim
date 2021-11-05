local merge = require('mapx.util').merge
local log = require 'mapx.log'

local dbgi = log.dbgi

local Mapper = {
  mapopts = {
    buffer = { buffer = 0 },
    nowait = { nowait = true },
    silent = { silent = true },
    script = { script = true },
    expr = { expr = true },
    unique = { unique = true },
  },
}

-- Expands string-based options like "buffer", "silent", "expr" to their
-- table-based representation. Also supports <wrapped> strings "<buffer>"
-- Returns a new opts table with this expansion applied.
local function expandStringOpts(opts)
  local res = {}
  for k, v in pairs(opts) do
    if type(k) == 'number' then
      if Mapper.mapopts[v] then
        res[v] = true
        goto continue
      end
      local vsub = type(v) == 'string' and vim.fn.substitute(v, [[^<\|>$]], '', 'g')
      if vsub and Mapper.mapopts[vsub] ~= nil then
        res[vsub] = true
        goto continue
      end
      table.insert(res, v)
    else
      res[k] = v
    end
    ::continue::
  end
  return res
end

function Mapper:normalizeOpts(opts)
  local _opts = vim.deepcopy(opts)
  if _opts[#_opts] ~= nil and Mapper.mapopts[_opts[#_opts]] == nil then
    -- Extract the WhichKey label from the last numeric table element and put
    -- it into the `label` field.
    local label = _opts[#_opts]
    table.remove(_opts, #_opts)
    _opts.label = label
  end
  return _opts
end

function Mapper.new()
  local self = {
    config = {},
    luaFuncs = {},
    filetypeMaps = {},
    groupOpts = {},
    groupActive = false,
    whichkey = nil,
  }
  vim.cmd [[
    augroup mapx_mapper
      au!
      au FileType * lua require'mapx'.mapper:filetype()
    augroup END
  ]]
  return setmetatable(self, { __index = Mapper })
end

function Mapper:setup(config)
  self.config = merge(self.config, config)
  if self.config.whichkey then
    local ok
    ok, self.whichkey = pcall(
      require('mapx.whichkey').new,
      type(self.config.whichkey) == 'table' and self.config.whichkey
    )
    if not ok then
      error('mapx.Map:setup: Unable to set up WhichKey integration: ' .. self.whichkey)
    end
  end
  dbgi('mapx.Map:setup', self)
  return self
end

function Mapper:filetypeMap(fts, fn)
  dbgi('Map.filetype', { fts = fts, fn = fn })
  if type(fts) ~= 'table' then
    fts = { fts }
  end
  for _, ft in ipairs(fts) do
    if self.filetypeMaps[ft] == nil then
      self.filetypeMaps[ft] = {}
    end
    table.insert(self.filetypeMaps[ft], fn)
  end
  dbgi('mapx.Map.filetypeMaps insert', self.filetypeMaps)
end

function Mapper:filetype()
  local ft = vim.fn.expand '<amatch>'
  local buf = tonumber(vim.fn.expand '<abuf>')
  local filetypeMaps = self.filetypeMaps[ft]
  dbgi('mapx.Map:handleFiletype', { ft = ft, buf = buf, ftMaps = filetypeMaps })
  if filetypeMaps == nil then
    return
  end
  for _, fn in ipairs(filetypeMaps) do
    fn(buf)
  end
end

function Mapper:func(id, ...)
  local fn = self.luaFuncs[id]
  if fn == nil then
    return
  end
  return fn(...)
end

function Mapper:registerMap(mode, lhs, rhs, opts)
  if opts.label then
    if self.whichkey then
      local label = opts.label
      opts.label = nil
      local buffer = opts.buffer
      opts.buffer = nil
      self.whichkey:map(mode, buffer, lhs, merge({ rhs, label }, opts))
      return
    end
  elseif opts.buffer then
    local bopts = merge({}, opts)
    bopts.buffer = nil
    dbgi('Mapper:registerMap (buffer)', { mode = mode, lhs = lhs, rhs = rhs, opts = opts, bopts = bopts })
    vim.api.nvim_buf_set_keymap(opts.buffer, mode, lhs, rhs, bopts)
  else
    dbgi('Mapper:registerMap', { mode = mode, lhs = lhs, rhs = rhs, opts = opts })
    vim.api.nvim_set_keymap(mode, lhs, rhs, opts)
  end
end

function Mapper:registerName(mode, lhs, opts)
  if opts.name == nil then
    error 'mapx.name: missing name'
  end
  if self.whichkey then
    dbgi('Mapper:registerName', { mode = mode, lhs = lhs, opts = opts })
    local buffer = opts.buffer
    opts.buffer = nil
    self.whichkey:map(mode, buffer, lhs, { name = opts.name })
    return
  end
end

function Mapper:register(config, lhss, rhs, ...)
  if type(config) ~= 'table' then
    config = { mode = config, type = 'map' }
  end
  local opts = merge(self.groupOpts, ...)
  local ft = opts.filetype or opts.ft
  if ft ~= nil then
    opts.ft = nil
    opts.filetype = nil
    self:filetypeMap(ft, function(buf)
      opts.buffer = buf
      self:register(config, lhss, rhs, opts)
    end)
    return
  end
  opts = expandStringOpts(opts)
  if opts.buffer == true then
    opts.buffer = 0
  end
  opts = self:normalizeOpts(opts)

  if type(lhss) ~= 'table' then
    lhss = { lhss }
  end
  if type(rhs) == 'function' then
    -- TODO: rhs gets inserted multiple times if a filetype mapping is
    -- triggered multiple times
    table.insert(self.luaFuncs, rhs)
    dbgi('state.funcs insert', { luaFuncs = self.luaFuncs })
    local luaexpr = "require'mapx'.mapper:func(" .. #self.luaFuncs .. ', vim.v.count)'
    if opts.expr then
      rhs = 'luaeval("' .. luaexpr .. '")'
    else
      rhs = '<Cmd>lua ' .. luaexpr .. '<Cr>'
    end
  end
  for _, lhs in ipairs(lhss) do
    if config.type == 'map' then
      self:registerMap(config.mode, lhs, rhs, opts)
    elseif config.type == 'name' then
      self:registerName(config.mode, lhs, opts)
    end
  end
end

function Mapper:group(...)
  local prevOpts = self.groupOpts
  local fn
  local args = { ... }
  for i, v in ipairs(args) do
    if i < #args then
      self.groupOpts = merge(self.groupOpts, v)
    else
      fn = v
    end
  end
  self.groupOpts = expandStringOpts(self.groupOpts)
  dbgi('group', self.groupOpts)
  local opts = self:normalizeOpts(self.groupOpts)
  if opts.label ~= nil then
    error('mapx.group: cannot set label on group: ' .. tostring(opts.label))
  end
  local prevGroupActive = self.groupActive
  self.groupActive = true
  fn()
  self.groupActive = prevGroupActive
  self.groupOpts = prevOpts
  if self.groupActive == false and self.whichkey then
    self.whichkey:flush()
  end
end

return Mapper
