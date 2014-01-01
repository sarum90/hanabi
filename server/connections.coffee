
ws = require('ws')
pson_lib = require('pson')
bb_lib = require('bytebuffer')
infra = require('../server/infra')
hanabi = require('../common/game')

class LogMessage
  constructor: (@cxn) ->

  got: (message) ->
    console.log(message)
    if message.type == "move"
      if message.movetype == "discard"
        mv = new hanabi.DiscardMove(@cxn.game, message.card)
      else if message.movetype == "play"
        mv = new hanabi.PlayMove(@cxn.game, message.card)
      else if message.movetype == "hint"
        mv = new hanabi.HintMove(@cxn.game, message.target*1, message.hint)

      if @cxn.game.doMove mv
        console.log("updating game")
        for cxn in @cxn.getCxns()
          cxn.sendGame()
      else
        console.log("failed to make move")
        @cxn.send("Bad Move / Move not possible")
    else if message.type == "ack"
      @cxn.game.ack()
      for cxn in @cxn.getCxns()
        cxn.sendGame()
    else if message.type == "handmod"
      newhand = message.newhand
      oldhand = @cxn.game.hands[message.player]
      change = true
      if newhand.length != oldhand.length
        change = false

      for i in newhand
        inother = false
        for j in oldhand
          if j*1 == i*1
            inother = true
        if not inother
          change = false

      for j in oldhand
        inother = false
        for i in newhand
          if j*1 == i*1
            inother = true
        if not inother
          change = false

      if change
        @cxn.game.hands[message.player] = newhand
      for cxn in @cxn.getCxns()
        cxn.sendGame()
    else
      console.log(message)

class WaitForGame
  constructor: (@cxn) ->

  got: (message) ->
    if not message?
      @cxn.send("No message?")
      return
    if not message.gamename?
      @cxn.send("No game name")
      return
    if (not message.players?) or
       message.players < 2 or
       message.players > 5
      @cxn.send("bad players number")
      return
    if (not message.from?) or
       message.from < 0 or
       message.from >= message.players
      @cxn.send("bad from val")
      return
    @cxn.game = infra.getGame(message.gamename, message.players)
    @cxn.gamename = message.gamename
    @cxn.players = message.players
    un = @cxn.uniqueName()
    arr = @cxn.getCxns()
    if not arr?
      connections[un] = []
      arr = @cxn.getCxns()
    arr.push(@cxn)
    @cxn.player = message.from
    @cxn.sendGame()
    @cxn.state = new LogMessage(@cxn)


class Connection
  constructor: (@ws) ->
    @pson = new pson_lib.ProgressivePair([])
    me = this
    @ws.onmessage = (message) ->
      me.got(message)
    @state = new WaitForGame(this)
    @gamename = ""
    @players = 2

  uniqueName: ->
    return "#{@players}-#{@gamename}"

  getCxns: ->
    return connections[@uniqueName()]

  sendGame: ->
    if not @ver?
      @ver = 0
    @ver++
    xmit = {}
    for k,v of @game.cloneFor @player
      if typeof v != "function"
        xmit[k] = v
    @send
      type: "game"
      game: xmit
      ver: @ver

  send: (message) ->
    enc = @pson.encode(message)
    enc.flip()
    if @ws.readyState == ws.OPEN
      @ws.send(enc.toBase64())

  got: (message) ->
    bb = bb_lib.decode64(message.data)
    decoded = @pson.decode(bb)
    @state.got(decoded)

connections = {}

this.start = (svr) ->
  wss = new ws.Server
              server: svr
              path: '/ws'
  wss.on('connection', (ws) ->
    new Connection(ws)
  )
