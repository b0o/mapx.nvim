it('creates commands', function()
  local mapx = require 'mapx'
  mapx.setup { global = true }
  expect.notNil(cmd)
  local cmd = mapx.cmd
  local cmdbang = mapx.cmdbang

  local var = nil

  -- option test
  cmd('SetVar', function(opt)
    if opt.register ~= '' then
      var = opt.register
    elseif #opt.modifiers > 0 then
      var = opt.modifiers[1]
    elseif opt.bang then
      var = nil
    elseif not var and #opt.arguments > 0 then
      var = opt.arguments[1]
    elseif not var and opt.count > 0 then
      var = opt.count
    end
  end, {
    nargs = '?',
    count = true,
    register = true,
  }, {
    bang = true,
  }, {})

  vim.cmd [[SetVar 1]]
  expect.equal(1, var)

  vim.cmd [[2SetVar]]
  expect.equal(1, var)

  vim.cmd [[SetVar!]]
  expect.equal(nil, var)

  vim.cmd [[2SetVar]]
  expect.equal(2, var)

  vim.cmd [[vertical SetVar]]
  expect.equal('vertical', var)

  vim.cmd [[SetVar x]]
  expect.equal('x', var)

  -- function table test
  cmdbang('SetVar', {
    function(opt)
      if opt.register ~= '' then
        var = opt.register
      end
    end,
    function(opt)
      if #opt.modifiers > 0 then
        var = opt.modifiers[1]
      end
    end,
  }, {
    nargs = 0,
  }, {
    register = true,
  })

  vim.cmd [[belowright SetVar]]
  expect.equal('belowright', var)

  vim.cmd [[SetVar a]]
  expect.equal('a', var)

  -- function Vim command string test
  vim.g.var = nil

  cmdbang('SetVar', 'let g:var = <q-reg>', {
    nargs = 0,
    register = true,
  })

  vim.cmd [[SetVar b]]
  expect.equal('b', vim.g.var)
end)
