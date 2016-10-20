return function(file)
  if file:match('^./') then
    local current_directory = debug.getinfo(2, 'S').source:sub(2):match('(.*/)')
    file = current_directory .. file:match('^./(.+)')
  end
  setfenv(loadfile(file), getfenv(2))()
end
