

express = require('express')
coffeeMid = require('coffee-middleware')
stylus = require('stylus')
infra = require('./server/infra')
serial = require('./common/serialize')
app = express()
path = require('path')
http = require('http')
cxns = require('./server/connections')




app.set('port', 3000)
app.set('views', __dirname + '/views')
app.set('view engine', 'jade')
app.use(express.favicon())
app.use(express.logger('dev'))

publicDir = path.join(__dirname, 'public')

app.use(express.urlencoded())
app.use(express.methodOverride())
app.use(express.cookieParser('2J3idnv943Qfai'))
app.use(express.session())
app.use(app.router)
app.use(stylus.middleware(publicDir))
app.use(express.static(publicDir))


app.get('/', (req, res) ->
  res.render('index', title: 'Hanabi')
)

app.get('/game/:name/p/:players/from/:player', (req, res) ->
  g = infra.getGame(req.params.name,req.params.players)
  if g?
    c = g.cloneFor(req.params.player)
    if c?
      res.send(serial.game(c))
    else
      res.send("Bad player number.")
  else
    res.send("Bad number of players.")
)

commonDir = __dirname + '/common'
clientDir = __dirname + '/client'

app.use coffeeMid
  src: commonDir
  compress: true
  prefix: '/js'
  force: true

app.use coffeeMid
  src: clientDir
  compress: true
  prefix: '/js'
  force: true


app.use(express.errorHandler())

server = http.createServer (app)
cxns.start(server)

server.listen 3000

