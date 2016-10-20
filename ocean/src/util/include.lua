local function locals()
  local locals = {}
  local i = 1
  while true do
    local k, v = debug.getlocal(3, i)
    if k then
      locals[k] = v
    else
      break
    end
    i = 1 + i
  end
  return locals
end

return function(file)
  if file:match('^./') then
    local current_directory = debug.getinfo(2, 'S').source:sub(2):match('(.*/)')
    file = current_directory .. file:match('^./(.+)')
  end
  setfenv(loadfile(file), setmetatable(locals(), {
    __index = getfenv(2)
  }))()
end
