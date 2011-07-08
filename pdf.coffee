#!/usr/bin/env coffee

# **PDF** module privides helpful utilities for generating PDF files.

exports.load_pdfdoc_enc = (data) ->
  enc = {}
  for l in data.split '\n' when l.length > 0 and l[0] != '#'
    [uc, ec, nm] = l.split ' '
    enc[parseInt(uc, 16)] = [parseInt(ec, 16), nm]
  enc

# vim: et ts=2 sw=2
