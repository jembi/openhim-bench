loadtest = require 'loadtest'
MongoClient = require("mongodb").MongoClient
os = require 'os'

path = require 'path'
exports.appRoot = path.resolve(__dirname)

db = null


getSystemInfo = ->
  platform: os.platform()
  arch: os.arch()
  release: os.release()
  totalmem: os.totalmem()
  cpus: os.cpus()


exports.initMongo = initMongo = (callback) ->
  return callback null, db if db?
  # TODO make host configurable
  mongoHost = 'localhost'
  MongoClient.connect "mongodb://#{mongoHost}/openhim-bench-results", (err, database) ->
    return callback err, null if err
    db = database
    callback null, db

addResultsToMongo = (benchmarkName, results, gitCommitHash, callback) ->
  initMongo (err, db) ->
    return callback err if err

    key = benchmarkName.replace /[^\w]/g, ''

    mongoCollection = db?.collection key
    index = date: 1
    mongoCollection.ensureIndex date: 1, (err, indexName) ->
      return callback err if err
      results.name = benchmarkName
      results.date = new Date()
      results.system = getSystemInfo()
      results.gitCommitHash = gitCommitHash if gitCommitHash?
      mongoCollection.insert results, callback


params = null

getParams = ->
  return params if params?

  res = {}
  res.host = 'localhost'
  res.port = '5001'

  if process.argv.length > 2
    url = process.argv[2].split ':'
    if url.length < 2
      console.log "Invalid URL specified #{url}"
      process.exit 1
    res.host = url[0]
    res.port = url[1]

  if process.argv.length > 3
    res.gitCommitHash = process.argv[3] if process.argv[3]

  params = res
  console.log "Testing #{params.host}:#{params.port}"
  console.log "OpenHIM Git Commit: #{params.gitCommitHash}"
  return res

exports.exit = exit = (err) ->
  db.close()
  if err
    console.log err
    process.exit 1
  else
    process.exit 0

exports.runBenchmarks = runBenchmarks = (benchmarks) ->
  return exit null if benchmarks.length is 0

  params = getParams()

  benchmark = benchmarks[0](params.host, params.port)
  console.log "\nBenchmark: #{benchmark.name}"

  loadtest.loadTest benchmark.options, (err, results) ->
    return exit err if err

    console.log results

    addResultsToMongo benchmark.name, results, params.gitCommitHash, (err) ->
      return exit err if err
      runBenchmarks benchmarks[1..]
