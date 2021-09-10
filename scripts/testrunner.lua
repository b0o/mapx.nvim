_G.expect = {}

function _G.it(desc, fn)
  io.write(" -> It " .. desc .. "...")
  fn()
  print(" OK\n")
end

function expect.compare(op, expected, actual)
  if not op(actual, expected) then
    print(" FAIL\n")
    print("Expected:")
    print(expected)
    print("Actual:")
    print(actual)
    print("\n")
    vim.cmd("cquit")
  end
end

function expect.equal(expected, actual)
  return expect.compare(function(a, b) return a == b end, expected, actual)
end

function expect.notEqual(notExpected, actual)
  return expect.compare(function(a, b) return a ~= b end, notExpected, actual)
end

function expect.notNil(actual)
  return expect.notEqual(nil, actual)
end

function expect.isType(expectedType, actual)
  return expect.equal(expectedType, type(actual))
end

function expect.isBoolean(actual)
  return expect.isType("boolean", actual)
end

function expect.isFunction(actual)
  return expect.isType("function", actual)
end

function expect.isNil(actual)
  return expect.isType("nil", actual)
end

function expect.isNumber(actual)
  return expect.isType("number", actual)
end

function expect.isString(actual)
  return expect.isType("string", actual)
end

function expect.isTable(actual)
  return expect.isType("table", actual)
end

function expect.isThread(actual)
  return expect.isType("thread", actual)
end

function expect.isUserdata(actual)
  return expect.isType("userdata", actual)
end

local function _dofile(file)
  local ok, err = pcall(dofile, file)
  if not ok then
    print(" ERROR\n")
    print(err)
    print("\n")
    vim.cmd("cquit")
  end
end

function _G.loadTestData(file)
  _dofile(vim.g.mapx_root .. "/test/testdata/" .. file .. ".lua")
end

function _G.runTestFile(file)
  _dofile(file)
end
