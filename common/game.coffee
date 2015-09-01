
extend =  require "node.extend"

((global) ->
  num_suites = 6
  num_cards = 5
  duplicates = 2
  tot_cards = num_suites*duplicates*num_cards
  suites = ['red', 'yellow', 'green', 'blue', 'white', 'rainbow']

  class Move
    constructor: (@game, @type) ->

    isLegal: ->
      return true

  class DiscardMove extends Move
    constructor: (game, @discard) ->
      @discard = 1*@discard
      super(game, "discard")

    isLegal: ->
      return super() &&
        @discard in @game.hands[@game.turn()]

    apply: () ->
      if @isLegal()
        @game.discard.push(@discard)
        @game.lastplay = @discard
        handarr = @game.hands[@game.turn()]
        handarr.splice(handarr.indexOf(@discard), 1)
        @game.deal()
        if @game.hints < 8
          @game.hints++

  class PlayMove extends Move
    constructor: (game, @play) ->
      @play = 1*@play
      super(game, "play")

    isLegal: ->
      return super() &&
        @play in @game.hands[@game.turn()]

    apply: () ->
      if @isLegal()
        card = @game.cards[@play]
        playarr = @game.plays[card.color]
        if card.number == 1 && playarr.length == 0
          playarr.push(@play)
        else if playarr.length > 0 && @game.cards[playarr[playarr.length-1]].number*1 == (card.number*1-1)
          playarr.push(@play)
        else
          @game.bombs++
          @game.discard.push(@play)
        handarr = @game.hands[@game.turn()]
        handarr.splice(handarr.indexOf(@play), 1)
        @game.lastplay = @play
        if card.number == 5 and @game.hints < 8
            @game.hints++
        @game.deal()

  class HintMove extends Move
    constructor: (game, @target, @hint) ->
      super(game, "hint")
      @cards = []
      hand = @game.hands[@target]
      for c in hand
        card = @game.cards[c]
        if 1*card.number == 1*@hint || ""+card.color == ""+@hint
          @cards.push(c)
        if ""+card.color == "rainbow"
          for s in suites
            if ""+s == ""+@hint
              @cards.push(c)

    isLegal: ->
      return super() && @cards.length > 0 && @game.hints > 0 && @target != @game.turn() && ""+@hint != "rainbow"

    apply: () ->
      if @isLegal()
        @game.hints--
        @game.lastplay=-1
        @game.waitForAck =
          target: @target,
          cards : @cards,
          hint  : @hint
          

  class Card
    constructor: (@color, @number) ->
      @known = @color?

    toString: () ->
      if @known then @color + "-" + @number else "unknown"

  class Game
    constructor: (@players) ->
      @lastplay = -1
      indexToCard = (index) ->
        inmod10 = index % 10
        cardnum = Math.floor((inmod10+1)/2)
        cardnum = if cardnum == 0 then 1 else cardnum
        color = suites[Math.floor(index / 10)]
        return new Card(color,cardnum)
      @moves=0
      @hints=8
      @discard=[]
      @bombs=0
      @gameover=false
      @waitForAck= undefined
      @score=0
      @turnsleft=-1
      cards = [0...tot_cards]
      @cards = []
      while cards.length > 0
        i = Math.floor cards.length*Math.random()
        @cards.push indexToCard cards.splice(i,1)[0]
      @cardsPerHand = if @players < 4 then 5 else 4
      @hands = []
      for i in [0...@players]
        hand = []
        for j in [i*@cardsPerHand...(i+1)*@cardsPerHand]
          hand.push(j)
        @hands.push(hand)
      @deck = [@players * @cardsPerHand ... tot_cards]
      @plays = {}
      for s in suites
        @plays[s]=[]

    turn: () -> @moves % @players

    deal: () ->
      if @deck.length > 0
        @hands[@turn()].push(@deck.splice(0,1)[0])
      if @deck.length == 0
        if @turnsleft == -1
          @turnsleft = @players+1

    cardsToString : (cards) ->
      (@cards[c].toString() for c in cards).join("\n")

    handCards: (playernum) ->
      @cards[i] for i in @hands[playernum]

    toString: () ->
      ret = ("Hand #{h}\n" + @cardsToString(@hands[h]) for h in [0...@players])
      ret.push "Deck\n" + @cardsToString(@deck)
      for s in suites
        ret.push ["Down #{s}",@cardsToString(@plays[s])]
      return ret.join("\n")

    isVisable: (index, player) ->
      not (index in @hands[player] or index in @deck)

    cloneFor: (player) ->
      if player < 0 || player > @players
        return null
      ret = extend(true,{},this)
      for i in [0...tot_cards]
        if !@isVisable(i, player)
          ret.cards[i] = new Card()
      ret

    ack: ->
      @waitForAck = undefined

    doMove: (move) ->
      if @gameover
        return false
      if @waitForAck?
        return false
      if !move.isLegal()
        return false
      move.apply()
      @moves++
      if @bombs == 3
        @gameover = true
        return true
      if @turnsleft > 0
        @turnsleft--
      if @turnsleft == 0
        @score = 0
        for _,stack of @plays
          @score += stack.length
        @gameover = true
      return true

  global.Card = Card
  global.Game = Game
  global.DiscardMove = DiscardMove
  global.PlayMove = PlayMove
  global.HintMove = HintMove
)(this)

