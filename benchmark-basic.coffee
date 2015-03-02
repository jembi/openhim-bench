bench = require './benchmark-common'
fs = require 'fs'

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
      content: "#{fs.readFileSync "#{bench.appRoot}/resources/pnr_wSOAP.xml"}"
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
      content: "#{fs.readFileSync "#{bench.appRoot}/resources/pnr_wSOAP.xml"}"
    contentType: 'application/json'
    headers:
      Authorization: 'Basic YmVuY2g6YmVuY2g='

basicGET10secondConcurrent = (host, port) ->
  name: 'Basic GET 10 seconds Concurrent'
  options:
    url: "http://#{host}:#{port}/bench/basic/get"
    maxSeconds: 10
    concurrency: 4
    method: 'GET'
    headers:
      Authorization: 'Basic YmVuY2g6YmVuY2g='

basicPOST10secondConcurrent = (host, port) ->
  name: 'Basic POST 10 seconds Concurrent'
  options:
    url: "http://#{host}:#{port}/bench/basic/post"
    maxSeconds: 10
    concurrency: 4
    method: 'POST'
    body:
      bench: 'openhim'
      content: "#{fs.readFileSync "#{bench.appRoot}/resources/pnr_wSOAP.xml"}"
    contentType: 'application/json'
    headers:
      Authorization: 'Basic YmVuY2g6YmVuY2g='

basicGET10secondHighConcurrent = (host, port) ->
  name: 'Basic GET 10 seconds Highly Concurrent'
  options:
    url: "http://#{host}:#{port}/bench/basic/get"
    maxSeconds: 10
    concurrency: 20
    method: 'GET'
    headers:
      Authorization: 'Basic YmVuY2g6YmVuY2g='

basicPOST10secondHighConcurrent = (host, port) ->
  name: 'Basic POST 10 seconds Highly Concurrent'
  options:
    url: "http://#{host}:#{port}/bench/basic/post"
    maxSeconds: 10
    concurrency: 20
    method: 'POST'
    body:
      bench: 'openhim'
      content: "#{fs.readFileSync "#{bench.appRoot}/resources/pnr_wSOAP.xml"}"
    contentType: 'application/json'
    headers:
      Authorization: 'Basic YmVuY2g6YmVuY2g='


do ->
  target = bench.getHostAndPort()
  console.log "Testing #{target.host}:#{target.port}"

  benchmarks = [
    basicGET100, basicPOST100, basicGET10second, basicPOST10second,
    basicGET10secondConcurrent, basicPOST10secondConcurrent,
    basicGET10secondHighConcurrent, basicPOST10secondHighConcurrent
  ]

  bench.runBenchmarks target.host, target.port, benchmarks
