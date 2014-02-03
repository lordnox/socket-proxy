
mock = require '../lib'

describe "proxyquire testing", ->

  test = null

  beforeEach -> test = mock.static test
  afterEach -> test = null

  it "mock node-static for the static proxy", ->

    instance = new test.module
      path: '/'

    test.call.called('nx-proxy:static').should.have.length 1
    instance.should.have.property 'httpServer'
    instance.httpServer.should.be.instanceOf (require 'events').EventEmitter
    test.emitter.address = -> port: 1
    test.emitter.emit 'listening'
    test.call.called('nx-proxy:static').should.have.length 2



