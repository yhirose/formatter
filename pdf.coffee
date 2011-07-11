# **PDF** module privides helpful utilities for generating PDF files.

# Loads Unicode character map database.
exports.loadUnicodeCharMap = (data) ->
  cmap = {}
  for l in data.split '\n' when l.length > 0 and l[0] != '#'
    [uc, ec, nm] = l.split ' '
    cmap[parseInt(uc, 16)] = [parseInt(ec, 16), nm]
  cmap

# Escapes '(' and ')' characters
encodePDFText = (s) ->
  s.replace /([()])/g, -> '\\' + RegExp.$1

