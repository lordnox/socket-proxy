
wrapper = require './client-wrapper'

http = require 'http'

config =
  path: '/test',
  port: 8000

server = http.createServer (req, res) ->
  res.writeHead 200,
    'Content-Type': 'text/plain'
  res.write 'request successfully proxied: ' + req.url + '\n' + JSON.stringify(req.headers, true, 2)

  res.end()

wrapper config, server, ->
  console.log "server is listening now %d", server.address().port
