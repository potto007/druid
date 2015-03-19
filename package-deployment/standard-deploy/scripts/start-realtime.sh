#!/bin/bash
# NOTE:  Above use "bin/bash" not "bin/sh" since $RANDOM is only available from bash.
CP=/opt/druid/config/realtime:$CP

# If peon mode is not set, then default to local
: ${PEON_MODE:=local}

# If HTTP_NUM_THREADS is not set, then calculate it from the max expected concurrency from brokers.
: ${HTTP_NUM_THREADS:=`expr $NUM_CONNECTIONS_PER_BROKER \\* $MAX_NUM_BROKERS`}

# If partition num not set, then use a random number.
: ${PARTITION_NUM:=$RANDOM}
INDEXER_ID=${PARTITION_NUM}_$(date +%Y-%m-%dT%H:%M:%S,%s)


REALTIME_JAVA_OPTS="-Xmx8g -Xms8g -XX:NewSize=256m -XX:MaxNewSize=256m -XX:MaxDirectMemorySize=8G -XX:+UseConcMarkSweepGC -XX:MaxGCPauseMillis=100"
REALTIME_JAVA_PROPS="-Ddruid.peon.mode=${PEON_MODE} -Ddruid.computation.buffer.size=268435456 -Ddruid.storageDirectory=${DEEPSTORAGE_DIRECTORY} -Ddruid.selectors.indexing.serviceName=${INDEXING_SERVICEMANAGER_NAME} -Ddruid.indexer.task.baseDir=/tmp -Ddruid.indexer.task.baseTaskDir=/tmp/persistent/tasks  -Ddruid.server.http.numThreads=${HTTP_NUM_THREADS} -Ddruid.metadata.storage.connector.connectURI=${STORAGE_CONNECTOR_URI} -Ddruid.metadata.storage.connector.user=${STORAGE_CONNECTOR_USER} -Ddruid.metadata.storage.connector.password=${STORAGE_CONNECTOR_PASSWORD} -Ddruid.metadata.storage.tables.base=${METADATA_TABLE_BASE}"

# Create our working directory
mkdir -p /tmp/persistent/tasks/${INDEXER_ID}
# make sure it is defined and not empty 
# Didn't work for bin/sh.
#if [[ $TEMPLATE_FILE_URL && ${TEMPLATE_FILE_URL-_} ]]
#then
  curl $TEMPLATE_FILE_URL > /tmp/persistent/tasks/${INDEXER_ID}/task_template.json
#fi

cat /tmp/persistent/tasks/${INDEXER_ID}/task_template.json | sed s/'<%= @partition %>'/${PARTITION_NUM}/g | sed s/'<%= @zk_connect %>'/${ZK_CONNECT}/g | sed s/'<%= @cluster %>'/${DRUID_CLUSTER_NAME}/g | sed s/'<%= @datasource %>'/${DATASOURCE}/g | sed s/'<%= @kafka_topic %>'/${KAFKA_TOPIC}/g | sed s/'<%= @query_granularity_duration %>'/${QUERY_GRANULARITY_DURATION}/g > /tmp/persistent/tasks/${INDEXER_ID}/task.json

# Mesos runs the docker container detached.  So there is no stdin.
# So based on https://github.com/druid-io/druid/blob/d7d712a6abf3aca4443cfeddc201a5dd5ad2a922/indexing-service/src/main/java/io/druid/indexing/worker/executor/ExecutorLifecycle.java#L112
# it will die before starting.
# So pipe a never ending stream into it.
tail -f ./emptyfile.txt | java $COMMON_JAVA_PROPS $REALTIME_JAVA_OPTS -cp $CP $REALTIME_JAVA_PROPS io.druid.cli.Main internal peon /tmp/persistent/tasks/${INDEXER_ID}/task.json /tmp/persistent/tasks/${INDEXER_ID}/status.json --nodeType realtime &

# Unforutnatly, piping the stream in means even after java dies, the pipe keeps running.  So the Docker container never ends.
# So run it in the background and then get its pid (the last background process)
pid=$!
# Print out a bit of debugging info in case this goes wrong.
ps -aux
echo $pid

# And now-- set up stuff to make sure the process cleanly exits when the process ends.

# If this script is killed, kill the java.
trap "kill $pid 2> /dev/null" EXIT
# While java is running, keep going.
while kill -0 $pid 2> /dev/null; do
    sleep 1
done
# Disable the trap on a normal exit.
trap - EXIT

# And exit the whole bash script to kill the docker container.
exit 2
