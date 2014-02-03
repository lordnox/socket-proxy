
{config} = require './shared'

engine = require 'engine.io-client'

timeout = 500
last_err = null


log = require('debug') 'nx-proxy:wrapper'

slog = require('debug') 'nx-proxy:socket'

{EventEmitter} = require 'events'

class Socket extends EventEmitter
  constructor: ->
    @stack = []
    @connecting = false
    @connected = false
    @error = null

    # register events for the socket class
    @on 'close', =>
      @emit 'disconnect' if @connected
      slog "disconnected from socket proxy host, going to reconnect now"
      @connected = false
      @reopen()

    @on 'error', (err) =>
      @emit 'disconnect' if @connected
      @connected = false
      @connecting = false
      @reopen err

    @on 'open', =>
      @connected = true
      @connecting = false
      @error = null
      @sendStack()
      slog "connected"

  open: ->
    return if @connecting or @connected

    @connecting = true
    # create a socket
    @socket = engine.Socket 'ws://localhost:' + config.ports.socket
    # connect the important events (not the open-event)
    @init()

  reopen: (err) ->
    if !!err && (err?.description isnt @error)
      slog "Error: ", err
      slog "trying to reconnect"
      @emit 'close', err
      @error = err.description

    setTimeout (=> @open()), timeout

  close: ->

  init: ->
    ['close', 'error', 'message', 'open'].forEach (evt) =>
      @socket.on evt, (arg) => @emit evt, arg

  sendStack: ->
    while @stack.length
      @socket.send.apply @socket, @stack.shift()

  send: (args...) ->
    @stack.push args
    @sendStack() if @connected
    @open() if not @connected


class Wrapper extends EventEmitter
  constructor: (@config, @server) ->
    @server = @server.httpServer if not @server.listen and @server.httpServer
    @socket = new Socket

    @running = false

    @server.on 'listening', =>
      @running = true
      @emit 'listening', @server.address().port

    @on 'packet::registered', (data) =>
      @start data.port

    @on 'packet::request', (data) =>
      res =
        id:   data.id
        type: 'response'
        for:  data.name
      @emit 'request', data.name, (response) =>
        res.data = response
        @send res

    @on 'packet::response', (data) =>
      console.log data
      @emit 'respond::' + data.for, data.id, data.data

    @socket.on 'close', (reason) =>
      @cleanUp "connection closed: " + reason

    @socket.on 'message', (utf8) => @recieve utf8

    @socket.on 'disconnect', =>
      @emit 'reset'

    @socket.on 'open', =>
      @init()

    @socket.open()

  init: ->
    if @config.name or @config.hasOwnProperty 'reroute'
      @send
        type: 'config'
        name: @config.name
        reroute: @config.reroute
    @emit 'init'

    @send
      type: 'register'
      path: @config.path
      port: @config.port

  request: (type, data) ->
    @send
      type: 'request'
      name: type
      data: data

  send: (data) ->
    log "sending a #{data.type}-packet"
    @socket.send JSON.stringify data
  recieve: (utf8) ->
    data = JSON.parse utf8
    log "recieved packet::#{data.type}"
    @emit "packet::#{data.type}", data
  stop: ->
    log 'Stopping server'
    @server.close() if @running
    @running = false
  start: (port) ->
    log 'starting server on ' + port
    @server.listen port
  cleanUp: (msg) ->
    return if not @running
    log 'cleanUp: ' + msg
    @stop()

module.exports = (config, server, fn) ->
  if 'function' is typeof server
    server = require('http').createServer server
  wrapper = new Wrapper config, server
  if fn
    wrapper.on 'listening', fn
  wrapper
