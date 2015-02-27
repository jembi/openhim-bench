bench = require './benchmark-common'


mockService = (host, port) ->
  name: 'Mock Service Directly'
  options:
    url: "http://#{host}:#{port}/bench/basic/post"
    maxSeconds: 10
    concurrency: 20
    method: 'GET'
    body:
      bench: 'openhim'
    contentType: 'application/json'
    headers:
      Authorization: 'Basic YmVuY2g6YmVuY2g='


do ->
  target = bench.getHostAndPort()
  console.log "Testing #{target.host}:#{target.port}"

  benchmarks = [mockService]

  bench.runBenchmarks target.host, target.port, benchmarks
