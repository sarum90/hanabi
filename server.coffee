
http = require "http"

httpfunc = (request, response) ->
  g = new Game(4)
  headers =
    'Content-Type': "text/plain"
  response.writeHead 200,headers
  response.write g.toString()
  response.end()

http.createServer(httpfunc).listen 8888

