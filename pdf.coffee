# **PDF** module privides helpful utilities for generating PDF files.

# Loads **Unicode to target encoding character** map database.
# The data consists of tab delimited lines.
#     Unicode [Tab] Target encoding code [Tab] Adobe Postscript glyph name
exports.loadUnicodeCharMap = (data) ->
  cmap = {}
  for l in data.split '\n' when l.length > 0 and l[0] != '#'
    [uc, ec, nm] = l.split ' '
    cmap[parseInt(uc, 16)] = [parseInt(ec, 16), nm]
  cmap

