
fs      = require 'fs'
http    = require 'http'
statik  = require 'node-static'

log = require('debug') 'nx-proxy:static'

class Static
  constructor: (config, fn = ->) ->

    path = fs.realpathSync config.path

    log "creating static server for %s", path
    fileServer = new statik.Server path, config.options || {}

    @httpServer = http.createServer (request, response) ->
      if fn
        try
          fn request, response
        catch error
          log "Error", error
          return
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
