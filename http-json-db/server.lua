local http = require 'coro-http'
local split = require 'coro-split'
local json = require 'json'

local urls = {
  'http://www.foaas.com/this/Everyone',
  'http://www.foaas.com/that/Everyone',
  'http://www.foaas.com/everything/Everyone',
  'http://www.foaas.com/pink/Everyone',
  'http://www.foaas.com/life/Everyone',
  'http://www.foaas.com/thanks/Everyone',
  'http://www.foaas.com/flying/Everyone',
  'http://www.foaas.com/cool/Everyone',
  'http://www.foaas.com/what/Everyone',
  'http://www.foaas.com/because/Everyone',
  'http://www.foaas.com/bye/Everyone',
  'http://www.foaas.com/diabetes/Everyone',
  'http://www.foaas.com/awesome/Everyone',
  'http://www.foaas.com/tucker/Everyone',
  'http://www.foaas.com/mornin/Everyone',
  'http://www.foaas.com/me/Everyone',
  'http://www.foaas.com/single/Everyone',
  'http://www.foaas.com/no/Everyone',
  'http://www.foaas.com/give/Everyone',
  'http://www.foaas.com/zero/Everyone',
  'http://www.foaas.com/sake/Everyone',
  'http://www.foaas.com/maybe/Everyone',
  'http://www.foaas.com/too/Everyone',
  'http://www.foaas.com/horse/Everyone'
}

local function Requester(url)
  return function()
    local _, content = http.request('GET', url, {
      { 'accept', 'application/json' }
    })
    content = json.decode(content)
    return content.message .. ' ' .. content.subtitle
  end
end

coroutine.wrap(function()
  local requesters = {}
  for _, url in ipairs(urls) do
    table.insert(requesters, Requester(url))
  end

  local responses = table.pack(split(table.unpack(requesters)))

  for _, response in ipairs(responses) do
    print(response)
  end
end)()
