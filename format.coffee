#!/usr/bin/env coffee

Md =
  afm: require './afm'
  fs: require 'fs'

PointsPerInch = 72

PaperSizeLetter =
  w: 612
  h: 792

margins =
  l: PointsPerInch / 2
  t: PointsPerInch / 2
  r: PointsPerInch / 2
  b: PointsPerInch / 2

Fonts =
  Times:
    r:  { no: 1, type: 'afm', name: 'Times-Roman.afm' }
    b:  { no: 2, type: 'afm', name: 'Times-Bold.afm' }
    i:  { no: 3, type: 'afm', name: 'Times-Italic.afm' }
    bi: { no: 4, type: 'afm', name: 'Times-BoldItalic.afm' }
  Helvetica:
    r:  { no: 5, type: 'afm', name: 'Helvetica.afm' }
    b:  { no: 6, type: 'afm', name: 'Helvetica-Bold.afm' }
    i:  { no: 7, type: 'afm', name: 'Helvetica-Oblique.afm' }
    bi: { no: 8, type: 'afm', name: 'Helvetica-BoldOblique.afm' }
  Courier:
    r:  { no:  9, type: 'afm', name: 'Courier.afm' }
    b:  { no: 10, type: 'afm', name: 'Courier-Bold.afm' }
    i:  { no: 11, type: 'afm', name: 'Courier-Oblique.afm' }
    bi: { no: 12, type: 'afm', name: 'Courier-BoldOblique.afm' }

getFontMetrics = (font) ->
  fs = require 'fs'
  path = './afm/' + font.name
  data = Md.fs.readFileSync path, 'utf8'
  fm = Md.afm.load_afm data

calcBBox = (paperSize, margins) ->
  x: margins.l
  y: margins.b
  w: paperSize.w - (margins.l + margins.r)
  h: paperSize.h - (margins.t + margins.b)

calcColomnBox = (bbox, cols, gap) ->
  # `cols` must be an integer value greater than 0
  w = (bbox.w - gap * (cols - 1)) / cols
  offs = [0]
  offs.push offs[i - 1] + w + gap for i in [1...cols]

  w: w
  h: bbox.h
  offs: offs

formatColumns = (text, cbox, fontName, fontSize, leading) ->
  leading = fontSize * 1.2

  fm = getFontMetrics Fonts[fontName].r
  dsc = fm.fontBBox[1] / 1000.0 * fontSize * -1
  asc = fm.fontBBox[3] / 1000.0 * fontSize

  contents = []

  col = []
  y = cbox.h - asc
  for l, i in text.split '\n'
    if y - dsc < 0
      contents.push col
      col = []
      y = cbox.h - asc
    col.push x: 0, y: y, s: i + ': ' + l
    y -= leading
  contents.push col if col.length > 0

  contents

formatText = (text, colCount, fontName, fontSize, leading) ->
  bbox = calcBBox(PaperSizeLetter, margins)
  cbox = calcColomnBox(bbox, colCount, PointsPerInch / 4)

  bbox: bbox
  cbox: cbox
  pageCount: 2
  columCount: colCount
  colomns: formatColumns(text, cbox, fontName, fontSize, leading)
  fontName: fontName
  fontSize: fontSize

