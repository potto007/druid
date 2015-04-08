#!/bin/bash
CP=/opt/druid/config/historical:$CP

# If HTTP_NUM_THREADS is not set, then calculate it from the max expected concurrency from brokers.
: echo ${HTTP_NUM_THREADS:=`expr $NUM_CONNECTIONS_PER_BROKER \\* $MAX_NUM_BROKERS`}

: echo ${PROCESSING_BUFFER_SIZE_BYTES:=1073741824}
: echo ${PROCESSING_NUM_THREADS:=16}
: echo ${USE_CACHE:=false}
: echo ${CACHE_TYPE:=local}
: echo ${CACHE_PREFIX:=$DRUID_CLUSTER_NAME}
# 30 days
: echo ${CACHE_EXPIRATION:=2592000}
#default is 0 like druid default.  Bigger = higher priority.
: echo ${SERVER_PRIORITY:=0}

#  Needs to be based on the size of the local cache disk available to this historical node.
#  Should really have no default.
#: ${SERVER_MAX_SIZE:=5497559962838}

#  Druid gives this error-- so calculate to avoid it as a default:
#   Not enough direct memory.  
#   Please adjust -XX:MaxDirectMemorySize, druid.processing.buffer.sizeBytes, or druid.processing.numThreads: maxDirectMemory[12,240,683,008], memoryNeeded[18,253,611,008] = druid.processing.buffer.sizeBytes[1,073,741,824] * ( druid.processing.numThreads[16] + 1 )
NUM_THREADS_PLUS_ONE=`expr $PROCESSING_NUM_THREADS \\+ 1`
: ${JVM_MAX_DIRECT_MEM_SIZE:=`expr $PROCESSING_BUFFER_SIZE_BYTES \\* $NUM_THREADS_PLUS_ONE`}

HISTORICAL_JAVA_OPTS="-XX:NewSize=6g -XX:MaxNewSize=6g -XX:+UseConcMarkSweepGC -XX:MaxDirectMemorySize=${JVM_MAX_DIRECT_MEM_SIZE}"
HISTORICAL_JAVA_PROPS="-Ddruid.server.tier=${HISTORICAL_TIER} -Ddruid.server.priority=${SERVER_PRIORITY} -Ddruid.storageDirectory=${DEEPSTORAGE_DIRECTORY} -Ddruid.server.http.numThreads=${HTTP_NUM_THREADS} -Ddruid.processing.buffer.sizeBytes=${PROCESSING_BUFFER_SIZE_BYTES} -Ddruid.processing.numThreads=${PROCESSING_NUM_THREADS} -Ddruid.server.maxSize=${SERVER_MAX_SIZE} -Ddruid.segmentCache.locations=[{\"path\":\"/druid/local/historical/indexCache\",\"maxSize\":${SERVER_MAX_SIZE}}] -Ddruid.historical.cache.useCache=${USE_CACHE} -Ddruid.historical.cache.populateCache=${USE_CACHE} -Ddruid.cache.type=${CACHE_TYPE} -Ddruid.cache.memcachedPrefix=${CACHE_PREFIX} -Ddruid.cache.hosts=${MEMCACHED_HOSTS} -Ddruid.cache.expiration=${CACHE_EXPIRATION}"


JAVA_COMMAND="java $COMMON_JAVA_PROPS $HISTORICAL_JAVA_OPTS -cp $CP $COMMON_JAVA_OPTS $HISTORICAL_JAVA_PROPS io.druid.cli.Main server historical"
echo $JAVA_COMMAND
$JAVA_COMMAND
