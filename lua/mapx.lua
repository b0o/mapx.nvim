local Mapper = require 'mapx.mapper'
local log = require 'mapx.log'
local merge = require('mapx.util').merge
local deprecated = require 'mapx.deprecated'

local dbgi = log.dbgi

local function globalize(mapx, opt)
  local mapFuncs = {}
  for _, mode in ipairs { '', 'n', 'v', 'x', 's', 'o', 'i', 'l', 'c', 't' } do
    local m = mode .. 'map'
    local n = mode .. 'noremap'
    mapFuncs[m] = mapx[m]
    mapFuncs[n] = mapx[n]
  end
  mapFuncs.mapbang = mapx.mapbang
  mapFuncs.noremapbang = mapx.noremapbang
  for k, v in pairs(mapFuncs) do
    if _G[k] ~= nil then
      if opt ~= 'force' then
        if opt == 'skip' then
          goto continue
        end
        log.warn(
          'mapx.global: name conflict: "'
            .. k
            .. '" exists in global scope. Use { global = "force" } or { global = "skip" }.'
        )
        break
      end
    end
    _G[k] = v
    ::continue::
  end
end

local mapx = merge({
  config = {
    debug = false,
    global = false,
    whichkey = false,
  },
  globalized = false,
  mapper = Mapper.new(),
}, Mapper.mapopts)

deprecated.apply(mapx)

-- Configure mapx
function mapx.setup(config)
  mapx.config = merge(mapx.config, config or {})
  log.debug = mapx.config.debug or false
  mapx.mapper:setup { whichkey = mapx.config.whichkey }
  if mapx.config.global then
    globalize(mapx, type(mapx.config.global) == 'string' and mapx.config.global)
    mapx.globalized = true
  end
  deprecated.checkConfig(mapx.config)
  mapx.setup = true
  dbgi('setup', mapx)
  return mapx
end

-- Create a mapx group
-- @vararg opts  string|table Map options
-- @param  fn    function     Function with map definitions
function mapx.group(...)
  return mapx.mapper:group(...)
end

-- Create a Normal, Visual, Select, and Operator-pending mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.map(lhs, rhs, ...)
  return mapx.mapper:register('', lhs, rhs, ...)
end

-- Create a Normal mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.nmap(lhs, rhs, ...)
  return mapx.mapper:register('n', lhs, rhs, ...)
end

-- Create a Normal and Command mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.mapbang(lhs, rhs, ...)
  return mapx.mapper:register('!', lhs, rhs, ...)
end

-- Create a Visual and Select mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.vmap(lhs, rhs, ...)
  return mapx.mapper:register('v', lhs, rhs, ...)
end

-- Create a Visual mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.xmap(lhs, rhs, ...)
  return mapx.mapper:register('x', lhs, rhs, ...)
end

-- Create a Select mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.smap(lhs, rhs, ...)
  return mapx.mapper:register('s', lhs, rhs, ...)
end

-- Create an Operator-pending mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.omap(lhs, rhs, ...)
  return mapx.mapper:register('o', lhs, rhs, ...)
end

-- Create an Insert mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.imap(lhs, rhs, ...)
  return mapx.mapper:register('i', lhs, rhs, ...)
end

-- Create an Insert, Command, and Lang-arg mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.lmap(lhs, rhs, ...)
  return mapx.mapper:register('l', lhs, rhs, ...)
end

-- Create a Command mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.cmap(lhs, rhs, ...)
  return mapx.mapper:register('c', lhs, rhs, ...)
end

-- Create a Terminal mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.tmap(lhs, rhs, ...)
  return mapx.mapper:register('t', lhs, rhs, ...)
end

-- Create a non-recursive Normal, Visual, Select, and Operator-pending mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.noremap(lhs, rhs, ...)
  return mapx.mapper:register('', lhs, rhs, { noremap = true }, ...)
end

-- Create a non-recursive Normal mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.nnoremap(lhs, rhs, ...)
  return mapx.mapper:register('n', lhs, rhs, { noremap = true }, ...)
end

-- Create a non-recursive Normal and Command mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.noremapbang(lhs, rhs, ...)
  return mapx.mapper:register('!', lhs, rhs, { noremap = true }, ...)
end

-- Create a non-recursive Visual and Select mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.vnoremap(lhs, rhs, ...)
  return mapx.mapper:register('v', lhs, rhs, { noremap = true }, ...)
end

-- Create a non-recursive Visual mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.xnoremap(lhs, rhs, ...)
  return mapx.mapper:register('x', lhs, rhs, { noremap = true }, ...)
end

-- Create a non-recursive Select mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.snoremap(lhs, rhs, ...)
  return mapx.mapper:register('s', lhs, rhs, { noremap = true }, ...)
end

