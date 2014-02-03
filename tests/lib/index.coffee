_should = require("chai").should()

`should = _should`
# suger function for testing
###
 @TODO move to seperate file, to be included in all tests
###

mock =
  Call: ->
    current = (call) -> -> current.calls.push call
    current.calls = []
    current.called = (val) ->
      calls = current.calls
      if val
        calls = calls.filter (v) -> val is v
      calls
    current

module.exports = mock

[
  'static'
  'server'
].forEach (key) ->
  mock[key] = require "./mock.#{key}"


