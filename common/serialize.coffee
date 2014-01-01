
hanabi = require('../common/game')
pson_lib = require('pson')
bytebuffer = require('bytebuffer')


@game = (game) ->
  pson = new pson_lib.ProgressivePair([])
  xmit = {}
  for k,v of game
    if typeof v != "function"
      xmit[k] = game[k]
  ps = pson.encode(xmit)
  ps.flip()
  bb = ps.toBase64()
  return bb

