local au = {}
au.__index = au

-- public

function au:group_begin(group)
  return setmetatable({ group = group, autocmds = {} }, au)
end

function au:cmd(e, p, c, a)
  table.insert(
    self.autocmds,
    { event = e, pattern = p, command = c, args = a or {} }
  )
  return self
end

function au:group_end()
  local g = ""
  g = g .. self:__group_header_gen() .. "\n"

  for i, a in ipairs(self.autocmds) do
    local c = ""
    c = c .. self:__header_gen(i) .. " "

    local f = a.command
    if type(f) == "table" then
      f = function(opt)
        for _, _f in ipairs(a.command) do
          _f(opt)
        end
      end
    end

    if type(f) == "function" then
      self.__au[self:__key(i)] = f
      c = c .. self:__bridge_gen(i) .. " "

      for k, tmp in pairs(getmetatable(self).__index) do
        if string.match(k, "tmp$") then
          c = c .. " " .. tmp(self, i)
        end
      end

      c = c .. self:__call_gen(i) .. " "
    elseif type(f) == "string" then
      c = c .. f .. " "
    else
      error("Wrong type of command for autocmd: " .. vim.inspect(a))
    end

    c = self:__body(c)
    g = g .. "    " .. c .. "\n"
  end

  g = g .. self:__group_footer_gen() .. "\n"
  require("user.util.cmd").pvimcmd(g)

  return self
end

-- private

au.__au = {}

function au:__key(i)
  return self.group .. i
end

function au:__body(c)
  c = string.gsub(c, "%s+", " ")
  c = string.gsub(c, "^%s+", "")
  c = string.gsub(c, "%s+$", "")
  return c
end

function au:__group_header_gen()
  local g = self.group
  return string.format("augroup %s\n    autocmd!", g)
end

function au:__group_footer_gen()
  return [[augroup END]]
end

function au:__header_gen(i)
  local a = self.autocmds[i]
  local e = ""
  local p = ""
  local r = ""

  if type(a.event) == "table" then
    for _, v in ipairs(a.event) do
      e = e .. v .. ","
    end
  elseif type(a.event) == "string" then
    e = a.event
  else
    error("Wrong type of event for autocmd: " .. vim.inspect(a))
  end

  if type(a.pattern) == "table" then
    for _, v in ipairs(a.pattern) do
      p = p .. v .. ","
    end
  elseif type(a.pattern) == "string" then
    p = a.pattern
  else
    error("Wrong type of pattern for autocmd: " .. vim.inspect(a))
  end

  if type(a.args) == "table" then
    for k, v in pairs(a.args) do
      if v then
        r = r .. "++" .. k .. " "
      end
    end
  elseif type(a.args) == "string" then
    r = a.args
  else
    error("Wrong type of args for autocmd: " .. vim.inspect(a))
  end

  return string.format([[ autocmd %s %s %s ]], e, p, r)
end

function au:__bridge_gen(_)
  return [[ lua local au = require 'user.util.autocmd' ]]
end

function au:__buf_tmp(_)
  return " local buf = vim.fn.expand([[<abuf>]]) "
end

function au:__file_tmp(_)
  return " local file = vim.fn.expand([[<afile>]]) "
end

function au:__match_tmp(_)
  return " local match = vim.fn.expand([[<amatch>]]) "
end

function au:__call_gen(i)
  return string.format(
    [[
    local ran, res = pcall(au.__au["%s"], {
        buf = buf,
        file = file,
        match = match,
    })
    if not ran then error(res) end
    ]],
    self:__key(i)
  )
end

return au
