#!/bin/bash

#  Use DRUID_CLUSTER_NAME for all these "cluster name" type parameters if they aren't expliciltly set.
# Use echo to prevent the "/" causing the variable to be executed as a directory
: echo ${ZK_BASE_PATH:=$DRUID_CLUSTER_NAME}
: echo ${METADATA_TABLE_BASE:=$DRUID_CLUSTER_NAME}
: echo ${SOURCE_PROCESS_CLUSTER:=/$DRUID_CLUSTER_NAME}

#  If not set, default to druid's normal default of overlord.
#  Only matters if running peons in remote mode (PEON_MODE=remote) instead of local.
: echo ${INDEXING_SERVICEMANAGER_NAME:=overlord}
#  Not sure if we want it prefixed by the ZK_BASE_PATH in the name? 
#  I think not?
# INDEXING_SERVICEMANAGER_NAME=${ZK_BASE_PATH}:${INDEXING_SERVICEMANAGER_NAME}

#  Don't use "com.metamx.metrics.SysMonitor" since  Sigar needs to read /dev which in docker seems to not be readable or volume mountable.
# : echo ${MONITORING_MONITORS:="[\"com.metamx.metrics.JvmMonitor\",\"io.druid.server.metrics.ServerMonitor\"]"}
if ! [ -n "$MONITORING_MONITORS" ]; then
   if [ $1 = "historical" ]; then
      MONITORING_MONITORS="[\"com.metamx.metrics.JvmMonitor\",\"io.druid.server.metrics.ServerMonitor\"]"
   else
      MONITORING_MONITORS="[\"com.metamx.metrics.JvmMonitor\"]"
   fi
   echo "Warning:  Using default MONITORING_MONITORS: ${MONITORING_MONITORS}.  Set Environment variable to override."
fi


CP=/opt/druid/config/_common:/opt/druid/lib/*:/opt/druid/lib/logger/*
# Also allow EXTRA_JAVA_PROPS to be passed ass an environment variable.
# Since that seems to contain nested environment variables inside the string (e.g. like "\$VAR1", do some bash magic to evaluate them now.
EVALUATED_EXTRA_JAVA_OPTS=$(eval echo $EXTRA_JAVA_OPTS) 
COMMON_JAVA_PROPS="-server -Duser.timezone=UTC -Dfile.encoding=UTF-8 -Ddruid.host=${HOST}:${PORT} -Ddruid.port=${PORT} -Dlog4j.configurationFile=$LOG4J_CONFIG_FILE -Djava.io.tmpdir=/tmp -Ddruid.zk.service.host=${ZK_CONNECT} -Ddruid.zk.paths.base=${ZK_BASE_PATH} -Ddruid.discovery.curator.path=${ZK_BASE_PATH}/discovery -Ddruid.extensions.remoteRepository=[] -Ddruid.extensions.localRepository=/opt/druid/deps -Ddruid.extensions.coordinates=${EXTENSION_COORDINATES} -Ddruid.monitoring.monitors=${MONITORING_MONITORS} ${EVALUATED_EXTRA_JAVA_OPTS}"

if [ $1 = "historical" ]; then
	source $(dirname $0)/start-historical.sh
elif [ $1 = "broker" ]; then
	source $(dirname $0)/start-broker.sh
elif [ $1  = "coordinator" ]; then
	source $(dirname $0)/start-coordinator.sh
elif [ $1 = "realtime" ]; then
	source $(dirname $0)/start-realtime.sh
else echo "Usage:   ./start-service.sh <sevice_name>     where service_name in {historical, broker, coordinator, realtime} "
fi
