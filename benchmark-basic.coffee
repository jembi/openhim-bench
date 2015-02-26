bench = require './benchmark-common'

basicGET100 = (host, port) ->
  name: 'Basic GET 100'
  options:
    url: "http://#{host}:#{port}/bench/basic/get"
    maxRequests: 100
    concurrency: 1
    method: 'GET'
    headers:
      Authorization: 'Basic YmVuY2g6YmVuY2g='

basicPOST100 = (host, port) ->
  name: 'Basic POST 100'
  options:
    url: "http://#{host}:#{port}/bench/basic/post"
    maxRequests: 100
    concurrency: 1
    method: 'POST'
    body:
      bench: 'openhim'
    contentType: 'application/json'
    headers:
      Authorization: 'Basic YmVuY2g6YmVuY2g='

basicGET10second = (host, port) ->
  name: 'Basic GET 10 seconds'
  options:
    url: "http://#{host}:#{port}/bench/basic/get"
    maxSeconds: 10
    concurrency: 1
    method: 'GET'
    headers:
      Authorization: 'Basic YmVuY2g6YmVuY2g='

basicPOST10second = (host, port) ->
  name: 'Basic POST 10 seconds'
  options:
    url: "http://#{host}:#{port}/bench/basic/post"
    maxSeconds: 10
    concurrency: 1
    method: 'POST'
    body:
      bench: 'openhim'
    contentType: 'application/json'
    headers:
      Authorization: 'Basic YmVuY2g6YmVuY2g='


do ->
  target = bench.getHostAndPort()
  console.log "Testing #{target.host}:#{target.port}"

  benchmarks = [basicGET100, basicPOST100, basicGET10second, basicPOST10second]

  bench.runBenchmarks target.host, target.port, benchmarks
