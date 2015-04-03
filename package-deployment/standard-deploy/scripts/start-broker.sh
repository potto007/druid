#!/bin/bash
: echo ${JVM_MAX_DIRECT_MEM_SIZE:=64g}
: echo ${SELECT_TIER:=highestPriority}
: echo ${MAX_IDLE_TIME:=PT5m}
: echo ${USE_CACHE:=false}
: echo ${CACHE_TYPE:=local}
: echo ${CACHE_PREFIX:=$DRUID_CLUSTER_NAME}
# 30 days
: echo ${CACHE_EXPIRATION:=2592000}

CP=/opt/druid/config/broker:$CP
BROKER_JAVA_OPTS="-XX:NewSize=6g -XX:MaxNewSize=6g -XX:+UseConcMarkSweepGC -XX:MaxDirectMemorySize=${JVM_MAX_DIRECT_MEM_SIZE}"
BROKER_JAVA_PROPS="-Ddruid.broker.http.numConnections=${NUM_CONNECTIONS_PER_BROKER} -Ddruid.broker.cache.useCache=${USE_CACHE} -Ddruid.broker.cache.populateCache=${USE_CACHE} -Ddruid.cache.type=${CACHE_TYPE} -Ddruid.cache.memcachedPrefix=${CACHE_PREFIX} -Ddruid.cache.hosts=${MEMCACHED_HOSTS} -Ddruid.cache.expiration=${CACHE_EXPIRATION}  -Ddruid.broker.select.tier=${SELECT_TIER} -Ddruid.server.http.maxIdleTime=${MAX_IDLE_TIME}"

JAVA_COMMAND="java $COMMON_JAVA_PROPS $BROKER_JAVA_OPTS -cp $CP $COMMON_JAVA_OPTS $BROKER_JAVA_PROPS io.druid.cli.Main server broker"
echo $JAVA_COMMAND
$JAVA_COMMAND
