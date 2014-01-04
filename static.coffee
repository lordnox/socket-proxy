{config, log} = require './shared'

http    = require 'http'
statik  = require 'node-static'

class Static
  constructor: (config) ->

    fileServer = new statik.Server config.path

    @httpServer = http.createServer (request, response) ->
      console.log request.url
      request.addListener('end', ->
        fileServer.serve request, response, (e, rsp) ->
          if (e && e.status is 404)
            response.writeHead e.status, e.headers
            response.end "notFound"
      ).resume()

    @listen = (port, fn) ->
      @httpServer.listen port, fn

module.exports = Static
