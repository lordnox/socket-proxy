http    = require 'http'
statik  = require 'node-static'

log = require('debug') 'nx-proxy:static'

class Static
  constructor: (config) ->
    log "creating static server for %s", config.path
    fileServer = new statik.Server config.path

    @httpServer = http.createServer (request, response) ->
      log request.url
      request.addListener('end', ->
        fileServer.serve request, response, (e, rsp) ->
          if (e && e.status is 404)
            response.writeHead e.status, e.headers
            response.end "notFound"
      ).resume()

    @httpServer.on 'listening', =>
      log "started on %d", @httpServer.address().port

module.exports = Static
