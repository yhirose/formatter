env = require './env'
afm = require './afm'
pdf = require './pdf'

run = (path, afmPath, out) ->
  env.fs.readFile 'cmap/pdfdocenc.txt', 'utf8', (err, data) ->
    cmap = pdf.loadUnicodeCharMap data

    env.fs.readFile afmPath, 'utf8', (err, data) ->
      fm = afm.loadAfm data

      env.fs.readFile path, 'utf8', (err, data) ->
        for l in data.split '\n'
          for ch, i in l
            uc = l.charCodeAt i
            [ec, nm] = cmap[uc]
            wd = fm.charMetrics[nm].WX
            out ch, uc, wd, nm

srcPath = process.argv[2] || 'sandbox.coffee'
afmPath = process.argv[3] || './afm/Times-Roman.afm'

run srcPath, afmPath, env.print
