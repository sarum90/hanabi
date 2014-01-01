
extend = require("node.extend")

addcard = (container, game, card_num) ->
  card = new Card()
  if card_num >= 0
    card = game.cards[card_num]
  if not card_num?
    card_num = ""
  color = card.color
  number = card.number
  if not card.known
    number = '?'
    color = 'undefined'
  container.append("<li num='#{card_num}' class='card #{color}-card'>#{number}<div class='cardid'>#{card_num}</div></li>")

drawGame = (container, game, playerid) ->
  container.text("")
  for i in [1..game.players]
    container.append("<div id='hand_#{i-1}_label' class='handlabel'>Hand #{i}:</div>")

    container.append("<ul id='hand_#{i-1}' class='handcontainer'></ul>")
    handc = $("#hand_#{i-1}")
    for c in game.hands[i-1]
      addcard(handc, game, c)

    container.append("<br>")

  $("#hand_#{playerid}").sortable
    axis: "x"
    stop: (event, ui) ->
      newhand = []
      for i in $("#hand_#{playerid}").children()
        newhand.push($(i).attr("num")*1)
      diff = false
      for i in [0...newhand.length]
        if 1*newhand[i] != 1*game.hands[playerid][i]
          diff = true
      if diff
        sendinfo
          type: "handmod"
          player: playerid
          newhand: newhand

  $("#hand_#{playerid} > .card").click ->
    $(".selected").removeClass("selected")
    $(this).addClass("selected")
  $("#hand_#{game.turn()}").addClass("selectedhand")
  container.append("Hints: #{game.hints}<br>")
  container.append("Bombs: #{game.bombs}<br>")
  container.append("Deck: #{game.deck.length}<br>")

  container.append("Play: <br/><div id='play_container' class='container'></div><br/>")
  the_play = $("#play_container")
  for k,v of game.plays
    if v.length < 0
      addcard(the_play, game, -1)
    else
      ind = v.length-1
      addcard(the_play, game, v[ind])
  container.append("Discard: <br/><div id='dc_pile' class='container'></div><br/>")
  for d in game.discard
    addcard($("#dc_pile"), game, d)
  container.append("Turn: #{game.turn() + 1}<br>")
  if game.gameover
    container.append("Score: #{game.score}<br>")
  else
    container.append("Controls:")
    if game.waitForAck?
      wfa = game.waitForAck
      for c in wfa.cards
        carddiv = $(".card[num=#{c}]")
        if wfa.hint*1 in [1..5]
          carddiv.html("
            #{wfa.hint}<div class='cardid'>#{c}</div>")
        else
          carddiv.removeClass("undefined-card")
          carddiv.addClass("#{wfa.hint}-card")
        carddiv.addClass("lookHere")

      if game.waitForAck.target == playerid
        container.append("<input type='button' value='Acknowledge'></input>")
        $("input[value=Acknowledge]").click ->
          sendinfo
            type: "ack"
      else
        container.append("Hinted Player #{wfa.target+1}: #{wfa.hint}.")
    else
      container.append("<br>")
      container.append("<input type='button' value='Hint'></input>")
      container.append(
       '<select name="hint">
          <option value=""></option>
          <option value="yellow">Yellow</option>
          <option value="red">Red</option>
          <option value="white">White</option>
          <option value="blue">Blue</option>
          <option value="green">Green</option>
          <option value="1">1</option>
          <option value="2">2</option>
          <option value="3">3</option>
          <option value="4">4</option>
          <option value="5">5</option>
        </select>'
      )
      container.append(
        '<select name="Target"> </select>'
      )
      $("select[name=Target]").append(
        "<option value=''></option>"
      )
      for i in [0...game.players]
        if i != playerid
          $("select[name=Target]").append(
            "<option value=#{i}>Player #{i+1}</option>"
          )

      container.append("<br>")
      container.append("<input type='button' value='Play'></input>")
      container.append("<br>")
      container.append("<input type='button' value='Discard'></input>")
      $("input[value=Hint]").click ->
        num = $(".selected").attr("num")
        reqmv = new PlayMove(game, num)
        sendinfo
          type: "move"
          movetype: "hint"
          target: $("select[name=Target]").val()
          hint: $("select[name=hint]").val()

      $("input[value=Play]").click ->
        if $(".selected").size() == 0
          alert "Must select a card first"
        if $(".selected").size() == 1
          num = $(".selected").attr("num")
          reqmv = new PlayMove(game, num)
          sendinfo
            type: "move"
            movetype: "play"
            card: num

      $("input[value=Discard]").click ->
        if $(".selected").size() == 0
          alert "Must select a card first"
        if $(".selected").size() == 1
          num = $(".selected").attr("num")
          sendinfo
            type: "move"
            movetype: "discard"
            card: num
  if game.lastplay? && game.lastplay >= 0
    hl = game.lastplay
    console.log(hl)
    console.log(".card[num=#{hl}]")
    $(".card[num=#{hl}]").addClass("lastplay")
    console.log("HERE")


ws = {}
pson = new dcodeIO.PSON.ProgressivePair([])
ver = 0

setGame = (g, v, pid) ->
  if v > ver
    game = g
    drawGame($(".midpane"),game, pid)
    ver = v

sendinfo = (info) ->
  bb = pson.encode info
  bb.flip()
  ws.send(bb.toBase64())

$(document).ready( ->
  $(".midpane").append '
    <form id="startform" > 
      Game Name: <input type="text" id="name" /> <br>
      # Players: <input type="text" id="players" /> <br>
      Your player #: <input type="text" id="num" /> <br>
      <input type="submit">
    </form>
      '
  $("#startform").submit( (event) ->
    ws = new WebSocket("ws://162.243.130.247:3000/ws")
    ws.onopen = (event) ->
      sendinfo
              gamename: $("#startform > #name").val()
              players: 1*$("#startform > #players").val()
              from: 1*$("#startform > #num").val()-1
      ws.pid = 1*$("#startform > #num").val()-1
    ws.onmessage = (message) ->
      data = dcodeIO.ByteBuffer.decode64(message.data)
      val = pson.decode(data)
      if val.type?
        if val.type == "game"
          g = new Game(val.game.players)
          g.hands = []
          g.deck = []
          extend(true,g,val.game)
          newcards = []
          for c in val.game.cards
            if c.known
              newcards.push(new Card(c.color,c.number))
            else
              newcards.push(new Card())
          g.cards = newcards
          setGame(g, val.ver, ws.pid)
        else if val.type == "move"
          console.log "No function for move yet"
      else
        console.log val
    event.preventDefault()
  )
)



