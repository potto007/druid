druid-mesos
===========
Allows druid components (currently broker, historical nodes, coordinator, and realtime indexers) to be run from a docker container on mesos.
A single docker image contains all the scripts and configs necessary to launch these components.
Some standard deployment options are hardcoded (in config/...) inside the docker container for now.
Environment variables are used to configure the more variable pieces of the component.
Longer term, we may want to allow all runtime properties to be configured from an external properites file.

This base packaging assumes that the druid jars will be available outside of the docker image, deployed on the host machine.  A self contained docker image is also created that has the jars inside the docker image.

The base image without the druid jars is currently named `drui` in honor of the Irish word for Druid:  http://en.wikipedia.org/wiki/Druid.

## Service Discovery
ZK and Curator are key for discovery.
See http://druid.io/docs/latest/ZooKeeper.html
where they state:
> If druid.zk.paths.base and druid.zk.paths.indexer.base are both set, and none of the other druid.zk.paths.* or druid.zk.paths.indexer.* values are set, then the other properties will be evaluated relative to their respective base. For example, if druid.zk.paths.base is set to /druid1 and druid.zk.paths.indexer.base is set to /druid2 then druid.zk.paths.announcementsPath will default to /druid1/announcements while druid.zk.paths.indexer.announcementsPath will default to /druid2/announcements.

We use the druid.zk.paths.base to create logical druid clusters on the same physical cluster.
We probably don't use druid.zk.paths.indexer.base  since that is for task management by middlemanagers, and we don't have any middlemanager.

*TBD*:  We are currently NOT setting druid.selectors.indexing.serviceName  which is documented in http://druid.io/docs/latest/Configuration.html as:
> The druid.service name of the indexing service Overlord node. To start the Overlord with a different name, set it with this property.	
Since we don't use an overlord, this seems unnecessary.  But it isn't clear where it gets used?  Maybe Tranquility?  We'll need to see.

## Configuration
Configuration of the system is done with volume mountings (on the distributed file system and host machine) and via environment variables and marathon files on mesos.
For volume mountings below, we list the container path that must be mapped to a host path via a volume mapping.


### Common Configuration:  Required for all components

#### Volume Mountings

#####  All
-  **/opt/druid/externalconfig**:  A location from which to read external configuration files (log4j2.xml, realtime indexer spec files, etc.).
-  **/opt/druid/lib**:   The location of the druid jars.
-  **/opt/druid/deps**:   The location of the local druid extension repository (druid.extensions.localRepository).  *TODO:*  In the future, we could make it configurable whether to use local extensions as in production or a remote repo.
-  **/opt/druid/logs**:  The directory to write logs to.
-  **/tmp**:   An external location for writing large files and druid cache stuff where efficiency matters (more than the docker FS supports)

##### Historical
-  **/druid/local/historical/indexCache**:   The local cache for the historical node.

##### Realtime Indexer
-  **/druid/persist**:  The directory for incremental persists.


#### Environment Variables

#####  All

-  **DRUID_CLUSTER_NAME**:  A logical name for this cluster instance.  Will be used as a default value for other things like ZK_BASE_PATH, METADATA_TABLE_BASE, and SOURCE_PROCESS_CLUSTER if they are not set.  For this reason, should not contain characters that would be incompatible with 
-  **SERVICE_TYPE**:  Enumerated to {broker, historical, coordinator, realtime}.  Defines which configuraiton files and shell script will be used to launch the docker process.

-  **EXTENSION_COORDINATES**:  The druid extensions to load for the service.

-  **ZK_CONNECT**:   The connection string for the ZK cluster, since lots of coordination between components happens in ZK.  See METADATA_TABLE_BASE as these two should probably just match eachother.
-  **ZK_BASE_PATH**:   Conceptually, the name of this druid cluster.  All components (broker, historical, coordinator, realtime) with the same base path will coordinate with eachother as a single cluster.   This allows us to run multiple isolated druid clusters on the same physical hardware.
-  **ZK_CURATOR_DISCOVERY_PATH**:  This seems to be used with tranquility 

