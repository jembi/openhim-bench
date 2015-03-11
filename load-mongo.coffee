fs = require 'fs'
MongoClient = require('mongodb').MongoClient
Server = require('mongodb').Server
ObjectID = require('mongodb').ObjectID
Q = require 'q'

batchSize = 250
concurrency = 8

args = process.argv
args.splice(0, 2)
numTxToInsert = args[0]
numInserted = 0

requ =
  path: "/api/test"
  headers:
    "header-title": "header1-value"
    "another-header": "another-header-value"
  querystring: "param1=value1&param2=value2"
  body: (fs.readFileSync 'resources/adhocRequest_wSoap.xml').toString()
  method: "POST"
  timestamp: "2014-06-09T11:17:25.929Z"

respo =
  status: "200"
  headers:
    header: "value"
    header2: "value2"
  body: (fs.readFileSync 'resources/pnr_wSOAP.xml').toString()
  timestamp: "2014-06-09T11:17:25.929Z"

transactionDoc =
  status: "Successful"
  clientID: "999999999999999999999999"
  channelID: "888888888888888888888888"
  request: requ
  response: respo
    
  routes:
    [
      name: "dummy-route"
      request: requ
      response: respo
    ]

  orchestrations:
    [
      name: "dummy-orchestration"
      request: requ
      response: respo
    ]
  properties: 
    property: "prop1", value: "prop1-value1"
    property:"prop2", value: "prop-value1"

#console.log transactions[0]

cloneObj = (obj) ->
  return JSON.parse(JSON.stringify(obj))

createAndInsertBatch = (coll, size) ->
  deferred = Q.defer()

  # for some reason we need a new object each time so ObjectIds don't clash
  batchTxs = []
  for i in [0..(size-1)]
    tx = cloneObj transactionDoc
    batchTxs.push tx

  coll.insert batchTxs, (err, result) ->
    if err?
      console.error err
      deferred.reject err
    else
      numInserted += size
      console.log "#{numInserted} records inserted"
      deferred.resolve()

  return deferred.promise

runClient = (clientNum, db, coll, numToInsert) ->
  deferred = Q.defer()

  if numToInsert < batchSize
    numBatches = 0
    remainder = numToInsert
  else
    numBatches = Math.floor(numToInsert / batchSize)
    remainder = numToInsert % batchSize

  console.log "Client #{clientNum}: Inserting #{numToInsert} transactions into mongo in #{numBatches + if remainder > 0 then 1 else 0} batch inserts"

  if numBatches > 0
    for i in [1..numBatches]
      if promiseChain?
        promiseChain = promiseChain.then ->
          createAndInsertBatch coll, batchSize
      else
        promiseChain = createAndInsertBatch coll, batchSize

  if remainder > 0
    if promiseChain?
      promiseChain = promiseChain.then ->
        createAndInsertBatch coll, remainder
    else
      promiseChain = createAndInsertBatch coll, remainder
      
  promiseChain.then ->
    console.log "Client #{clientNum}: All done!"
    deferred.resolve()

  return deferred.promise

mongoClient = new MongoClient new Server 'localhost', 27017
mongoClient.open (err, mongoClient) ->
  console.error err if err?

  db = mongoClient.db 'openhim-bench'
  coll = db.collection 'transactions'
  startTime = new Date()
  promises = []

  if numTxToInsert < concurrency
    console.log "Starting 1 client..."
    promises.push runClient 1, db, coll, Math.round(numTxToInsert)
  else
    console.log "Starting #{concurrency} clients..."
    for i in [1..concurrency]
      promises.push runClient i, db, coll, Math.round(numTxToInsert / concurrency)
  
  (Q.all promises).then ->
    db.close()
    console.log "Took #{(new Date() - startTime) / 1000}s"