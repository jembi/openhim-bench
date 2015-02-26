#!/bin/bash

help=$(cat <<EOF
Usage: $0 [OPTIONS...]

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

EOF
)

branch="master"
url="localhost:6001"
selfManaged=false

openhieSuite=false
xdsMediatorBranch="master"
xdsProps="config/xds-mediator.properties"


while getopts ":b:hor:s:x" opt; do
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


echo -n "Checking dependencies... "
git --version >/dev/null 2>&1 || { echo "git is required but is not installed." >&2; exit 1; }
node --version >/dev/null 2>&1 || { echo "node.js is required but is not installed." >&2; exit 1; }
npm --version >/dev/null 2>&1 || { echo "npm is required but is not installed." >&2; exit 1; }
coffee --version >/dev/null 2>&1 || { echo "coffee-script is required but is not installed. Have you installed it globally?" >&2; exit 1; }
mongo --version >/dev/null 2>&1 || { echo "mongodb is required but is not installed." >&2; exit 1; }
if [ "$openhieSuite" = true ]; then
    javac -version >/dev/null 2>&1 || { echo "jdk is required for the OpenHIE suite but is not installed." >&2; exit 1; }
    mvn -version >/dev/null 2>&1 || { echo "maven is required for the OpenHIE suite but is not installed." >&2; exit 1; }
    perl -version >/dev/null 2>&1 || { echo "perl is required for the OpenHIE suite but is not installed." >&2; exit 1; }
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

function pushdir {
    pushd . > /dev/null 2>&1;
}

function popdir {
    popd > /dev/null 2>&1;
}


# Clear logs

rm -f logs/*;

# npm install

echo -n "Running npm install... ";
npm install > logs/npm-install.log 2>&1;
echo "done";


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
                exit 1;
            fi
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
                    exit 1;
                fi
            popdir
        fi
    popdir
    echo "done"

    echo -n "Configuring client and channels... "
    mongo config/core-conf-mongo.setup.js > logs/mongo-config.log 2>&1;
    echo "done"

    pushdir
        cd workspace/openhim-core-js;
        echo -n "Starting OpenHIM core... ";
        node --harmony lib/server.js --conf=../../config/core-conf.json > ../../logs/openhim-core.log 2>&1 &
        corePID=$!;
        sleep 10; # give the process a chance to startup
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
coffee benchmark-basic.coffee $url;
echo "";

if [ "$openhieSuite" = true ]; then
    echo "Running benchmark-openhie";
    coffee benchmark-openhie.coffee $url;
    echo "";
fi


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

    echo "done";
fi
