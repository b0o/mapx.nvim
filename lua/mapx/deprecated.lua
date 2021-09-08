local log = require'mapx.log'
local M = {}

local deprecated = {
  api = {
    globalize = "use mapx.setup({ global = true }) instead",
  },
  config = {
    quiet = "use mapx.setup({ global = 'skip' }) instead",
  },
}

function M.apply(mapx)
  for key, msg in pairs(deprecated.api) do
    mapx[key] = function()
      log.warn(string.format("mapx.%s has been deprecated: %s", key, msg))
    end
  end
end

function M.checkConfig(config)
  for key, val in pairs(deprecated.config) do
    if config[key] ~= nil then
      local msg = string.format("mapx: config '%s' has been deprecated", key)
      if type(val) == "string" then
        msg = msg .. string.format(": %s", val)
      end
      log.warn(msg)
    end
  end
end

return M
