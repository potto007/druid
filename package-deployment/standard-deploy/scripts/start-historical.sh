#!/bin/bash
CP=/opt/druid/config/historical:$CP

# If HTTP_NUM_THREADS is not set, then calculate it from the max expected concurrency from brokers.
: ${HTTP_NUM_THREADS:=`expr $NUM_CONNECTIONS_PER_BROKER \\* $MAX_NUM_BROKERS`}

HISTORICAL_JAVA_OPTS="-XX:NewSize=6g -XX:MaxNewSize=6g -XX:+UseConcMarkSweepGC"
HISTORICAL_JAVA_PROPS="-Ddruid.server.tier=${HISTORICAL_TIER} -Ddruid.storageDirectory=${DEEPSTORAGE_DIRECTORY} -Ddruid.server.http.numThreads=${HTTP_NUM_THREADS}"


java $COMMON_JAVA_PROPS $HISTORICAL_JAVA_OPTS -cp $CP $COMMON_JAVA_OPTS $HISTORICAL_JAVA_PROPS io.druid.cli.Main server historical