local timer = require 'timer'

local coro = function(f)
  coroutine.wrap(f)()
end

coro(function()
  local x = (function()
    timer.sleep(1000)
    return 4
  end)()

  local y = (function()
    timer.sleep(1000)
    return 5
  end)()

  print(x, y)
end)
