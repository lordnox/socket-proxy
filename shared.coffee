
moment = require 'moment'

module.exports =
  config:
    ports:
      proxy: 6660
      socket: 12000

  log: (args...) ->
    args.unshift moment().format "HH:mm:ss"
    console.log.apply @, args
