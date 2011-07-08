#!/usr/bin/env coffee

# **Env** module privides OS dependent functionaliteis.

exports.fs = require 'fs'

exports.args = process.argv

exports.stdin =
  read: (enc, callback) ->
    process.stdin.resume()
    process.stdin.setEncoding enc
    process.stdin.on 'data', callback

exports.readFileOrStdin = (path, enc, callback) ->
  if path
    exports.fs.readFile path, enc, (err, data) ->
      callback data
  else
    exports.stdin.read enc, callback

exports.print = console.log

# vim: et ts=2 sw=2
