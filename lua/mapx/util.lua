local M = {}

-- Flat merge of 2 or more tables, supporting a mixture of map-like tables and
-- list-list tables.
-- - Right-most arguments take precedence.
-- - Numeric indices are extended, not replaced.
-- - No side effects.
function M.merge(...)
  local res = {}
  for i = 1, select('#', ...) do
    local arg = select(i, ...)
    if type(arg) == 'table' then
      for k, v in pairs(arg) do
        if type(k) == 'number' then
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
