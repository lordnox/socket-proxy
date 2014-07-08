
uuid          = require 'node-uuid'
httpProxy     = require 'http-proxy'
engine        = require 'engine.io'
http          = require 'http'
async         = require 'async'

{EventEmitter} = require 'events'

defaults =
  socketPort: 12000
  proxyPort: 8000


# debuggin purposes, needs to be cleaned at some pont
log = require('debug') 'nx-proxy:server'


findMatch = (url, list) ->
  path = false
  list.some (_path) ->
    return false if -1 is url.indexOf _path
    path = _path

  return false if not path

  redirect = url.substr path.length
  redirect = "/" + redirect if redirect[0] isnt "/"

  url: redirect
  path: path


class Client extends EventEmitter
  constructor: (socket, proxy) ->
    log "Client '%s' connected", socket.id
    client = socket.transport.sid

    @name = socket.id
    @reroute = true

    cleanUp = ->
      socket.routes.forEach (route) ->
        delete proxy.routing[route]

    send = (data) ->
      socket.send JSON.stringify data

    request = (data) ->
      send
        type: 'request'
        body: data
        uuid: uuid()

    socket.on 'message', (utf8) =>
      data = JSON.parse utf8

      switch data.type
        when 'register'
          log "Client registered route: " + data.path
          socket.routes.push data.path
          port = proxy.makePort data.port
          proxy.addRoute data.path, @, port
          send
            type: 'registered'
            port: port
            uuid: data.uuid or uuid()

        when 'config'
          ['name', 'reroute'].forEach (property) =>
            return if not data.hasOwnProperty property
            id = @name
            @[property] = data[property]
            log "client '%s' changed property '%s' to '%s'", id, property, data[property]

        when 'request'
          log "client '%s' send request packet", @name
          data.id = socket.id
          proxy.broadcast socket.id, data

        when 'response'
          log "client '%s' responded to '%s'", @name, data.id
          proxy.sendTo data.id, data

    socket.on 'close', ->
      cleanUp()
      log "Client disconnected"

    socket.on 'error', (err) ->
      cleanUp()
      log "Client error", err

class Proxy

  init: ->

  response: (req, res, msg, code) ->
    code  ?= 404
    msg   ?= 'not found'
    if typeof msg is 'string'
      res.writeHead code,
        'Content-Type': 'text/plain'
      res.write 'not found'
    else
      res.writeHead code,
        'Content-Type': 'application/json'
      res.write JSON.stringify msg
    res.end()

  request: (req, res, proxy) =>
    # find redirect target
    redirect  = findMatch req.url, @routingKeys
    # return if not found
    return @response req, res, 'not found' if not redirect
    # get the route
    route = @routing[redirect.path]
    # change the requests url if needed
    req.url = redirect.url or req.url if route.client.reroute
    # build the new request for the internal route
    options =
      target: "http://localhost:#{route.port}"
    # debug
    log "proxying %s>%s", route.client.name, req.url
    # proxy the request
    @proxyServer.web req, res, options
    #proxy.proxyRequest req, res, request

  addRoute: (path, client, port) ->
    @routing[path] =
      client: client
      port  : port
    @routingKeys = Object.keys @routing
    @routingKeys.sort (a, b) -> b.length - a.length

  broadcast: (id, data) ->
    clients = Object.keys(@socketServer.clients).filter (client) -> client isnt id
    return if not clients.length
    log "broadcast '%s' by '%s' to %d clients", data.type or 'unknown', id, clients.length
    clients.forEach (client) =>
      @socketServer.clients[client].send JSON.stringify data

  sendTo: (id, data) ->
    if(@socketServer.clients[id])
      @socketServer.clients[id].send JSON.stringify data

  constructor: (config) ->

    @routing = {}
    @routingKeys = []

    config = config || {}
    config.socketPort ?= defaults.socketPort
    config.port ?= config.proxyPort || defaults.proxyPort

    port      = config.socketPort

    @makePort  = (p) -> p || port++

    @socketServerInstance  = http.createServer()

    @proxyServerInstance   = http.createServer @request

    @proxyServer           = new httpProxy.createProxyServer {}

    @socketServer          = engine.attach @socketServerInstance

    @listen = (fn) =>
      socketPort = @makePort()
      async.parallel [
        (cb) => @proxyServerInstance.listen config.port, cb
        (cb) => @socketServerInstance.listen socketPort, cb
      ], =>
        (fn or ->) @proxyServerInstance.address().port, @socketServerInstance.address().port

    @stop = (fn) =>
      async.parallel [
        (cb) => @proxyServerInstance.stop cb
        (cb) => @socketServerInstance.stop cb
      ], fn or ->

    @socketServer.on 'connection', (socket) =>
      socket.routes = []

      new Client socket, @

      @broadcast socket.id,
        type: 'connected'
        id: socket.id

module.exports = Proxy


