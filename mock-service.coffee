express = require 'express'
bodyParser = require 'body-parser'

app = express()
app.use bodyParser.json()

app.get "/bench/basic/get", (req, res) -> res.send "Basic GET"

app.post "/bench/basic/post", (req, res) ->
  if req.body?.bench is 'openhim'
    res.sendStatus 201
  else
    res.sendStatus 500


server = app.listen 6050, () ->
  console.log "Mock service running on #{server.address().port}"
