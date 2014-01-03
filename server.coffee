
{config, log} = require './shared'

uuid          = require 'node-uuid'
httpProxy     = require 'http-proxy'
engine        = require 'engine.io'
socketServer  = engine.listen config.ports.socket, -> log "Server startet on port " + config.ports.socket

routing = {}

port = config.ports.socket
makePort = (p) -> p || ++port


proxyServer = httpProxy.createServer (req, res, proxy) ->
  buffer = httpProxy.buffer req

  urls = Object.keys routing
  urls.sort (a, b) -> b.length - a.length

  path = false

  url = req.url
  console.log urls, url

  urls.some (_path) ->
    return false if _path.length > url.length
    rest = url.substr _path.length
    sign = rest[0]
    return false if url.length isnt path.length and sign isnt '/'
    part = url.substr 0, _path.length
    return false if _path isnt part
    path = _path

  if not path
    res.writeHead 404,
      'Content-Type': 'text/plain'
    res.write 'not found'
    return res.end()

  req.url = url.substr path.length

  proxy.proxyRequest req, res,
    host: '127.0.0.1'
    port: routing[path]
    buffer: buffer

proxyServer.listen config.ports.proxy, -> "Proxy-Server started on port " + config.ports.proxy

socketServer.on 'connection', (socket) ->
  client = socket.transport.sid

  send = (data) ->
    log data
    socket.send JSON.stringify data

  request = (data) ->
    send
      type: 'request'
      body: data
      uuid: uuid()

  socket.on 'message', (utf8) ->
    data = JSON.parse utf8
    log data

    switch data.type
      when 'register'
        routing[data.path] = makePort data.port
        send
          type: 'registered'
          port: routing[data.path]
          uuid: data.uuid or uuid()

  socket.on 'close', ->
    log "Client disconnected"

  socket.on 'error', (err) ->
    log "Client error", err
