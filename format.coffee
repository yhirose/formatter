# Simple PDF text formatter.
# This script formats text into columns and pages and outputs a PDF file.
# For now, it supports Latin based languages by using 14 Adobe standard Type1
# fonts, such as Times-Roman, Helvetica and so on.
# Fonts are not embedded in the PDF file. So it's up to PDF reader which fonts
# actually will be chosen when rendering on screen or paper.

#### Dependencies

# Load OS functions.
env = require './env'

# Load utilty functions for PDF processing.
pdf = require './pdf'

# Load Unicode character map for WinAnsiEncoding.
cmap = pdf.loadUnicodeCharMap env.fs.readFileSync('cmap/standard.txt', 'utf8')

#### Constants and globals

# 1 inch is equal to 72 points.
PointsPerInch = 72

# US Letter size in point.
PaperSizeLetter = w: 612, h: 792

# Font registry.
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

# Paper margins in point.
margins =
  l: PointsPerInch / 2
  t: PointsPerInch / 2
  r: PointsPerInch / 2
  b: PointsPerInch / 2

#### Handle font information.

# Load font metrics from AFM (Adobe Font Metrics) file.
getFontMetrics = (font) ->
  afm = require './afm'
  afm.loadAfm env.fs.readFileSync('./afm/' + font.name, 'utf8')

#### Formatting text.

# Calculate boundary box on pager in point.
calcBBox = (paperSize, margins) ->
  x: margins.l
  y: margins.b
  w: paperSize.w - (margins.l + margins.r)
  h: paperSize.h - (margins.t + margins.b)

# Calculate column boundary box in point.
calcColomnBox = (bbox, cols, gap) ->
  # `cols` must be an integer value greater than 0
  w = (bbox.w - gap * (cols - 1)) / cols
  offs = [0]
  offs.push offs[i - 1] + w + gap for i in [1...cols]

  w: w
  h: bbox.h
  offs: offs

# Round position by 3 digits below decimal point.
roundPosition = (x) ->
  Math.round(x * 1000) / 1000

# Line break algorithm.
lineBreak = (par, colw, fs, fm) ->
  result = []
  maxlw = colw * 1000
  lw = 0
  st = 0
  codes = []
  for ch, i in par.text
    uc = par.text.charCodeAt i
    [code, name] = cmap[uc] ? [0x3f, 'question'] # TODO: handle symbol chars

    cw = fm.charMetrics[name].WX * fs
    if lw + cw > maxlw
      result.push x: 0, codes: codes
      lw = 0
      st = i
      codes = []

    lw += cw
    codes.push code

  if st < i or result.length is 0
    result.push x: 0, codes: codes

  result

# Format columns.
formatColumns = (paragraphs, cbox, fontName, fontSize, leadingRatio) ->
  fm = getFontMetrics Fonts[fontName].r
  dsc = roundPosition fm.fontBBox[1] * fontSize * -1 / 1000
  asc = roundPosition fm.fontBBox[3] * fontSize / 1000

  contents = []
  col = []
  y = cbox.h - asc
  for par in paragraphs
    for lineInfo in lineBreak par, cbox.w, fontSize, fm
      if y - dsc < 0
        contents.push col
        col = []
        y = cbox.h - asc

      lineInfo.y = y
      col.push lineInfo

      y -= fontSize * leadingRatio

  contents.push col if col.length > 0
  contents

# Format pages.
formatText = (paragraphs, colCount, fontName, fontSize, leadingRatio) ->
  bbox = calcBBox(PaperSizeLetter, margins)
  cbox = calcColomnBox(bbox, colCount, PointsPerInch / 4)
  cols = formatColumns(paragraphs, cbox, fontName, fontSize, leadingRatio)

  bbox: bbox
  cbox: cbox
  pageCount: Math.ceil(cols.length / colCount)
  columCount: colCount
  colomns: cols
  fontName: fontName
  fontSize: fontSize

#### Generate PDF files from the formatted text information.

# Format pages
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
        >>
      /F2 <<
        /Type /Font
        /Subtype /Type1
        /BaseFont /Times-Bold
        >>
      /F3 <<
        /Type /Font
        /Subtype /Type1
        /BaseFont /Times-Italic
        >>
      /F4 <<
        /Type /Font
        /Subtype /Type1
        /BaseFont /Times-BoldItalic
        >>
      /F5 <<
        /Type /Font
        /Subtype /Type1
        /BaseFont /Helvetica
        >>
      /F6 <<
        /Type /Font
        /Subtype /Type1
        /BaseFont /Helvetica-Bold
        >>
      /F7 <<
        /Type /Font
        /Subtype /Type1
        /BaseFont /Helvetica-Oblique
        >>
      /F8 <<
        /Type /Font
        /Subtype /Type1
        /BaseFont /Helvetica-BoldOblique
        >>
      /F9 <<
        /Type /Font
        /Subtype /Type1
        /BaseFont /Courier
        >>
      /F10 <<
        /Type /Font
        /Subtype /Type1
        /BaseFont /Courier-Bold
        >>
      /F11 <<
        /Type /Font
        /Subtype /Type1
        /BaseFont /Courier-Oblique
        >>
      /F12 <<
        /Type /Font
        /Subtype /Type1
        /BaseFont /Courier-BoldOblique
        >>
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
      hexStr = '<' + (code.toString(16) for code in l.codes).join('') + '>'
      "#{roundPosition x} #{roundPosition y} Td\n#{hexStr} Tj"

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
  xrefs = ("0000000000 00000 n" for objId in [1...objCount]).join('\n')

  s += """
    xref
    0 #{objCount}
    0000000000 65535 f
    #{xrefs}

    trailer
    <<
      /Size #{objCount}
      /Root 1 0 R
    >>
    startxref
    0
    %%EOF\n
    """

#### Run the script.

makeParagraphDataFromPlainText = (data) ->
  for text in data.split '\n'
    {
      text: text
      attributes: undefined
      style:
        align: 'left'
        break: 'word'
    }

# Parse arguments
options =
  columnCount: 2,
  fontName: 'Times',
  fontSize: 7,
  leadingRatio: 1.2

srcPath = undefined

for arg in env.args[2...]
  # Parse option
  if arg.match /--(\w+)=(\w+)/
    { $1: key, $2: val } = RegExp
    switch key
      when 'fontName'
        options[key] = val
      when 'columnCount'
        options[key] = parseInt val, 10
      else
        options[key] = parseFloat val
  # Parse script path
  else
    srcPath = arg

# Open a script file.
env.readFileOrStdin srcPath, 'utf8', (data) ->

  # Setup paragraph data
  paragraphs = makeParagraphDataFromPlainText data

  # Format text
  cxt = formatText paragraphs,
    options.columnCount,
    options.fontName,
    options.fontSize,
    options.leadingRatio

  # Generate PDF, and output to stdin.
  pdf = outputPDF cxt
  env.print pdf