outputPDF = (cxt) ->
  # PDF version
  s = '%PDF-1.4\n\n'

  # Catalog
  stPgObjId = 7
  kids = ("#{i + stPgObjId} 0 R" for i in [0...cxt.pageCount]).join(' ')

  s += """
    1 0 obj
    <<
      /Type /Catalog
      /Pages 2 0 R
    >>
    endobj\n\n
    """

  # Pages
  s += """
    2 0 obj
    <<
      /Type /Pages
      /Kids [#{kids}]
      /Count #{cxt.pageCount}
    >>
    endobj\n\n
    """

  # MediaBox
  s += """
    3 0 obj
    <<
      [0 0 612 792]
    >>
    endobj\n\n
    """

  # ProcSet
  s += """
    4 0 obj
      [/PDF /Text]
    endobj\n\n
    """

  # Font
  s += """
    5 0 obj
    <<
      /F1 <<
        /Type /Font
        /Subtype /Type1
        /BaseFont /Times-Roman
        /Encoding /PDFDocEncoding >>
      /F2 <<
        /Type /Font
        /Subtype /Type1
        /BaseFont /Times-Bold
        /Encoding /PDFDocEncoding >>
      /F3 <<
        /Type /Font
        /Subtype /Type1
        /BaseFont /Times-Italic
        /Encoding /PDFDocEncoding >>
      /F4 <<
        /Type /Font
        /Subtype /Type1
        /BaseFont /Times-BoldItalic
        /Encoding /PDFDocEncoding >>
      /F5 <<
        /Type /Font
        /Subtype /Type1
        /BaseFont /Helvetica
        /Encoding /PDFDocEncoding >>
      /F6 <<
        /Type /Font
        /Subtype /Type1
        /BaseFont /Helvetica-Bold
        /Encoding /PDFDocEncoding >>
      /F7 <<
        /Type /Font
        /Subtype /Type1
        /BaseFont /Helvetica-Oblique
        /Encoding /PDFDocEncoding >>
      /F8 <<
        /Type /Font
        /Subtype /Type1
        /BaseFont /Helvetica-BoldOblique
        /Encoding /PDFDocEncoding >>
      /F9 <<
        /Type /Font
        /Subtype /Type1
        /BaseFont /Courier
        /Encoding /PDFDocEncoding >>
      /F10 <<
        /Type /Font
        /Subtype /Type1
        /BaseFont /Couurier-Bold
        /Encoding /PDFDocEncoding >>
      /F11 <<
        /Type /Font
        /Subtype /Type1
        /BaseFont /Couurier-Oblique
        /Encoding /PDFDocEncoding >>
      /F12 <<
        /Type /Font
        /Subtype /Type1
        /BaseFont /Couurier-BoldOblique
        /Encoding /PDFDocEncoding >>
    >>
    endobj\n\n
    """

  # Page grid
  bbox = cxt.bbox
  s += """
    6 0 obj
    << /Length 0 >>
    stream
    q
    1 0 0 1 0 0 cm
    .2 w
    0 0 1 rg
    #{bbox.x} #{bbox.y} m #{bbox.x} #{bbox.y + bbox.h} l
    #{bbox.x} #{bbox.y + bbox.h} m #{bbox.x + bbox.w} #{bbox.y + bbox.h} l
    #{bbox.x + bbox.w} #{bbox.y + bbox.h} m #{bbox.x + bbox.w} #{bbox.y} l
    #{bbox.x + bbox.w} #{bbox.y} m #{bbox.x} #{bbox.y} l
    S
    Q
    endstream
    endobj\n\n
    """

  # Page
  for pgId in [0...cxt.pageCount]
    pgObjId = stPgObjId + pgId
    stColId = cxt.columCount * pgId
    stColObjId = stPgObjId + cxt.pageCount + stColId
    objIds = for i in [0...cxt.columCount] when cxt.colomns[stColId + i]
      stColObjId + i
    contRefs = ("#{id} 0 R" for id in objIds).join(' ')

    s += """
      #{pgObjId} 0 obj
      <<
        /Type /Page
        /Parent 2 0 R
        /MediaBox 3 0 R
        /Contents [6 0 R #{contRefs}]
        /Resources << /ProcSet 4 0 R /Font 5 0 R >>
      >>
      endobj\n\n
      """

  # Contents
  for col, colId in cxt.colomns
    objId = stPgObjId + cxt.pageCount + colId

    lines = for l, lnId in col
      if lnId is 0
        x = l.x + cxt.bbox.x + cxt.cbox.offs[colId]
        y = l.y + cxt.bbox.y
      else
        x = l.x - col[lnId - 1].x
        y = l.y - col[lnId - 1].y
      "#{x} #{y} Td\n(#{l.s}) Tj"

    s += """
      #{objId} 0 obj
      << /Length 0 >>
      stream
      BT
      /F#{Fonts[cxt.fontName].r.no} #{cxt.fontSize} Tf
      #{lines.join('\n')}
      ET
      endstream
      endobj\n\n
      """

  # Xref and Trailer
  s += """
    xref
    0 10
    0000000000 65535 f

    trailer
    <<
      /Size 10
      /Root 1 0 R
    >>
    startxref
    0
    %%EOF\n
    """

###
text = '''
  Line 1: This is line one. Abcdefg Hijklmn Opqrst Uvwxyz.
  Line 2: This is line two. Abcdefg Hijklmn Opqrst Uvwxyz.
  Line 3: This is line three. Abcdefg Hijklmn Opqrst Uvwxyz.
  '''
###

text = Md.fs.readFileSync 'format.coffee', 'utf8'
columnCount = 2
fontName = 'Times'
#fontName = 'Courier'
fontSize = 8
leading = fontSize * 1.2

cxt = formatText(text, columnCount, fontName, fontSize, leading)
pdf = outputPDF(cxt)
console.log pdf

# vim: et ts=2 sw=2
