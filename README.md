OpenHIM Benchmarking Suite
==========================

Benchmarks for the [OpenHIM](http://openhim.org).

Usage
-----

Run the suite as follows: `./openhim-bench.sh [OPTIONS...]`

Run a Benchmark Suite on an OpenHIM instance. The suite will manage the OpenHIM and mediator instances unless the -s option is used. If used, your OpenHIM instance will need to be configured correctly for the tests. You can use the /config/core-conf-mongo-setup.js script to setup your mongo instance with the correct channels and client.

OPTIONS are:
    -b BRANCH
        Benchmark a particular github branch. Defaults to master.
    -h 
        Print help and exit.
    -o
        Include the OpenHIE suite. Disabled by default. The benchmark suite will manage the mediator and mock registries. If you want to use your own registries, specify this configuration using the -x parameter. If not -x is not specified, config/xds-mediator.properties will be used by default.
    -r BRANCH
        [OpenHIE Suite] Benchmark a particular github branch for the mediator. Defaults to master.
    -s TARGET
        Self managed instance. The benchmark suite will not manage the OpenHIM and mediator instances. A TARGET for the benchmark must be specified and takes the form HOSTNAME:PORT (WITHOUT anything extra like the scheme, paths or forward slashes)
    -x MEDIATOR_PROPERTIES
        [OpenHIE Suite] A file containing the XDS.b Mediator properties. You can create a copy of config/xds-mediator.properties to get you started.
