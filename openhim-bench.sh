#!/bin/bash

help=$(cat <<EOF
Usage: $0 [OPTIONS...]

Run a Benchmark Suite on an OpenHIM instance. The suite will manage the OpenHIM and mediator instances unless the -s option is used. If used, your OpenHIM instance will need to be configured correctly for the tests. You can use the /config/core-conf-mongo-setup.js script to setup your mongo instance with the correct channels and client.

Benchmark results will be saved in mongo (openhim-bench-results) and an html report will be generated, available in the results/ folder.

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
    -p
        Profile the application using perf_events and produce a flame graph in the results. Note: You must allow perf to run in userspace to run this without root. To do this execute: echo '-1' | sudo tee /proc/sys/kernel/perf_event_paranoid. Can only be used with NON-self-managed instances.
    -l N
        Load the mongodb with N transactions, where N is a number. Note: 100 000 transaction takes about 2mins (and 6GB) and 1 000 000 transactions takes about 20mins (and 60GB!). Can only be used with NON-self-managed instances.

EOF
)

branch="master"
url="localhost:6001"
selfManaged=false
profile=false
load=0

openhieSuite=false
xdsMediatorBranch="master"
xdsProps="config/xds-mediator.properties"


while getopts ":b:hor:s:xpl:" opt; do
    case $opt in
        b)
            branch=$OPTARG
            ;;
        h)
            echo "${help}" >&2
            exit 0
            ;;
        o)
            openhieSuite=true
            ;;
        r)
            xdsMediatorBranch=$OPTARG
            ;;
        s)
            selfManaged=true
            url=$OPTARG
            ;;
        x)
            xdsProps=$OPTARG
            ;;
        p)
            profile=true
            ;;
        l)
            load=$OPTARG
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done


function unlockAndExit {
    rm -f .lock;
    exit $1;
}

# Locking

if [ -f .lock ]; then
    echo "It looks like another benchmark instance is already running. Aborting.";
    echo -e "\nIf you believe this to be an error, then delete the .lock file manually and try again.";
    exit 0;
fi

touch .lock;


# Dependencies

echo -n "Checking dependencies... "
git --version >/dev/null 2>&1 || { echo "git is required but is not installed." >&2; unlockAndExit 1; }
node --version >/dev/null 2>&1 || { echo "node.js is required but is not installed." >&2; unlockAndExit 1; }
npm --version >/dev/null 2>&1 || { echo "npm is required but is not installed." >&2; unlockAndExit 1; }
coffee --version >/dev/null 2>&1 || { echo "coffee-script is required but is not installed. Have you installed it globally?" >&2; unlockAndExit 1; }
mongo --version >/dev/null 2>&1 || { echo "mongodb is required but is not installed." >&2; unlockAndExit 1; }
if [ "$openhieSuite" = true ]; then
    javac -version >/dev/null 2>&1 || { echo "jdk is required for the OpenHIE suite but is not installed." >&2; unlockAndExit 1; }
    mvn -version >/dev/null 2>&1 || { echo "maven is required for the OpenHIE suite but is not installed." >&2; unlockAndExit 1; }
    perl -version >/dev/null 2>&1 || { echo "perl is required for the OpenHIE suite but is not installed." >&2; unlockAndExit 1; }
fi
if [ "$profile" = true ]; then
    perf --version >/dev/null 2>&1 || { echo "perf_events is required but is not installed." >&2; unlockAndExit 1; }
fi
echo "done"


corePID=""
xdsMediatorPID=""

mockServicePID=""

mockatnaPID=""
mockcsdPID=""
mockpixPID=""
mockregPID=""
mockrepPID=""

perfPID=""

gitCommitHash=""

function pushdir {
    pushd . > /dev/null 2>&1;
}

function popdir {
    popd > /dev/null 2>&1;
}


# Clear logs and previous results

