local timer = require 'timer'
local split = require 'coro-split'

local function coro(f)
  coroutine.wrap(f)()
end

local function time(f)
  local start = os.time()
  f()
  print('time taken: ' .. os.difftime(os.time(), start))
end

coro(function()
  time(function()
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

  time(function()
    local a, b = split(function()
      timer.sleep(1000)
      return 4
    end, function()
      timer.sleep(1000)
      return 5
    end)

    print(a, b)
  end)
end)
