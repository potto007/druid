#!/bin/bash
: echo ${JVM_MAX_DIRECT_MEM_SIZE:=64g}
: echo ${SELECT_TIER:=highestPriority}
: echo ${MAX_IDLE_TIME:=PT5m}

CP=/opt/druid/config/broker:$CP
BROKER_JAVA_OPTS="-XX:NewSize=6g -XX:MaxNewSize=6g -XX:+UseConcMarkSweepGC -XX:MaxDirectMemorySize=${JVM_MAX_DIRECT_MEM_SIZE}"
BROKER_JAVA_PROPS="-Ddruid.broker.http.numConnections=${NUM_CONNECTIONS_PER_BROKER} -Ddruid.cache.hosts=${MEMCACHED_HOSTS} -Ddruid.broker.select.tier=${SELECT_TIER} -Ddruid.server.http.maxIdleTime=${MAX_IDLE_TIME}"

JAVA_COMMAND="java $COMMON_JAVA_PROPS $BROKER_JAVA_OPTS -cp $CP $COMMON_JAVA_OPTS $BROKER_JAVA_PROPS io.druid.cli.Main server broker"
echo $JAVA_COMMAND
$JAVA_COMMAND