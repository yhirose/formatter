#
#
#
env = require './env'

pdf = require './pdf'
enc = pdf.loadPDFDocEncoding env.fs.readFileSync('enc/pdfdocenc.txt', 'utf8')

PointsPerInch = 72

PaperSizeLetter =
  w: 612
  h: 792

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

margins =
  l: PointsPerInch / 2
  t: PointsPerInch / 2
  r: PointsPerInch / 2
  b: PointsPerInch / 2

getFontMetrics = (font) ->
  afm = require './afm'
  afm.loadAfm env.fs.readFileSync('./afm/' + font.name, 'utf8')

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

roundPosition = (x) ->
  Math.round(x * 1000) / 1000

lineBreak = (par, colw, fs, fm) ->
  chunks = []
  maxlw = colw * 1000
  lw = 0
  st = 0
  for ch, i in par
    uc = par.charCodeAt i
    codeInfo = enc[uc]
    nm = if codeInfo then codeInfo[1] else 'emdash' # TODO: handle symbol chars
    cw = fm.charMetrics[nm].WX * fs
    if lw + cw > maxlw
      chunks.push par.slice st, i
      st = i
      lw = 0
    lw += cw
  if st < i or chunks.length is 0
    chunks.push par.slice st, i
  chunks

encodePDFText = (s) ->
  s.replace /([()])/g, -> '\\' + RegExp.$1

formatColumns = (text, cbox, fontName, fontSize, leading) ->
  leading = fontSize * 1.2

  fm = getFontMetrics Fonts[fontName].r
  dsc = roundPosition fm.fontBBox[1] * fontSize * -1 / 1000
  asc = roundPosition fm.fontBBox[3] * fontSize / 1000

  contents = []
  col = []
  y = cbox.h - asc
  for par in text.split '\n'
    for line in lineBreak par, cbox.w, fontSize, fm
      if y - dsc < 0
        contents.push col
        col = []
        y = cbox.h - asc
      col.push x: 0, y: y, s: line
      y -= leading
  contents.push col if col.length > 0
  contents

formatText = (text, colCount, fontName, fontSize, leading) ->
  bbox = calcBBox(PaperSizeLetter, margins)
  cbox = calcColomnBox(bbox, colCount, PointsPerInch / 4)
  cols = formatColumns(text, cbox, fontName, fontSize, leading)

  bbox: bbox
  cbox: cbox
  pageCount: Math.ceil(cols.length / colCount)
  columCount: colCount
  colomns: cols
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
  bboxShape = """
    #{bbox.x} #{bbox.y} m #{bbox.x} #{bbox.y + bbox.h} l
    #{bbox.x} #{bbox.y + bbox.h} m #{bbox.x + bbox.w} #{bbox.y + bbox.h} l
    #{bbox.x + bbox.w} #{bbox.y + bbox.h} m #{bbox.x + bbox.w} #{bbox.y} l
    #{bbox.x + bbox.w} #{bbox.y} m #{bbox.x} #{bbox.y} l
    S
    """
  cbox = cxt.cbox
  cboxShapes = for dl in cbox.offs
    x = bbox.x + dl
    y = bbox.y
    w = cbox.w
    h = cbox.h
    """
    #{x} #{y} m #{x} #{y + h} l
    #{x} #{y + h} m #{x + w} #{y + h} l
    #{x + w} #{y + h} m #{x + w} #{y} l
    #{x + w} #{y} m #{x} #{y} l
    S
    """

  s += """
    6 0 obj
    << /Length 0 >>
    stream
    q
    1 0 0 1 0 0 cm
    .1 w
    0 0 1 rg
    #{bboxShape}
    #{cboxShapes.join('\n')}
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
        x = l.x + cxt.bbox.x + cxt.cbox.offs[colId % cxt.columCount]
        y = l.y + cxt.bbox.y
      else
        x = l.x - col[lnId - 1].x
        y = l.y - col[lnId - 1].y
      "#{roundPosition x} #{roundPosition y} Td\n(#{encodePDFText(l.s)}) Tj"

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
  objCount = stPgObjId + cxt.pageCount + cxt.colomns.length
  xrefs = for objId in [1...objCount]
    "0000000000 00000 n"

  s += """
    xref
    0 #{objCount}
    0000000000 65535 f
    #{xrefs.join('\n')}

    trailer
    <<
      /Size #{objCount}
      /Root 1 0 R
    >>
    startxref
    0
    %%EOF\n
    """

# Run the script.
srcPath = env.args[2]
env.readFileOrStdin srcPath, 'utf8', (data) ->
  columnCount = 3
  fontName = 'Times'
  fontSize = 8
  leading = fontSize * 1.2

  cxt = formatText data, columnCount, fontName, fontSize, leading
  pdf = outputPDF cxt
  env.print pdf
