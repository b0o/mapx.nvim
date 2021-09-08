local M = {}

function M.merge(...)
  local res = {}
  for i = 1, select('#', ...) do
    local arg = select(i, ...)
    if type(arg) == 'table' then
      for k, v in pairs(arg) do
        if type(k) == "number" then
          table.insert(res, v)
        else
          res[k] = v
        end
      end
    else
      table.insert(res, arg)
    end
  end
  return res
end

return M
