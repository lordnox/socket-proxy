
uuid          = require 'node-uuid'
httpProxy     = require 'http-proxy'
engine        = require 'engine.io'
http          = require 'http'
async         = require 'async'


# debuggin purposes, needs to be cleaned at some pont
{log}         = require './shared'

class Proxy

  constructor: (config) ->

    port      = config.socketPort
    makePort  = (p) -> p || port++

    @socketServerInstance  = http.createServer()
    @proxyServerInstance   = httpProxy.createServer (req, res, proxy) ->
      buffer = httpProxy.buffer req

      urls = Object.keys routing
      urls.sort (a, b) -> b.length - a.length

      path = false

      url = req.url
      console.log urls, url

      urls.some (_path) ->
        return false if _path.length > url.length
        part = url.substr 0, _path.length
        rest = url.substr _path.length - 1
        sign = rest[0]
        return false if _path isnt part
        return false if url.length isnt _path.length and sign isnt '/'
        path = _path

      if not path
        res.writeHead 404,
          'Content-Type': 'text/plain'
        res.write 'not found'
        return res.end()

      req.url = url.substr path.length - 1
      console.log req.url

      request =
        host: 'localhost'
        port: routing[path]
        buffer: buffer

      console.log 'sending proxyrequest to', request.host + ':' + request.port
      proxy.proxyRequest req, res, request

    #@proxyServerInstance.proxy.on 'start', (req, res, target)-> console.log 'start', target
    #@proxyServerInstance.proxy.on 'proxyError', (err, req, res)-> console.log 'proxyError', err

    @socketServer          = engine.attach @socketServerInstance

    @listen = (fn) ->
      async.parallel [
        (cb) => @proxyServerInstance.listen config.port, cb
        (cb) => @socketServerInstance.listen makePort(), cb
      ], fn or ->

    routing = {}

    @socketServer.on 'connection', (socket) ->
      log "Client connected"

      routes = []
      client = socket.transport.sid

      cleanUp = ->
        routes.forEach (route) ->
          delete routing[route]

      send = (data) ->
        socket.send JSON.stringify data

      request = (data) ->
        send
          type: 'request'
          body: data
          uuid: uuid()

      socket.on 'message', (utf8) ->
        data = JSON.parse utf8

        switch data.type
          when 'register'
            log "Client registered route: " + data.path
            routes.push data.path
            routing[data.path] = makePort data.port
            send
              type: 'registered'
              port: routing[data.path]
              uuid: data.uuid or uuid()

      socket.on 'close', ->
        cleanUp()
        log "Client disconnected"

      socket.on 'error', (err) ->
        cleanUp()
        log "Client error", err

module.exports = Proxy
