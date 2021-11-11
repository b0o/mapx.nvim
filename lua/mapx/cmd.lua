local cmd = {}

-- public

local function create(self, name, bang, fun, args)
  args = args or {}
  local cmd_str = ''
  cmd_str = cmd_str .. self.__generate_header(name, bang, args) .. ' '

  if type(fun) == 'function' then
    self.__storage[self.__key(name)] = fun
    cmd_str = cmd_str .. self.__generate_brigde(name, args) .. ' '
    for mem_name, __template in pairs(self) do
      if string.match(mem_name, 'template$') then
        cmd_str = cmd_str .. __template(name, args) .. ' '
      end
    end
    cmd_str = cmd_str .. self.__generate_call(name, args) .. ' '
  elseif type(fun) == 'string' then
    cmd_str = cmd_str .. fun .. ' '
  else
    error('Wrong command function type for command: ' .. name)
    return
  end

  cmd_str = self.__normalize(cmd_str)
  vim.cmd(cmd_str)
end

cmd = setmetatable(cmd, { __call = create })

-- private

cmd.__storage = {}

function cmd.__key(name)
  return name
end

function cmd.__num(value)
  return value
end

function cmd.__range(number, first, last)
  if number == 1 then
    return { line = first }
  elseif number == 2 then
    return { first = first, last = last }
  end

  return {}
end

function cmd.__register(value)
  return value
end

function cmd.__bang(value)
  return value == '!'
end

function cmd.__count(value)
  if value > 0 then
    return value
  else
    return nil
  end
end

function cmd.__modifiers(value)
  local mod_obj = {}
  for mod in string.gmatch(value or '', '%S+') do
    table.insert(mod_obj, mod)
  end
  return mod_obj
end

function cmd.__arguments(...)
  local arg_obj = {}
  for _, arg in ipairs { ... } do
    table.insert(arg_obj, load('return ' .. arg)())
  end
  return arg_obj
end

function cmd.__normalize(cmd_str)
  cmd_str = string.gsub(cmd_str, '%s+', ' ')
  cmd_str = string.gsub(cmd_str, '^%s+', '')
  cmd_str = string.gsub(cmd_str, '%s+$', '')
  return cmd_str
end

function cmd.__generate_header(name, bang, args)
  local header = ''

  if type(args) == 'table' then
    for arg_name, arg_val in pairs(args) do
      if type(arg_val) == 'boolean' then
        if arg_val then
          header = header .. ' -' .. arg_name
        end
      else
        header = header .. ' -' .. arg_name .. '=' .. arg_val
      end
    end
  elseif type(args) == 'string' then
    header = args
  else
    error('Wrong type of args for command: ' .. name)
  end

  return string.format([[ command%s %s %s ]], bang, header, name)
end

function cmd.__generate_brigde(_, _)
  return [[ lua local cmd = require 'mapx.cmd' ]]
end

function cmd.__range_template(_, args)
  if args.range then
    return [[
        local range = cmd.__range(
            cmd.__number(<range>),
            cmd.__number(<line1>),
            cmd.__number(<line2>))
        ]]
  end

  return [[ local range = nil ]]
end

function cmd.__count_template(_, args)
  if args.count then
    return [[ local count = cmd.__count(<count>) ]]
  end
  return [[ local count = nil ]]
end

function cmd.__bang_template(_, args)
  if args.bang then
    return [[ local bang = cmd.__bang(<q-bang>) ]]
  end
  return [[ local bang = nil ]]
end

function cmd.__modifier_template(_, _)
  return [[ local modifiers = cmd.__modifiers(<q-mods>) ]]
end

function cmd.__register_template(_, args)
  if args.register then
    return [[ local register = cmd.__register(<q-reg>) ]]
  end
  return [[ local register = nil ]]
end

function cmd.__arguments_template(_, _)
  return [[ local arguments = cmd.__arguments(<f-args>) ]]
end

function cmd.__generate_call(name, _)
  return string.format(
    [[
    cmd.__storage["%s"] {
        range = range,
        count = count,
        bang = bang,
        modifiers = modifiers,
        register = register,
        arguments = arguments,
    }
    ]],
    cmd.__key(name)
  )
end

return cmd
