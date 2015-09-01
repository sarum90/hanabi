
hanabi = require('../common/game')

games = {}


this.getGame = (name, players) ->
  console.log name+":"+players
  if players < 2 || players > 5
    return null
  key = "#{players}-#{name}"
  if not games[key]?
    games[key] = new hanabi.Game(players)
  return games[key]

