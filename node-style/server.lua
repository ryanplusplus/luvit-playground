local http = require('http')

http.createServer(function (req, res)
  local body = "Hello world\n"
  res:setHeader("Content-Type", "text/plain")
  res:setHeader("Content-Length", #body)
  res:finish(body)
end):listen(1337, '127.0.0.1')

print('Server running at http://127.0.0.1:1337/')
