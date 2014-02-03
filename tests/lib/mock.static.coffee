
mock = require "./"

{EventEmitter} = require 'events'
proxyquire = require 'proxyquire'

module.exports = (test) ->
  test = test || {}
  test.call = mock.Call()

  test.statik = test.statik ||
    Server: test.Server || test.call 'Server'

  test.emitter = new EventEmitter

  test.http = test.http ||
    createServer: (fn) ->
      test.emitter

  test.module = proxyquire.noCallThru() "../../src/static.coffee",
    "node-static" : test.statik
    "http"        : test.http
    "debug"       : (type) -> test.call type

  test

