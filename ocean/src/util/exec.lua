local spawn = require 'coro-spawn'

return function(command)
  local cmd, rest = command:match('(%S+)%s(.+)')
  local args = {}
  for arg in rest:gmatch('%S+') do
    table.insert(args, arg)
  end
  spawn(cmd, { args = args }).waitExit()
end