-- Create a non-recursive Operator-pending mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.onoremap(lhs, rhs, ...)
  return mapx.mapper:register('o', lhs, rhs, { noremap = true }, ...)
end

-- Create a non-recursive Insert mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.inoremap(lhs, rhs, ...)
  return mapx.mapper:register('i', lhs, rhs, { noremap = true }, ...)
end

-- Create a non-recursive Insert, Command, and Lang-arg mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.lnoremap(lhs, rhs, ...)
  return mapx.mapper:register('l', lhs, rhs, { noremap = true }, ...)
end

-- Create a non-recursive Command mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.cnoremap(lhs, rhs, ...)
  return mapx.mapper:register('c', lhs, rhs, { noremap = true }, ...)
end

-- Create a non-recursive Terminal mode mapping
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  rhs   string       Right-hand side of map
-- @vararg opts  string|table Map options
-- @param  label string       Optional label for which-key.nvim
function mapx.tnoremap(lhs, rhs, ...)
  return mapx.mapper:register('t', lhs, rhs, { noremap = true }, ...)
end

-- Specify a which-key group name for {lhs} in Normal, Visual, Select, and Operator-pending mode
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  name  string       Which-key name
-- @vararg opts  string|table Map options such as { buffer } or { filetype }.
function mapx.name(lhs, name, ...)
  return mapx.mapper:register({ mode = '', type = 'name' }, lhs, nil, { name = name }, ...)
end

-- Specify a which-key group name for {lhs} in Normal mode
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  name  string       Which-key name
-- @vararg opts  string|table Map options such as { buffer } or { filetype }.
function mapx.nname(lhs, name, ...)
  return mapx.mapper:register({ mode = 'n', type = 'name' }, lhs, nil, { name = name }, ...)
end

-- Specify a which-key group name for {lhs} in Normal and Command mode
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  name  string       Which-key name
-- @vararg opts  string|table Map options such as { buffer } or { filetype }.
function mapx.namebang(lhs, name, ...)
  return mapx.mapper:register({ mode = '!', type = 'name' }, lhs, nil, { name = name }, ...)
end

-- Specify a which-key group name for {lhs} in Visual and Select mode
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  name  string       Which-key name
-- @vararg opts  string|table Map options such as { buffer } or { filetype }.
function mapx.vname(lhs, name, ...)
  return mapx.mapper:register({ mode = 'v', type = 'name' }, lhs, nil, { name = name }, ...)
end

-- Specify a which-key group name for {lhs} in Visual mode
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  name  string       Which-key name
-- @vararg opts  string|table Map options such as { buffer } or { filetype }.
function mapx.xname(lhs, name, ...)
  return mapx.mapper:register({ mode = 'x', type = 'name' }, lhs, nil, { name = name }, ...)
end

-- Specify a which-key group name for {lhs} in Select mode
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  name  string       Which-key name
-- @vararg opts  string|table Map options such as { buffer } or { filetype }.
function mapx.sname(lhs, name, ...)
  return mapx.mapper:register({ mode = 's', type = 'name' }, lhs, nil, { name = name }, ...)
end

-- Specify a which-key group name for {lhs} inn Operator-pending mode
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  name  string       Which-key name
-- @vararg opts  string|table Map options such as { buffer } or { filetype }.
function mapx.oname(lhs, name, ...)
  return mapx.mapper:register({ mode = 'o', type = 'name' }, lhs, nil, { name = name }, ...)
end

-- Specify a which-key group name for {lhs} inn Insert mode
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  name  string       Which-key name
-- @vararg opts  string|table Map options such as { buffer } or { filetype }.
function mapx.iname(lhs, name, ...)
  return mapx.mapper:register({ mode = 'i', type = 'name' }, lhs, nil, { name = name }, ...)
end

-- Specify a which-key group name for {lhs} inn Insert, Command, and Lang-arg mode
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  name  string       Which-key name
-- @vararg opts  string|table Map options such as { buffer } or { filetype }.
function mapx.lname(lhs, name, ...)
  return mapx.mapper:register({ mode = 'l', type = 'name' }, lhs, nil, { name = name }, ...)
end

-- Specify a which-key group name for {lhs} in Command mode
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  name  string       Which-key name
-- @vararg opts  string|table Map options such as { buffer } or { filetype }.
function mapx.cname(lhs, name, ...)
  return mapx.mapper:register({ mode = 'c', type = 'name' }, lhs, nil, { name = name }, ...)
end

-- Specify a which-key group name for {lhs} in Terminal mode
-- @param  lhs   string|table Left-hand side(s) of map
-- @param  name  string       Which-key name
-- @vararg opts  string|table Map options such as { buffer } or { filetype }.
function mapx.tname(lhs, name, ...)
  return mapx.mapper:register({ mode = 't', type = 'name' }, lhs, nil, { name = name }, ...)
end

return mapx
