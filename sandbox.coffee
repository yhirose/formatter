env = require './env'
afm = require './afm'
pdf = require './pdf'

run = (path, afmPath, out) ->
  env.fs.readFile 'enc/pdfdocenc.txt', 'utf8', (err, data) ->
    enc = pdf.loadPDFDocEncoding data

    env.fs.readFile afmPath, 'utf8', (err, data) ->
      fm = afm.loadAfm data

      env.fs.readFile path, 'utf8', (err, data) ->
        for l in data.split '\n'
          for ch, i in l
            uc = l.charCodeAt i
            [ec, nm] = enc[uc] ? [0x3f, 'question'] # TODO: handle symbol chars
            wd = fm.charMetrics[nm].WX
            out ch, uc, wd, nm

srcPath = process.argv[2] ? 'sandbox.coffee'
afmPath = process.argv[3] ? './afm/Times-Roman.afm'

run srcPath, afmPath, env.print
