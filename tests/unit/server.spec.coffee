mock = require '../lib'

describe "server", ->

  describe.only "basic", ->

    test = null;

    beforeEach ->
      test =
        config:
          socketPort: 1
          proxyPort: 2

      test.http = require 'http'

      test.httpProxy = require 'http-proxy'


      test = mock.server test

    it.only "should not throw an exception when no configuration is given", ->

      test.config = null

      server = new test.module test.config
      server.routing.should.be.an.Array
      server.routing.should.be.empty

      server.should.have.property 'socketServerInstance'
      server.should.have.property 'proxyServerInstance'

    it "should have a listen-method that starts both servers", ->
      server = new test.module test.config
      server.should.have.property "listen"
      server.listen.should.be.a.function

      server.listen test.call 'done'

      test.call.called().should.have.length 3
      test.call.called('socketServerInstance').should.have.length 1
      test.call.called('proxyServerInstance').should.have.length 1
      test.call.called('done').should.have.length 1

      server.stop test.call 'done'
      test.call.called().should.have.length 6
      test.call.called('socketServerInstance').should.have.length 2
      test.call.called('proxyServerInstance').should.have.length 2
      test.call.called('done').should.have.length 2

    it "should have killed the server", ->
      server = new test.module test.config
      server.listen()

    it "should respond to connections on the socket", ->


