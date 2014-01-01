
this.require = (val) ->
  if val == "node.extend"
    return $.extend
  throw "Unknown call to require #{val}"

this.pson = new dcodeIO.PSON.ProgressivePair([])