-  **DEEPSTORAGE_DIRECTORY**:   When using NSF mounted deepstorage, the local directory for all deep storage handoff to occur to.  Required by the realtime to do handoff and the historical to retrieve data presumably.  See the external volume mount.  Should match whatever that is mapped to internally.

-  **LOG4J_CONFIG_FILE**:  The log4j2 config file for configuring logging.  Should be outside of the docker container (on the external config volume mount) to support runtime changes where log4j polls for changes.

- **KAFKA_BROKER_LIST_OPERATIONAL**:  The broker list for outputting operations stats from druid, using the kafka log4j2 logger.
- **KAFKA_TOPIC_OPERATIONAL_STATS**:  The kafka topic to output operational stats to.
- **KAFKA_TOPIC_OPERATIONAL_ALERTS**:  The kafka topic to output operational alerts to.


NOTE:  Currently, the log4j2 operational stats logging does NOT support populating these fields from environment variables.  So these values get coded into the log4j configuration.
It would be nice to fix in the future.

- **SOURCE_PROCESS_CLUSTER**:  The name of this druid cluster for outputting operational stats.  Used to annotated the logged operational stats and alerts.
- **SOURCE_PROCESS_NAME**:   An identifier for this process used for annotation in operatinal stats logging.  Probably should be "druid"
- **SOURCE_PROCESS_VERSION**:   The version of the druid software that is running.

##### Historical
- **HISTORICAL_TIER**:  Which tier is this node associated with.  If you don't know, you probably want to use "_default_tier".   *TODO*:   Currently there is no validation that this field is provided.

##### Realtime
- **TEMPLATE_FILE_URL**:  A location (http url-- which might be file  in volume mapped /opt/druid/externalconfig) for the realtime indexer spec file, parameterized with variables.  The script **start-realtime.sh** will replace these variables using environment variables:
-- *<%= @partition %>*:  Used with linear sharded ingest
-- *<%= @zk_connect %>*:  Used if ingesting from kafka.

##### Coordinator
-  **STORAGE_CONNECTOR_URI**:  The connection string for the MySQL metadata store
-  **STORAGE_CONNECTOR_USER**:  The user for the MySQL metadata store
-  **STORAGE_CONNECTOR_PASSWORD**:  The super top secret password for accessing that metadata
-  **METADATA_TABLE_BASE**:    The prefix for all the tables in that user's schema, allowing isocation of mutliple logical druid clusters running on the same physical hardware with the same metastore and user/schema.   See ZK_BASE_PATH as these two should probably just match eachother.

##### Broker
- **MEMCACHED_HOSTS**:  A list of host/ports for the memcached instance.

#### Broker, Historical, and Realtimes
From Hagen Rother:
> The sum of all druid.broker.http.numConnections must be smaller than each druid.server.http.numThreads (i.e. check each historical and realtime).  If the number of threads is larger, one can end up with a deadlock situation distributing the queries to the realtime/historical query nodes.

-  **NUM_CONNECTIONS_PER_BROKER**:  *Required* for the Broker.  Required for realtime and historical to do some math to make sure they have enough threads.

One of the following two values is *required* for the Realtime and Historical nodes.  
-  **MAX_NUM_BROKERS**:  The maximimum number of brokers that will every be lauched for HA.  The maximum number of simultaneous requests a query node (historical, realtime) can receive will be at most *MAX_NUM_BROKER x NUM_CONNECTIONS_PER_BROKER*.
-  **HTTP_NUM_THREADS**:  The maximum number of simultaneous requests that the query node (historical or runtime) can handle.  Should be at least MAX_NUM_BROKER * BROKER_NUM_CONNECTIONS unles you know it will never have that many simultaneous requests.  *Use at your own risk.*

