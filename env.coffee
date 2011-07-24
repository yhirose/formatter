# **Env** module privides OS dependent functionaliteis.

# Exports 'fs' module in node.js.
exports.fs = require 'fs'

# Exports 'process.argv' in node.js.
exports.args = process.argv

# Exports stdin functions
exports.stdin =
  # Read data from stdin with encoding.
  read: (enc, callback) ->
    process.stdin.resume()
    process.stdin.setEncoding enc
    process.stdin.on 'data', callback

# Reads data from file or stdin.
exports.readFileOrStdin = (path, enc, callback) ->
  if typeof path is 'string'
    exports.fs.readFile path, enc, (err, data) ->
      callback data
  else
    exports.stdin.read enc, callback

# Prints data. This is alias to 'console.log' in node.js.
exports.print = console.log
