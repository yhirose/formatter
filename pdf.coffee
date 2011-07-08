# **PDF** module privides helpful utilities for generating PDF files.

# Loads PDFDocEncoding text database.
exports.loadPDFDocEncoding = (data) ->
  enc = {}
  for l in data.split '\n' when l.length > 0 and l[0] != '#'
    [uc, ec, nm] = l.split ' '
    enc[parseInt(uc, 16)] = [parseInt(ec, 16), nm]
  enc

# Escapes '(' and ')' characters
encodePDFText = (s) ->
  s.replace /([()])/g, -> '\\' + RegExp.$1