rm -f logs/*;
rm -fR results/*;

# npm install

echo -n "Running npm install... ";
npm install > logs/npm-install.log 2>&1;
echo "done";

# Install flamegraph tools

if [ "$profile" = true ]; then
    echo -n "Preparing flamegraph tools... ";

    pushdir
        cd workspace;

        if [ ! -d "FlameGraph" ]; then
            echo -e "\nCloning https://github.com/brendangregg/FlameGraph.git"
            git clone https://github.com/brendangregg/FlameGraph.git >> ../logs/flame-graph-setup.log 2>&1;
        fi

        pushdir
            cd FlameGraph;
            git pull >> ../../logs/flame-graph-setup.log 2>&1;
        popdir
    popdir

    echo "done";
fi

# Manage instances

if [ "$selfManaged" = false ]; then
    echo -n "Preparing OpenHIM core, mediators and mock services... ";

    pushdir
        cd workspace;

        echo "Setting up OpenHIM core..." > ../logs/openhim-core-setup.log 2>&1;
        if [ ! -d "openhim-core-js" ]; then
            echo -e "\nCloning https://github.com/jembi/openhim-core-js.git"
            git clone https://github.com/jembi/openhim-core-js.git >> ../logs/openhim-core-setup.log 2>&1;
        fi

        pushdir
            cd openhim-core-js;

            git pull >> ../../logs/openhim-core-setup.log 2>&1;
            git checkout $branch >> ../../logs/openhim-core-setup.log 2>&1;

            npm install >> ../../logs/openhim-core-setup.log 2>&1;
            if [ $? -ne 0 ]; then
                echo -e "\nA problem occurred while building core. Check the logs for details.";
                unlockAndExit 1;
            fi

            gitCommitHash=`git rev-parse HEAD`;
        popdir

        if [ "$openhieSuite" = true ]; then
            echo "Setting up XDS.b Mediator..." > ../logs/xds-mediator-setup.log 2>&1;

            if [ ! -d "openhim-mediator-xds" ]; then
                echo -e "\nCloning https://github.com/jembi/openhim-mediator-xds.git"
                git clone https://github.com/jembi/openhim-mediator-xds.git >> ../logs/xds-mediator-setup.log 2>&1;
            fi

            pushdir
                cd openhim-mediator-xds;

                git pull >> ../../logs/xds-mediator-setup.log 2>&1;
                git checkout $xdsMediatorBranch >> ../../logs/xds-mediator-setup.log 2>&1;

                mvn install -DskipTests=true >> ../../logs/xds-mediator-setup.log 2>&1;
                if [ $? -ne 0 ]; then
                    echo -e "\nA problem occurred while building the XDS.b mediator. Check the logs for details.";
                    unlockAndExit 1;
                fi
            popdir
        fi
    popdir
    echo "done"

    echo -n "Configuring client and channels... "
    mongo config/core-conf-mongo.setup.js > logs/mongo-config.log 2>&1;
    echo "done"

    if [ "$load" -gt 0 ]; then
        echo -n "Loading database with "$load" documents... "
        coffee load-mongo.coffee $load
        echo "done"
        echo -n "Giving the system 30s to recover before running performance tests... "
        sleep 30;
        echo "done"
    fi

    pushdir
        cd workspace/openhim-core-js;
        echo -n "Starting OpenHIM core... ";
        if [ "$profile" = true ]; then
            node --perf-basic-prof --harmony lib/server.js --conf=../../config/core-conf.json > ../../logs/openhim-core.log 2>&1 &
            corePID=$!;
            sleep 10; # give the process a chance to startup
            echo -e "\n  Profiling PID = "$corePID
            perf record -q -F 99 -p $corePID -g > /dev/null 2>&1 & 
            perfPID=$!;
        else
            node --harmony lib/server.js --conf=../../config/core-conf.json > ../../logs/openhim-core.log 2>&1 &
            corePID=$!;
            sleep 10; # give the process a chance to startup
        fi
        echo "done"
    popdir

    if [ "$openhieSuite" = true ]; then
        echo -n "Starting XDS.b Mediator... ";
        java -jar workspace/openhim-mediator-xds/target/mediator-xds-1.0.0-jar-with-dependencies.jar --conf $xdsProps > logs/xds-mediator.log 2>&1 &
        xdsMediatorPID=$!;
        sleep 5; # give the process a chance to startup
        echo "done";
    fi

    echo -n "Starting mock services... "
    coffee mock-service.coffee > /dev/null 2>&1 &
    mockServicePID=$!;

    if [ "$openhieSuite" = true ]; then
        pushdir
            cd workspace/openhim-mediator-xds/src/test/resources/mock-services
            ./mock-atna-server.pl > /dev/null 2>&1 &
            mockatnaPID=$!;
            node mock-csd-server.js > /dev/null 2>&1 &
            mockcsdPID=$!;
            node mock-pix-server.js > /dev/null 2>&1 &
            mockpixPID=$!;
            node mock-reg-server.js > /dev/null 2>&1 &
            mockregPID=$!;
            node mock-rep-server.js > /dev/null 2>&1 &
            mockrepPID=$!;
        popdir
    fi

    sleep 5; # give the processes a chance to startup
    echo "done";
fi


# Run benchmarks

echo "";
echo "Running benchmark-basic";
coffee benchmark-basic.coffee $url $gitCommitHash;
echo "";

if [ "$selfManaged" = false ]; then
    # Benchmark the mock service direclty at high concurrency
    # for comparison to the core results
    echo "Running benchmark-mockservice";
    coffee benchmark-mockservice.coffee "localhost:6050" $gitCommitHash;
    echo "";
fi

if [ "$openhieSuite" = true ]; then
    echo "Running benchmark-openhie";
    coffee benchmark-openhie.coffee $url $gitCommitHash;
    echo "";
fi

# Generate flame graph
if [ "$profile" = true ]; then
    echo "Generating flame chart... ";
    pushdir
        cd workspace;
        pushdir
            cd openhim-core-js;
            kill -SIGINT $perfPID
            sleep 2 # allow perf to write data
            perf script | ../FlameGraph/stackcollapse-perf.pl > ../out.perf-folded
            rm -f perf.data
        popdir
        ./FlameGraph/flamegraph.pl --color=js -title="OpenHIM (green == JS, aqua == built-ins, yellow == C++, red == system)" out.perf-folded > perf-openhim.svg
        rm out.perf-folded
    popdir
    echo "done";
fi

# Generate report

echo -n "Generating report... ";

pushdir
    cd results;
    tar -xzf ../resources/report-assets.tar.gz;
    chmod 755 assets;
    chmod 755 assets/*;
    if [ "$profile" = true ]; then
        mv ../workspace/perf-openhim.svg assets/
    fi
popdir

if [ "$openhieSuite" = true ]; then
    coffee generate-report.coffee -o;
else
    coffee generate-report.coffee;
fi

echo "done";


# Shutdown instances

if [ "$selfManaged" = false ]; then
    echo -n "Cleaning up instances...";

    kill $corePID;
    kill $mockServicePID;

    if [ "$openhieSuite" = true ]; then
        kill $xdsMediatorPID;
        kill $mockatnaPID;
        kill $mockcsdPID;
        kill $mockpixPID;
        kill $mockregPID;
        kill $mockrepPID;
    fi

    mongo openhim-bench --eval "db.dropDatabase()" > /dev/null 2>&1

    echo "done";
fi

unlockAndExit 0
