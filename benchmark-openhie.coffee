bench = require './benchmark-common'
fs = require 'fs'

getEncounter10 = (host, port) ->
  name: 'OpenHIE Get Encounter 10'
  options:
    url: "http://#{host}:#{port}/xdsregistry"
    maxRequests: 10
    concurrency: 1
    method: 'POST'
    body: "#{fs.readFileSync "#{bench.appRoot}/resources/adhocRequest_wSoap.xml}"}"
    contentType: 'application/soap+xml'
    headers:
      Authorization: 'Basic YmVuY2g6YmVuY2g='

getEncounter10seconds = (host, port) ->
  name: 'OpenHIE Get Encounter 10 seconds'
  options:
    url: "http://#{host}:#{port}/xdsregistry"
    maxSeconds: 10
    concurrency: 1
    method: 'POST'
    body: "#{fs.readFileSync "#{bench.appRoot}/resources/adhocRequest_wSoap.xml}"}"
    contentType: 'application/soap+xml'
    headers:
      Authorization: 'Basic YmVuY2g6YmVuY2g='

saveEncounter10 = (host, port) ->
  name: 'OpenHIE Save Encounter 10'
  options:
    url: "http://#{host}:#{port}/xdsrepository"
    maxRequests: 10
    concurrency: 1
    method: 'POST'
    body: "#{fs.readFileSync "#{bench.appRoot}/resources/pnr_wSOAP.xml"}"
    contentType: 'application/soap+xml'
    headers:
      Authorization: 'Basic YmVuY2g6YmVuY2g='

saveEncounter10seconds = (host, port) ->
  name: 'OpenHIE Save Encounter 10 seconds'
  options:
    url: "http://#{host}:#{port}/xdsrepository"
    maxSeconds: 10
    concurrency: 1
    method: 'POST'
    body: "#{fs.readFileSync "#{bench.appRoot}/resources/pnr_wSOAP.xml"}"
    contentType: 'application/soap+xml'
    headers:
      Authorization: 'Basic YmVuY2g6YmVuY2g='


do ->
  target = bench.getHostAndPort()
  console.log "Testing #{target.host}:#{target.port}"

  benchmarks = [getEncounter10, getEncounter10seconds, saveEncounter10, saveEncounter10seconds]

  bench.runBenchmarks target.host, target.port, benchmarks
