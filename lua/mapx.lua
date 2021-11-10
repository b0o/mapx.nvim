local Mapper = require 'mapx.mapper'
local log = require 'mapx.log'
local merge = require('mapx.util').merge
local wrap = require('mapx.util').wrap
local deprecated = require 'mapx.deprecated'
local cmd = require 'mapx.cmd'

local dbgi = log.dbgi

local function globalize(mapx, opt)
  local funcs = {}
  for _, mode in ipairs { '', 'n', 'v', 'x', 's', 'o', 'i', 'l', 'c', 't' } do
    local m = mode .. 'map'
    local n = mode .. 'noremap'
    funcs[m] = mapx[m]
    funcs[n] = mapx[n]
  end
  funcs.mapbang = mapx.mapbang
  funcs.noremapbang = mapx.noremapbang
  funcs.cmd = mapx.cmd
  funcs.cmdbang = mapx.cmdbang
  for k, v in pairs(funcs) do
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

-- Specify a Vim command
--
-- @param  name string
-- Name of the command
--
-- @param  fun string|function|table
-- Vim command string or Lua function or table of functions.
--
-- If using Lua, the function(s) will be passed a single argument as table
-- of all the options the user passed to the command such as arguments,
-- modifiers and the bang character.
-- Each of the options can be nil depending on if the user passed the option or
-- if the command supports the option.
-- The options "arguments" and "modifiers" are never nil and are empty tables
-- if the user passes none.
-- Note that the range and count options are mutually exclusive because the
-- commands in Vim can't accept both at the same time.
--
-- The possible keys and values of options are:
--
-- - arguments: table - arguments passed through the command line which are
--                      evaluated once using the Lua load function
--
-- - modifiers: table - modifiers passed through the command line such as
--                      "vertical" and "rightbelow"
--
-- - register: string - if the command was not created with the "register"
--                      attribute then this is always nil, otherwise it is the
--                      name of the register the user passed to the command and
--                      an empty string if the user did not pass a register to
--                      the command
--
-- - range: table     - if the command was not created with the "range" attribute
--                      then this is always nil, otherwise if the user selected a
--                      range of lines the keys "first" and "last" will contain
--                      the numbers of first and last line of the range, else if
--                      the user passed a line number on the command line the key
--                      "line" will be set to the number of the line, else the
--                      range will be an empty object
--
-- - count: number    - if the command was not created with the "count" attribute
--                      or if the user did not pass a count on the command line
--                      than this is nil, otherwise this is  the number the user
--                      passed to the command on the commandline
--
-- - bang: boolean    - if the command was not created with the "bang" attribute
--                      then this is always nil, otherwise if the user passed the
--                      bang on the command line then this will be true, and if
--                      the user executed this command without the bang, this will
--                      be false
--
-- @vararg attr table
-- A table of Vim command attributes such as "nargs" and "complete".
-- Attributes such as "bang" just have to be set to true, while attributes such
-- as "nargs" and "complete" take string arguments.
-- Note that the "range" and "count" attributes are mutually exclusive because the
-- commands in Vim can't accept both at the same time.
--
-- @see See the result of ":help :command" for more information.
function mapx.cmd(name, fun, ...)
  local new_fun = fun

  if type(fun) == 'table' then
    new_fun = wrap(unpack(fun))
  end

  cmd(name, "", new_fun, merge(...))
end

-- Specify a Vim command with a bang
--
-- @param  name string
-- Name of the command
--
-- @param  fun string|function|table
-- Vim command string or Lua function or table of functions.
--
-- If using Lua, the function(s) will be passed a single argument as table
-- of all the options the user passed to the command such as arguments,
-- modifiers and the bang character.
-- Each of the options can be nil depending on if the user passed the option or
-- if the command supports the option.
-- The options "arguments" and "modifiers" are never nil and are empty tables
-- if the user passes none.
-- Note that the range and count options are mutually exclusive because the
-- commands in Vim can't accept both at the same time.
--
-- The possible keys and values of options are:
--
-- - arguments: table - arguments passed through the command line which are
--                      evaluated once using the Lua load function
--
-- - modifiers: table - modifiers passed through the command line such as
--                      "vertical" and "rightbelow"
--
-- - register: string - if the command was not created with the "register"
--                      attribute then this is always nil, otherwise it is the
--                      name of the register the user passed to the command and
--                      an empty string if the user did not pass a register to
--                      the command
--
-- - range: table     - if the command was not created with the "range" attribute
--                      then this is always nil, otherwise if the user selected a
--                      range of lines the keys "first" and "last" will contain
--                      the numbers of first and last line of the range, else if
--                      the user passed a line number on the command line the key
--                      "line" will be set to the number of the line, else the
--                      range will be an empty object
--
-- - count: number    - if the command was not created with the "count" attribute
--                      or if the user did not pass a count on the command line
--                      than this is nil, otherwise this is  the number the user
--                      passed to the command on the commandline
--
-- - bang: boolean    - if the command was not created with the "bang" attribute
--                      then this is always nil, otherwise if the user passed the
--                      bang on the command line then this will be true, and if
--                      the user executed this command without the bang, this will
--                      be false
--
-- @vararg attr table
-- A table of Vim command attributes such as "nargs" and "complete".
-- Attributes such as "bang" just have to be set to true, while attributes such
-- as "nargs" and "complete" take string arguments.
-- Note that the "range" and "count" attributes are mutually exclusive because the
-- commands in Vim can't accept both at the same time.
--
-- @see See the result of ":help :command" for more information.
function mapx.cmdbang(name, fun, ...)
  local new_fun = fun

  if type(fun) == 'table' then
    new_fun = wrap(unpack(fun))
  end

  cmd(name, "!", new_fun, merge(...))
end

return mapx
