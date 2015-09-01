
hanabi = require "../common/game"

module.exports =
  setUp: (callback) ->
    callback()

  tearDown: (callback) ->
    callback()

  testexample: (test) ->
    test.equals(1,1)
    test.ok(true)
    test.done()

  cardcount: (test) ->
    game = new hanabi.Game(2)
    test.equals(game.hands[0].length, 5)
    test.equals(game.hands[1].length, 5)
    test.equals(game.deck.length, 50-5-5)
    game3 = new hanabi.Game(3)
    test.equals(game3.hands[0].length, 5)
    test.equals(game3.hands[1].length, 5)
    test.equals(game3.hands[2].length, 5)
    test.equals(game3.deck.length, 50-5-5-5)
    game4 = new hanabi.Game(4)
    test.equals(game4.hands[0].length, 4)
    test.equals(game4.hands[1].length, 4)
    test.equals(game4.hands[2].length, 4)
    test.equals(game4.hands[3].length, 4)
    test.equals(game4.deck.length, 50-16)
    game5 = new hanabi.Game(5)
    test.equals(game5.hands[0].length, 4)
    test.equals(game5.hands[1].length, 4)
    test.equals(game5.hands[2].length, 4)
    test.equals(game5.hands[3].length, 4)
    test.equals(game5.hands[4].length, 4)
    test.equals(game5.deck.length, 50-20)
    test.done()

  crosscloning: (test) ->
    game = new hanabi.Game(3)
    cloned = game.cloneFor(0)
    unknownCard = new hanabi.Card()
    unkhand = (unknownCard for i in [0...5])
    test.deepEqual(cloned.handCards(0),unkhand)
    test.ok not ((h.known for h in cloned.handCards(0)).reduce (x,y) -> x || y)
    test.ok (h.known for h in cloned.handCards(1)).reduce (x,y) -> x && y
    test.ok (h.known for h in cloned.handCards(2)).reduce (x,y) -> x && y
    test.done()

  discardMove: (test) ->
    game = new hanabi.Game(3)
    dc = game.hands[0][0]
    mv = new hanabi.DiscardMove(game,  dc)
    test.ok game.doMove(mv)
    test.equal(game.discard.length,1)
    test.equal(game.discard[0],dc)
    test.equal(game.hands[0].length,5)
    test.equal(game.hints,8)
    test.equal(game.bombs,0)
    test.equal(game.deck.length,50-(5*3)-1)
    test.ok not game.gameover
    test.done()

  discardMoveWithHint: (test) ->
    game = new hanabi.Game(3)
    dc = game.hands[0][0]
    game.hints = 0
    mv = new hanabi.DiscardMove(game,  dc)
    test.ok game.doMove(mv)
    test.equal(game.hints,1)
    test.done()

  badDiscardMove: (test) ->
    game = new hanabi.Game(3)
    dc = game.hands[1][0]
    mv = new hanabi.DiscardMove(game, dc)
    test.ok not game.doMove(mv)
    test.equal(game.discard.length,0)
    test.equal(game.hands[0].length,5)
    test.equal(game.hints,8)
    test.equal(game.bombs,0)
    test.equal(game.deck.length,50-(5*3))
    test.ok not game.gameover
    test.done()

  playMove: (test) ->
    game = new hanabi.Game(3)
    play = game.hands[0][0]
    game.cards[play] = new hanabi.Card("yellow", 1)
    mv = new hanabi.PlayMove(game,  play)
    test.ok game.doMove(mv)
    test.equal(game.discard.length,0)
    test.equal(game.plays["yellow"],play)
    test.equal(game.hands[0].length,5)
    test.equal(game.hints,8)
    test.equal(game.bombs,0)
    test.equal(game.deck.length,50-(5*3)-1)
    test.ok(!game.gameover)
    test.done()

  gameEndingPlayMove: (test) ->
    game = new hanabi.Game(3)
    game.turnsleft = 1
    play = game.hands[0][0]
    game.cards[play] = new hanabi.Card("yellow", 1)
    mv = new hanabi.PlayMove(game, play)
    test.ok game.doMove(mv)
    test.ok(game.gameover)
    test.equal(game.score,1)
    test.done()

  player2Move: (test) ->
    game = new hanabi.Game(3)
    game.turnsleft = 1
    game.moves = 1
    play = game.hands[1][0]
    game.cards[play] = new hanabi.Card("yellow", 1)
    mv = new hanabi.PlayMove(game,  play)
    test.ok game.doMove(mv)
    test.done()

  bombPlayMove: (test) ->
    game = new hanabi.Game(3)
    play = game.hands[0][0]
    game.cards[play] = new hanabi.Card("yellow", 2)
    mv = new hanabi.PlayMove(game,  play)
    test.ok game.doMove(mv)
    test.equal(game.discard[0],play)
    test.equal(game.plays["yellow"].length,0)
    test.equal(game.hands[0].length,5)
    test.equal(game.hints,8)
    test.equal(game.bombs,1)
    test.equal(game.deck.length,50-(5*3)-1)
    test.ok(!game.gameover)
    test.done()

  gameEndingBombMove: (test) ->
    game = new hanabi.Game(3)
    play = game.hands[0][0]
    game.cards[play] = new hanabi.Card("yellow", 2)
    game.bombs=2
    mv = new hanabi.PlayMove(game,  play)
    test.ok game.doMove(mv)
    test.equal(game.score,0)
    test.ok(game.gameover)
    test.done()

  badPlayMove: (test) ->
    game = new hanabi.Game(3)
    play = game.hands[1][0]
    mv = new hanabi.PlayMove(game,  play)
    test.ok not game.doMove(mv)
    test.equal(game.discard.length,0)
    test.equal(game.hands[0].length,5)
    test.equal(game.hints,8)
    test.equal(game.bombs,0)
    test.equal(game.deck.length,50-(5*3))
    test.ok not game.gameover
    test.done()

  hintMove: (test) ->
    game = new hanabi.Game(3)
    for i in [0...5]
      hint = game.hands[1][i]
      game.cards[hint] = new hanabi.Card("yellow", 1)
    mv = new hanabi.HintMove(game, 1, "yellow")
    test.ok game.doMove(mv)
    test.equal(mv.cards.length, 5)
    test.deepEqual(mv.cards.sort(), game.hands[1].sort())
    test.equal(game.discard.length,0)
    test.equal(game.hands[0].length,5)
    test.equal(game.hints,7)
    test.equal(game.bombs,0)
    test.equal(game.deck.length,50-(5*3))
    test.ok(!game.gameover)
    test.done()

  numHintMove: (test) ->
    game = new hanabi.Game(3)
    for i in [0...5]
      hint = game.hands[1][i]
      game.cards[hint] = new hanabi.Card("yellow", 4)
    mv = new hanabi.HintMove(game, 1, 4)
    test.ok game.doMove(mv)
    test.deepEqual(mv.cards.sort(), game.hands[1].sort())
    test.done()

  noHintMove: (test) ->
    game = new hanabi.Game(3)
    for i in [0...5]
      hint = game.hands[1][i]
      game.cards[hint] = new hanabi.Card("yellow", 1)
    mv = new hanabi.HintMove(game, 1, "yellow")
    game.hints = 0
    test.ok not game.doMove(mv)
    test.done()

  badHintMove: (test) ->
    game = new hanabi.Game(3)
    for i in [0...5]
      hint = game.hands[1][i]
      game.cards[hint] = new hanabi.Card("yellow", 1)
    mv = new hanabi.HintMove(game, 1, "red")
    test.ok not game.doMove(mv)
    test.equal(game.hints, 8)
    test.done()
    
