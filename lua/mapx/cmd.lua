local cmd = {}

-- public

function cmd.pvimcmd(c)
	local ran, res = pcall(vim.cmd, c)
	if not ran then
		error(res)
	end
end

local function create(self, n, f, a)
	a = a or {}
	local c = ""
	c = c .. self.__header_gen(n, a) .. " "

	local _f = f
	if type(_f) == "table" then
		_f = function(...)
			for _, __f in ipairs(f) do
				__f(unpack(...))
			end
		end
	end

	if type(_f) == "function" then
		self.__cmd[self.__key(n)] = _f
		c = c .. self.__bridge_gen(n, a) .. " "
		for k, tmp in pairs(self) do
			if string.match(k, "tmp$") then
				c = c .. tmp(n, a) .. " "
			end
		end
		c = c .. self.__call_gen(n, a) .. " "
	elseif type(_f) == "string" then
		c = c .. _f .. " "
	else
		print("Wrong command function type for command: " .. n)
		return
	end

	c = self.__body(c)
	self.pvimcmd(c)
end

setmetatable(cmd, { __call = create })

-- private

cmd.__cmd = {}

function cmd.__key(n)
	return n
end

function cmd.__num(n)
	return n
end

function cmd.__range(n, f, l)
	if n == 1 then
		return { line = f }
	elseif n == 2 then
		return { first = f, last = l }
	end

	return {}
end

function cmd.__reg(s)
	return s
end

function cmd.__bang(s)
	return s == "!"
end

function cmd.__count(c)
	if c > 0 then
		return c
	else
		return nil
	end
end

function cmd.__mods(m)
	local o = {}
	for v in string.gmatch(m or "", "%S+") do
		table.insert(o, v)
	end
	return o
end

function cmd.__args(...)
	local r = {}
	for _, v in ipairs({ ... }) do
		table.insert(r, load("return " .. v)())
	end
	return r
end

function cmd.__body(c)
	c = string.gsub(c, "%s+", " ")
	c = string.gsub(c, "^%s+", "")
	c = string.gsub(c, "%s+$", "")
	return c
end

function cmd.__header_gen(n, a)
	local r = ""

	if type(a) == "table" then
		for k, v in pairs(a) do
			if type(v) == "boolean" then
				if v then
					r = r .. " -" .. k
				end
			else
				r = r .. " -" .. k .. "=" .. v
			end
		end
	elseif type(a) == "string" then
		r = a
	else
		print("Wrong type of args for command: " .. n)
	end

	return string.format([[ command! %s %s ]], r, n)
end

function cmd.__bridge_gen(_, _)
	return [[ lua local cmd = require 'user.util.cmd' ]]
end

function cmd.__range_tmp(_, a)
	if a.range then
		return [[
        local range = cmd.__range(
            cmd.__num(<range>), 
            cmd.__num(<line1>),
            cmd.__num(<line2>))
        ]]
	end

	return [[ local range = nil ]]
end

function cmd.__count_tmp(_, a)
	if a.count then
		return [[ local count = cmd.__count(<count>) ]]
	end
	return [[ local count = nil ]]
end

function cmd.__bang_tmp(_, a)
	if a.bang then
		return [[ local bang = cmd.__bang(<bang>) ]]
	end
	return [[ local bang = nil ]]
end

function cmd.__mods_tmp(_, _)
	return [[ local mods = cmd.__mods(<q-mods>) ]]
end

function cmd.__reg_tmp(_, a)
	if a.register then
		return [[ local reg = cmd.__reg(<reg>) ]]
	end
	return [[ local reg = nil ]]
end

function cmd.__args_tmp(_, _)
	return [[ local args = cmd.__args(<f-args>) ]]
end

function cmd.__call_gen(n, _)
	return string.format(
		[[
    local ran, res = pcall(cmd.__cmd["%s"], {
        range = range,
        count = count,
        bang = bang,
        mods = mods,
        reg = reg,
        args = args,
    })
    if not ran then error(res) end
    ]],
		require("user.util.cmd").__key(n)
	)
end

return cmd
