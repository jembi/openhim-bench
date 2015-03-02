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
        <tr><td><strong>Total Memory</strong></td><td>#{Math.round( results.system?.totalmem / (1024*1024) )} MiB</td></tr>
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
    <i>Higher is better</i>
    <svg style='height:500px'> </svg>
  </div>
  <div id='meanLatency'>
    <h2>Mean Latency (ms)</h2>
    <i>Lower is better</i>
    <svg style='height:500px'> </svg>
  </div>
  <div id='maxLatency'>
    <h2>Max Latency (ms)</h2>
    <i>Lower is better</i>
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
  <hr/>
  <h1>Comparison to Previous Benchmarks</h1>
  <div id='basic100TimeSeries'>
    <h2>Basic 100 Time Taken</h2>
    <i>Lower is better</i>
    <svg style='height:500px'> </svg>
  </div>
  <div id='getRPSTimeSeries'>
    <h2>GET Requests Per Second</h2>
    <i>Higher is better</i>
    <svg style='height:500px'> </svg>
  </div>
  <div id='postRPSTimeSeries'>
    <h2>POST Requests Per Second</h2>
    <i>Higher is better</i>
    <svg style='height:500px'> </svg>
  </div>
  <div id='getLatencyTimeSeries'>
    <h2>GET Mean Latency</h2>
    <i>Lower is better</i>
    <svg style='height:500px'> </svg>
  </div>
  <div id='postLatencyTimeSeries'>
    <h2>POST Mean Latency</h2>
    <i>Lower is better</i>
    <svg style='height:500px'> </svg>
  </div>
  <hr/>
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

  function lineGraph(component, yLabel, data) {
    return function() {
      var chart = nv.models.lineChart()
        .margin({left: 100, right: 50})
      ;

      chart.xAxis
        .tickFormat(function(d) {
          return d3.time.format('%Y-%m-%d')(new Date(d))
      });
      chart.yAxis
        .axisLabel(yLabel)
        .tickFormat(function(d) {
          return d;
      });

      d3.select(component)
        .datum(data)
        .call(chart);

      nv.utils.windowResize(chart.update);

      return chart;
    }
  };

  nv.addGraph(barGraph('#total svg', #{JSON.stringify [{key: "Total Requests", values: results.total }] }));
  nv.addGraph(barGraph('#rps svg', #{JSON.stringify [{key: "Requests Per Second", values: results.rps }] }));
  nv.addGraph(barGraph('#meanLatency svg', #{JSON.stringify [{key: "Mean Latency (ms)", values: results.meanLatency }] }));
  nv.addGraph(barGraph('#maxLatency svg', #{JSON.stringify [{key: "Max Latency (ms)", values: results.maxLatency }] }));
  nv.addGraph(lineGraph(
    '#basic100TimeSeries svg', 'Time (s)',
    #{JSON.stringify [
      {key: "Basic GET 100", values: results.basicGET100TimeSeries },
      {key: "Basic POST 100", values: results.basicPOST100TimeSeries }
    ]})
  );
  nv.addGraph(lineGraph(
    '#getRPSTimeSeries svg', 'RPS',
    #{JSON.stringify [
      {key: "10s", values: results.basicGET10sTimeSeries },
      {key: "10s Concurrent", values: results.basicGET10sConcurrentTimeSeries },
      {key: "10s Highly Concurrent", values: results.basicGET10sHighConcurrentTimeSeries }
    ]})
  );
  nv.addGraph(lineGraph(
    '#postRPSTimeSeries svg', 'RPS',
    #{JSON.stringify [
      {key: "10s", values: results.basicPOST10sTimeSeries },
      {key: "10s Concurrent", values: results.basicPOST10sConcurrentTimeSeries },
      {key: "10s Highly Concurrent", values: results.basicPOST10sHighConcurrentTimeSeries }
    ]})
  );
  nv.addGraph(lineGraph(
    '#getLatencyTimeSeries svg', 'Mean Latency (ms)',
    #{JSON.stringify [
      {key: "100", values: results.basicGET10sMeanLatencyTimeSeries },
      {key: "10s", values: results.basicGET10sMeanLatencyTimeSeries },
      {key: "10s Concurrent", values: results.basicGET10sConcurrentMeanLatencyTimeSeries },
      {key: "10s Highly Concurrent", values: results.basicGET10sHighConcurrentMeanLatencyTimeSeries }
    ]})
  );
  nv.addGraph(lineGraph(
    '#postLatencyTimeSeries svg', 'Mean Latency (ms)',
    #{JSON.stringify [
      {key: "100", values: results.basicPOST10sMeanLatencyTimeSeries },
      {key: "10s", values: results.basicPOST10sMeanLatencyTimeSeries },
      {key: "10s Concurrent", values: results.basicPOST10sConcurrentMeanLatencyTimeSeries },
      {key: "10s Highly Concurrent", values: results.basicPOST10sHighConcurrentMeanLatencyTimeSeries }
    ]})
  );
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
      basicGET100TimeSeries: []
      basicPOST100TimeSeries: []
      basicGET10sTimeSeries: []
      basicPOST10sTimeSeries: []
      basicGET10sConcurrentTimeSeries: []
      basicPOST10sConcurrentTimeSeries: []
      basicGET10sHighConcurrentTimeSeries: []
      basicPOST10sHighConcurrentTimeSeries: []
      basicGET100MeanLatencyTimeSeries: []
      basicPOST100MeanLatencyTimeSeries: []
      basicGET10sMeanLatencyTimeSeries: []
      basicPOST10sMeanLatencyTimeSeries: []
      basicGET10sConcurrentMeanLatencyTimeSeries: []
      basicPOST10sConcurrentMeanLatencyTimeSeries: []
      basicGET10sHighConcurrentMeanLatencyTimeSeries: []
      basicPOST10sHighConcurrentMeanLatencyTimeSeries: []

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

              pushResults = (series, metric, results) ->
                format = (date) -> moment(date).format('YYYY-MM-DD')
                for r in results
                  # only add the last item for each day
                  if series.length is 0 or format(series[ series.length-1 ].x) isnt format(r.date)
                    series.push x: +r.date, y: r["#{metric}"]

              if c is 'BasicGET100'
                pushResults benchmarkResults.basicGET100TimeSeries, 'totalTimeSeconds', results
                pushResults benchmarkResults.basicGET100MeanLatencyTimeSeries, 'meanLatencyMs', results
              if c is 'BasicPOST100'
                pushResults benchmarkResults.basicPOST100TimeSeries, 'totalTimeSeconds', results
                pushResults benchmarkResults.basicPOST100MeanLatencyTimeSeries, 'meanLatencyMs', results

              if c is 'BasicGET10seconds'
                pushResults benchmarkResults.basicGET10sTimeSeries, 'rps', results
                pushResults benchmarkResults.basicGET10sMeanLatencyTimeSeries, 'meanLatencyMs', results
              if c is 'BasicPOST10seconds'
                pushResults benchmarkResults.basicPOST10sTimeSeries, 'rps', results
                pushResults benchmarkResults.basicPOST10sMeanLatencyTimeSeries, 'meanLatencyMs', results
              if c is 'BasicGET10secondsConcurrent'
                pushResults benchmarkResults.basicGET10sConcurrentTimeSeries, 'rps', results
                pushResults benchmarkResults.basicGET10sConcurrentMeanLatencyTimeSeries, 'meanLatencyMs', results
              if c is 'BasicPOST10secondsConcurrent'
                pushResults benchmarkResults.basicPOST10sConcurrentTimeSeries, 'rps', results
                pushResults benchmarkResults.basicPOST10sConcurrentMeanLatencyTimeSeries, 'meanLatencyMs', results
              if c is 'BasicGET10secondsHighlyConcurrent'
                pushResults benchmarkResults.basicGET10sHighConcurrentTimeSeries, 'rps', results
                pushResults benchmarkResults.basicGET10sHighConcurrentMeanLatencyTimeSeries, 'meanLatencyMs', results
              if c is 'BasicPOST10secondsHighlyConcurrent'
                pushResults benchmarkResults.basicPOST10sHighConcurrentTimeSeries, 'rps', results
                pushResults benchmarkResults.basicPOST10sHighConcurrentMeanLatencyTimeSeries, 'meanLatencyMs', results

              if c is 'BasicGET10secondsHighlyConcurrent'
                benchmarkResults.comparisonForMockService = results[0].rps

          deferred.resolve()

        promises.push deferred.promise

    (Q.all promises).then ->
      fs.writeFile "results/index.html", buildHtml(benchmarkResults), -> bench.exit()
