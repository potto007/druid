#!/bin/bash
CP=/opt/druid/config/coordinator:$CP
COORDINATOR_JAVA_OPTS="-XX:NewSize=512m -XX:MaxNewSize=512m -XX:+UseConcMarkSweepGC"
COORDINATOR_JAVA_PROPS="-Ddruid.metadata.storage.connector.connectURI=${STORAGE_CONNECTOR_URI} -Ddruid.metadata.storage.connector.user=${STORAGE_CONNECTOR_USER} -Ddruid.metadata.storage.connector.password=${STORAGE_CONNECTOR_PASSWORD} -Ddruid.metadata.storage.tables.base=${METADATA_TABLE_BASE}"

JAVA_COMMAND="java $COMMON_JAVA_PROPS $COORDINATOR_JAVA_OPTS -cp $CP $COMMON_JAVA_OPTS $COORDINATOR_JAVA_PROPS io.druid.cli.Main server coordinator"
echo $JAVA_COMMAND
$JAVA_COMMAND