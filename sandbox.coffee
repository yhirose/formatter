#!/usr/bin/env coffee

fs = require 'fs'
#_ = require 'underscore'
#_.mixin require 'underscore.string'

read_file = (path, callback) ->
  if path
    fs.readFile path, 'utf8', (err, data) ->
      callback data
  else
    process.stdin.resume()
    process.stdin.setEncoding 'utf8'
    process.stdin.on 'data', callback

load_afm = (font, callback) ->
  path = 'afm/' + font + '.afm'
  fs.readFile path, 'utf8', (err, data) ->
    afm =
      chm: {}
    lines = (x.trim() for x in data.split '\n')
    for i in [0...lines.length]
      l = lines[i]
      if /^StartCharMetrics/.exec l
        l = lines[++i]
        until /^EndCharMetrics/.exec l
          m = {}
          for [c, d...] in (x.split ' ' for x in l.split /\s*;\s*/ when x.length > 0)
            switch c
              when 'C', 'WX', 'B'
                d = d.map (x) -> parseInt x, 10
            m[c] = if d.length is 1 then d[0] else d
          afm.chm[m.N] = m
          l = lines[++i]
    callback afm

load_pdfdoc_enc = (callback) ->
  fs.readFile 'enc/pdfdocenc.txt', 'utf8', (err, data) ->
    enc = {}
    for l in data.split '\n' when l.length > 0
      [uc, ec, nm] = l.split ' '
      uc = parseInt uc, 16
      ec = parseInt ec, 16
      enc[uc] = [ec, nm]
    callback enc

run = (file, font, out) ->
  load_pdfdoc_enc (enc) ->
    load_afm font, (afm) ->
      read_file file, (data) ->
        for l in data.split '\n'
          for ch, i in l
            uc = l.charCodeAt i
            [ec, nm] = enc[uc]
            wd = afm.chm[nm].WX
            out ch, uc, wd, nm

argv = process.argv
file = if argv.length >= 3 then argv[2] else undefined
font = if argv.length >= 4 then argv[3] else 'Times-Roman'

file = 'sandbox.coffee'
run file, font, console.log

# vim: et ts=2 sw=2
