#!/bin/bash
CP=/opt/druid/config/broker:$CP
BROKER_JAVA_OPTS="-Xmx50g -Xms50g -XX:NewSize=6g -XX:MaxNewSize=6g -XX:MaxDirectMemorySize=64g -XX:+UseConcMarkSweepGC"
BROKER_JAVA_PROPS="-Ddruid.broker.http.numConnections=${NUM_CONNECTIONS_PER_BROKER} -Ddruid.cache.hosts=${MEMCACHED_HOSTS}"

java $COMMON_JAVA_PROPS $BROKER_JAVA_OPTS -cp $CP $BROKER_JAVA_PROPS io.druid.cli.Main server broker