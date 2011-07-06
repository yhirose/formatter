#!/usr/bin/env coffee

PointsPerInch = 72

PaperSizeLetter =
  w: 612
  h: 792

margins =
  l: PointsPerInch / 2,
  t: PointsPerInch / 2,
  r: PointsPerInch / 2,
  b: PointsPerInch / 2

box = (paper_size, margins) ->
  x: margins.l,
  y: margins.b,
  w: paper_size.w - (margins.l + margins.r),
  h: paper_size.h - (margins.t + margins.b)

format = (s) ->
  console.log box(PaperSizeLetter, margins)
  console.log s

s = '''
line 1: This is line one.
line 2: This is line two.
line 3: This is line three.
'''

format(s)

# vim: et ts=2 sw=2
