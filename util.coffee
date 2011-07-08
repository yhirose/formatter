#!/usr/bin/env coffee

Number::times = (callback) ->
  callback i for i in [0...this]

# vim: et ts=2 sw=2
