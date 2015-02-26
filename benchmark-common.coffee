loadtest = require 'loadtest'

exports.getHostAndPort = ->
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

  return res


exports.runBenchmarks = runBenchmarks = (host, port, benchmarks) ->
  return if benchmarks.length is 0

  benchmark = benchmarks[0](host, port)
  console.log "\nBenchmark: #{benchmark.name}"

  loadtest.loadTest benchmark.options, (err, results) ->
    if err
      console.log err
    else
      #TODO something more exiting with the results! e.g. html reports
      console.log results

    runBenchmarks host, port, benchmarks[1..]
