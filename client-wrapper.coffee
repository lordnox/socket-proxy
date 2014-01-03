
{config, log} = require './shared'

engine = require 'engine.io-client'

timeout = 500
last_err = null

retry = (timeout, fn) ->
  setTimeout fn, timeout

connect = (app) ->
  socket = engine.Socket 'ws://localhost:' + config.ports.socket
  socket.on 'open', ->
    log "connected"
    app socket

  socket.on 'close', ->
    log "disconnected"

    retry timeout, -> connect app

  socket.on 'error', (err) ->
    if err?.description isnt last_err
      log "Error: ", err
      last_err = err.description

    retry timeout, -> connect app

module.exports = (config, server, fn) ->
  server.on 'listening', fn

  stop = ->
    console.log 'stopping server'
  start = (port) ->
    console.log 'starting server on ' + port
    server.listen port


  connect (socket) ->
    send = (data) -> socket.send JSON.stringify data

    response = (data) ->
      (body) ->
        send
          type: 'response'
          body: body
          uuid: data.uuid

    send
      type: 'register'
      path: config.path
      port: config.port

    socket.on 'message', (utf8) ->
      data = JSON.parse utf8
      console.log data

      switch data.type
        when 'request'
          log "REQUEST VIA SOCKET!"
          #fn data.body, response(data), data, socket
        when 'registered'
          start data.port