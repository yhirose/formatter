#!/usr/bin/env coffee

fs = require 'fs'
#_ = require 'underscore'
#_s = require 'underscore.string'

read_file = (path, callback) ->
  if path
    fs.readFile path, 'utf8', (err, data) ->
      callback data
  else
    process.stdin.resume()
    process.stdin.setEncoding 'utf8'
    process.stdin.on 'data', callback

parse_afm_charmetrics_entry = (chm, item) ->
  [c, d...] = item.split ' '
  switch c
    when 'C', 'WX', 'B'
      d = d.map (v) -> parseInt v, 10
  chm[c] = if d.length is 1 then d[0] else d
  chm

parse_afm_charmetrics = (afm, lines, i) ->
  l = lines[i]
  until /^EndCharMetrics/.exec l
    items = (item for item in l.split /\s*;\s*/ when item.length > 0)
    chm = items.reduce ((m, v) -> parse_afm_charmetrics_entry(m, v)), {}
    afm.chm[chm.N] = chm
    l = lines[++i]
  i

load_afm = (font, callback) ->
  path = 'afm/' + font + '.afm'
  fs.readFile path, 'utf8', (err, s) ->
    afm = chm: {}
    lines = (l.trim() for l in s.split '\n')
    for i in [0...lines.length]
      l = lines[i]
      if /^StartCharMetrics/.exec l
        i = parse_afm_charmetrics(afm, lines, ++i)
    callback afm

parse_pdfdoc_enc_entry = (enc, l) ->
  [uc, ec, nm] = l.split ' '
  enc[parseInt(uc, 16)] = [parseInt(ec, 16), nm]
  enc

load_pdfdoc_enc = (callback) ->
  fs.readFile 'enc/pdfdocenc.txt', 'utf8', (err, s) ->
    lines = (l.trim() for l in s.split '\n' when l.length > 0 and l[0] != '#')
    callback lines.reduce ((m, v) -> parse_pdfdoc_enc_entry(m, v)), {}

run = (file, font, out) ->
  load_pdfdoc_enc (enc) ->
    load_afm font, (afm) ->
      read_file file, (s) ->
        for l in s.split '\n'
          for ch, i in l
            uc = l.charCodeAt i
            [ec, nm] = enc[uc]
            wd = afm.chm[nm].WX
            out ch, uc, wd, nm

argv = require('optimist').argv
font = argv.font || 'Times-Roman'
file = argv._[0]

#file = 'sandbox.coffee'
run file, font, console.log

# vim: et ts=2 sw=2
