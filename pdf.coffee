# **PDF** module privides helpful utilities for generating PDF files.

exports.loadPDFDocEncoding = (data) ->
  enc = {}
  for l in data.split '\n' when l.length > 0 and l[0] != '#'
    [uc, ec, nm] = l.split ' '
    enc[parseInt(uc, 16)] = [parseInt(ec, 16), nm]
  enc
