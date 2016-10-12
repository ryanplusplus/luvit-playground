local timer = require 'timer'

local function coro(f)
  coroutine.wrap(f)()
end

local function node_style(a, b, callback)
  timer.sleep(1000)
  callback(a, b)
end

local function denodify(f)
  return function(...)
    local args = table.pack(...)
    local thread = coroutine.running()
    table.insert(args, function(...)
      assert(coroutine.resume(thread, ...))
    end)
    coro(function()
      f(table.unpack(args))
    end)
    return coroutine.yield()
  end
end

local coro_style = denodify(node_style)

coro(function()
  local a, b = coro_style(4, 5)
  print(a, b)
end)
