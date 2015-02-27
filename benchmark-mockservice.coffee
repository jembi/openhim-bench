bench = require './benchmark-common'


mockService = (host, port) ->
  name: 'Mock Service Direct'
  options:
    url: "http://#{host}:#{port}/bench/basic/get"
    maxSeconds: 10
    concurrency: 20
    method: 'GET'
    body:
      bench: 'openhim'
    contentType: 'application/json'


do ->
  target = bench.getHostAndPort()
  console.log "Testing #{target.host}:#{target.port}"

  benchmarks = [mockService]

  bench.runBenchmarks target.host, target.port, benchmarks
