local M = {}

-- Flat merge of 2 or more tables, supporting a mixture of map-like tables and
-- list-list tables.
-- - Right-most arguments take precedence.
-- - Numeric indices are extended, not replaced.
-- - No side effects.
function M.setMerge(...)
  local res = {}
  for i = 1, select('#', ...) do
    local arg = select(i, ...)
    for k, v in pairs(arg) do
      if v then
        res[k] = true
      end
    end
  end
  return res
end

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
        elseif k == 'prefix' then
          res[k] = res[k] ~= nil and res[k] .. v or v
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

-- Wrap all functions into one that calls them all. It passes all the arguments
-- that were passed to the resulting function to the passed functions.
--
-- @vararg funcs function
-- Functions to call in the resulting function.
function M.wrap(...)
  local funcs = { ... }
  return function(...)
    for _, fun in ipairs(funcs) do
      fun(...)
    end
  end
end

return M
