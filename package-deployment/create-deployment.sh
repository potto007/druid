#!/bin/bash

# There are two directories we care about:
# 1.  The directory where this shell script is deployed
# 2.  The directory the user is running from where we want to package things to
# Dynamically determine them.
if [ -z "$PROG_HOME" ] ; then
  ## resolve links - $0 may be a link to PROG_HOME
  PRG="$0"

  # need this for relative symlinks
  while [ -h "$PRG" ] ; do
    ls=`ls -ld "$PRG"`
    link=`expr "$ls" : '.*-> \(.*\)$'`
    if expr "$link" : '/.*' > /dev/null; then
      PRG="$link"
    else
      PRG="`dirname "$PRG"`/$link"
    fi
  done

  saveddir=`pwd`

  PROG_HOME=`dirname "$PRG"`/..

  # make it fully qualified
  PROG_HOME=`cd "$PROG_HOME" && pwd`
  directory=`dirname "$PRG"`
  cd "$saveddir"
fi



PROG_DIR=${directory}
BASE_DIR=${PROG_DIR}/..
DRUID_LIB=./lib
DRUID_DEPS=./deps
CP=${DRUID_LIB}/*
# DRUID_VERSION="0.7.0"
if ! [ -n "$DRUID_VERSION" ];
then 
   echo "DRUID_VERSION environment variable must be set"
   exit -1
fi

echo BASE_DIR is ${BASE_DIR}

# STEP 1:  Assume druid has been built.  Extract the deployment jars from the
# tar file that they are packaged in and move them to the DRUID_LIB dir.
mkdir ${PROG_DIR}/tmp_extraction
tar xzf ${BASE_DIR}/services/target/druid-${DRUID_VERSION}-bin.tar.gz -C ${PROG_DIR}/tmp_extraction
mv ${PROG_DIR}/tmp_extraction/druid-${DRUID_VERSION}/lib/ ${DRUID_LIB}
rm -rf ${PROG_DIR}/tmp_extraction

# STEP 2: Get the sigar library
wget -P ${DRUID_LIB} -q https://repository.jboss.org/nexus/content/repositories/thirdparty-uploads/org/hyperic/sigar/1.6.5.132/sigar-1.6.5.132.jar
if [ $? -ne 0 ]
then
 echo "Could not download sigar"
 exit -1
fi


# STEP 3: Install a local repo of extensions in the DRUID_DEPS dir.  
java -server -Xmx8g -Xms8g -Duser.timezone=UTC -Dfile.encoding=UTF-8 -Ddruid.extensions.localRepository="${DRUID_DEPS}" -Ddruid.extensions.coordinates="[\"io.druid.extensions:druid-kafka-eight:$DRUID_VERSION\", \"io.druid.extensions:druid-histogram:$DRUID_VERSION\", \"io.druid.extensions:mysql-metadata-storage:$DRUID_VERSION\"]" -cp "$CP" io.druid.cli.Main tools pull-deps


# STEP 4:  Set up our log4j2 kafka logger for logging operational stats on the main classpath
wget -P ${DRUID_LIB}/logger -q http://relic.webapps.rr.com/artifactory/simple/twc-releases/com/twc/needle/logj42-kafka/kafka_2.10_0.8.1.1/1.2/log4j2-kafka-with-kafka_2.10_0.8.1.1-1.2.jar
if [ $? -ne 0 ]
then
 echo "Could not download log4j2 kafka logger"
 exit -1
fi
# Unfortunately, Kafka libraries depend on scala. 
# We need to make sure we get the same one that is in the extension.
cp -rv ${DRUID_DEPS}/org/scala-lang/scala-library/2.10.4/scala-library-2.10.4.jar ${DRUID_LIB}/logger
if [ $? -ne 0 ]
then
 echo "Could not copy ${DRUID_DEPS}/org/scala-lang/scala-library/2.10.4/scala-library-2.10.4.jar"
 exit -1
fi
