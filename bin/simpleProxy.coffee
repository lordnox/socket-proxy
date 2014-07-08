#!/usr/bin/env coffee

program       = require 'commander'
{config, log, toPort} = require '../src/shared'

debug = require('debug') 'nx-proxy:bin:server'

program
  .version('0.0.1')
  .option('-p, --port <n>', 'port used for the proxy', toPort)
  .option('-P, --socket-port <n>', 'port used as the internal socket server', toPort)
  .option('-i, --ip <n>', 'ip to redirect traffic to')
  .parse(process.argv);

program.port        ?= config.ports.proxy
program.socketPort  ?= config.ports.socket
program.ip          ?= 'localhost'

console.log(program)

httpProxy = require 'http-proxy'
http = require 'http'

server = new httpProxy.createProxyServer {}


proxyServer = http.createServer (req, res) ->
  # debug
  console.log "proxying %s", req.url
  # proxy the request
  options =
    target: "http://#{program.ip}:#{program.socketPort}"

  req.headers.host = "#{program.ip}:#{program.socketPort}"

  console.log req.headers

  server.web req, res, options

proxyServer.listen program.port
