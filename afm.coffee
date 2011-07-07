#!/usr/bin/env coffee

# **Afm** module privides font metrics information of Adobe AFM file format.

exports.load_afm = (data) ->
  afm = charMetrics: {}
  lines = (l.trim() for l in data.split '\n')
  for i in [0...lines.length]
    l = lines[i]
    if /^StartCharMetrics/.exec l
      i = parse_afm_charmetrics(afm, lines, ++i)
    else if /^FontBBox/.exec l
      afm.fontBBox = (parseInt(x, 10) for x in l.split(' ').splice(1))
  afm

parse_afm_charmetrics = (afm, lines, i) ->
  l = lines[i]
  until /^EndCharMetrics/.exec l
    chm = {}
    for s in l.split /\s*;\s*/ when s.length > 0
      [c, d...] = s.split ' '
      switch c
        when 'C', 'WX', 'B'
          d = d.map (v) -> parseInt v, 10
      chm[c] = if d.length is 1 then d[0] else d

    afm.charMetrics[chm.N] = chm
    l = lines[++i]
  i

# vim: et ts=2 sw=2

