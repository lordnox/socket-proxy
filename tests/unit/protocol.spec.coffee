mock = require '../lib'

describe "protocol", ->

  describe "should not fail, but skip the failing test!", ->
    it "should print text!", ->
      "TEST".should.be.equal "TEST"

