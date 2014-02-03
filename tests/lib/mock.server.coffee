
mock = require "./"

{EventEmitter} = require 'events'
proxyquire = require 'proxyquire'

module.exports = (test) ->
  test = test || {}
  test.call = mock.Call()
  test.uuid = '0001'

  mocks =
    "node-uuid"   : -> test.uuid

  mocks.http = test.http if test.hasOwnProperty "http"
  mocks["http-proxy"] = test.httpProxy if test.hasOwnProperty "httpProxy"

  test.module = proxyquire.noCallThru() "../../src/server.coffee", mocks

  test

