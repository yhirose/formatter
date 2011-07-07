#!/usr/bin/env coffee

fs = require 'fs'
afm = require './afm'
pdf = require './pdf'

run = (path, afmPath, out) ->
  fs.readFile 'enc/pdfdocenc.txt', 'utf8', (err, data) ->
    enc = pdf.load_pdfdoc_enc (data)

    fs.readFile afmPath, 'utf8', (err, data) ->
      fm = afm.load_afm data

      fs.readFile path, 'utf8', (err, data) ->
        for l in data.split '\n'
          for ch, i in l
            uc = l.charCodeAt i
            [ec, nm] = enc[uc]
            wd = fm.charMetrics[nm].WX
            out ch, uc, wd, nm

srcPath = process.argv[2] || 'sandbox.coffee'
afmPath = process.argv[3] || './afm/Times-Roman.afm'

run srcPath, afmPath, console.log

# vim: et ts=2 sw=2
