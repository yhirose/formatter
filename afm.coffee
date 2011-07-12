# **Afm** module privides font metrics information of Adobe AFM file format.
# See the AFM specification to get more information.

# Loads font metrics information from AFM. The data format is:
#    KEY VALUE
# Value format totally depends on the key.
exports.loadAfm = (data) ->
  afm = charMetrics: {}
  lines = (l.trim() for l in data.split '\n')
  for l, i in lines
    if /^StartCharMetrics/.exec l
      i = parseAfmCharMetrics(afm, lines, ++i)
    else if /^FontBBox/.exec l
      afm.fontBBox = (parseInt(x, 10) for x in l.split(' ').splice(1))
  afm

# Parse character metrics info. The data format is:
#     CMD: (DATA)+ (; CMD: (DATA)+)*
# Data type would be integer decimal or string depending on the command.
parseAfmCharMetrics = (afm, lines, i) ->
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
