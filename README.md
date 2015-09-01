# Hanabi
Online implementation of the cardgame Hanabi in CoffeeScript / NodeJS.

This implementation includes the Rainbow suit and uses the rule variant where
rainbow cards are always included in every hint.

Very simple project with minimal UI. Once the server is running (defaults to
port 3001) enter a game name, the number of players and the player you want to
be.

For instance if Bob and Nancy are playing a game named "ThursdayNight", Bob
would enter:

- Game Name: ThursdayNight
- Number of Players: 2
- Player Number: 1

and Nancy would enter:

- Game Name: ThursdayNight
- Number of Players: 2
- Player Number: 2

And they would be in the same game. You probably have to be familiar with the
card game "Hanabi" for it to make any sense, and it probably makes sense to at
least be in a Skype call with the people you are playing with.

# Technologies

- Nodejs
- CoffeScript
- WebSockets
- Express
- Jade
- Nodeunit.

For awhile PSON and other serialization technologies were used, but code has
been modified to just use plain old JSON since then.

Note much of the actual game logic is written so that it is shared on the client
and the server.
