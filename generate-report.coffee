bench = require './benchmark-common'
moment = require 'moment'
fs = require 'fs'
Q = require 'q'

buildHtml = (results) ->
  """
<html>
<head>
  <title>OpenHIM Benchmark Results - #{moment().format('DD MMMM YYYY')}</title>
  <script src=\"assets/d3.v3.min.js\" charset=\"utf-8\"></script>
  <script src=\"assets/nv.d3.min.js\" charset=\"utf-8\"></script>
  <link href=\"assets/nv.d3.css\" rel=\"stylesheet\" type=\"text/css\">
</head>
<body>
  <h1>OpenHIM Benchmark Results - #{moment().format('DD MMMM YYYY')}</h1>
  <div id='system'>
    <h2>System</h2>
    <table>
      <theader/>
      <tbody>
        <tr><td><strong>Platform</strong></td><td>#{results.system?.platform}</td></tr>
        <tr><td><strong>Architecture</strong></td><td>#{results.system?.arch}</td></tr>
        <tr><td><strong>Release</strong></td><td>#{results.system?.release}</td></tr>
        <tr><td><strong>Total Memory</strong></td><td>#{results.system?.totalmem}</td></tr>
        #{
          for cpu, i in results.system?.cpus
            """<tr>
              <td><strong>#{if i is 0 then 'CPUs' else ''}</strong></td>
              <td>#{cpu.model} (#{cpu.speed} MHz)</td>
            </tr>"""
        }
      </tbody>
    <table>
  </div>
  <div id='total'>
    <h2>Total Requests</h2>
    <svg style='height:500px'> </svg>
  </div>
  <div id='rps'>
    <h2>Requests per Second</h2>
    Higher is better
    <svg style='height:500px'> </svg>
  </div>
  <div id='meanLatency'>
    <h2>Mean Latency (ms)</h2>
    Lower is better
    <svg style='height:500px'> </svg>
  </div>
  <div id='maxLatency'>
    <h2>Max Latency (ms)</h2>
    Lower is better
    <svg style='height:500px'> </svg>
  </div>
  <div id='mockService'>
    <h2>Comparison to Mock Service Results</h2>
    <table>
      <tbody>
        <tr><td><strong>Mock Service</strong></td><td>#{results.mockServiceResults?.rps} RPS</td></tr>
        <tr><td><strong>OpenHIM Core</strong></td><td>#{results.comparisonForMockService} RPS</td></tr>
      </tbody>
    </table>
    <br/>
    Running the benchmarks against the mock service directly is roughly
    <strong>#{Math.round(results.mockServiceResults?.rps / results.comparisonForMockService)}X</strong>
    faster than routing through the OpenHIM first.
  </div>
  <div>
    <br/><br/><br/><small><italic>Generated on #{moment().format('YYYY-MM-DD HH:mm:ss')}</italic></small>
  </div>
  <script type=\"text/javascript\">

  function barGraph(component, data) {
    return function() {
      var chart = nv.models.discreteBarChart()
        .x(function(d) { return d.label })
        .y(function(d) { return d.value })
        .transitionDuration(350)
      ;

      d3.select(component)
        .datum(data)
        .call(chart);

      nv.utils.windowResize(chart.update);

      return chart;
    }
  }

  nv.addGraph(barGraph('#total svg', #{JSON.stringify [{key: "Total Requests", values: results.total }] }));
  nv.addGraph(barGraph('#rps svg', #{JSON.stringify [{key: "Requests Per Second", values: results.rps }] }));
  nv.addGraph(barGraph('#meanLatency svg', #{JSON.stringify [{key: "Mean Latency (ms)", values: results.meanLatency }] }));
  nv.addGraph(barGraph('#maxLatency svg', #{JSON.stringify [{key: "Max Latency (ms)", values: results.maxLatency }] }));
  </script>
</body>
</html>
"""


do -> bench.initMongo (err, db) ->
  return bench.exit err if err

  includeOpenhie = process.argv.length > 2 and process.argv[2] is '-o'

  db.collections (err, collections) ->
    collections = collections.map (c) -> c.collectionName

    benchmarkResults =
      system: null
      total: []
      rps: []
      meanLatency: []
      maxLatency: []
      mockServiceResults: null

    promises = []
    for c in collections
      do (c) ->
        deferred = Q.defer()

        collection = db.collection c
        collection.find({}, sort: { date: -1}).toArray (err, results) ->
          return bench.exit err if err

          if results?.length > 0 and results[0].name and results[0].rps
            if includeOpenhie or not results[0].name.toLowerCase().contains 'openhie'
              if not benchmarkResults.system
                benchmarkResults.system = results[0].system

              if c is 'MockServiceDirect'
                benchmarkResults.mockServiceResults = results[0]
              else
                benchmarkResults.total.push label: results[0].name, value: results[0].totalRequests
                benchmarkResults.rps.push label: results[0].name, value: results[0].rps
                benchmarkResults.meanLatency.push label: results[0].name, value: results[0].meanLatencyMs
                benchmarkResults.maxLatency.push label: results[0].name, value: results[0].maxLatencyMs

              if c is 'BasicGET10secondsHighlyConcurrent'
                benchmarkResults.comparisonForMockService = results[0].rps

          deferred.resolve()

        promises.push deferred.promise

    (Q.all promises).then ->
      fs.writeFile "results/index.html", buildHtml(benchmarkResults), -> bench.exit()
