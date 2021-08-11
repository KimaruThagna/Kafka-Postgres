# Kafka-Postgres
Data stream processing with Apache Kafka connectors, sinks and PostgreSQL
# Use Case
An ecommerce store with transactional data and wishes to process the event data generated by transactions. 

# Tech used
- Apache Kafka for stream data handling 
- Zookeeper for managing Kafka
- Kafka Connect for "transporting data into and out of Kafka
- Postgres for working with Kafka connectors to handle data going into and out of Kafka
- KSQL server for create real-time processing
- Kafka's schema registry for imposing the AVRO format.

# Connectors
`source.json` (source) Defines the connection between the source database(postgres) and Kafka as the destination
`sink.json` (Sink) Defines the connection between Kafka as the source and a postgres DB as the destination
# Running the project
Spin up the services using the command ` docker-compose up ` use `-d` flag to run in detatch mode.

## Setup a Postgres DB and Load Data
On a separate terminal, To spin up a postgres db, run the command
```
docker run -it --rm --network=kafka_postgres_default \
         -v $PWD:/home/data/ \
         postgres:11.0 psql -h postgres -U postgres
```
In the PSQL interface, run the commands defined in the `tables.sql` file
## Make source connection
Submit `source.json` file to the connect service via a curl command
```
curl -X POST -H “Accept:application/json” -H “Content-Type: application/json” --data @source.json http://localhost:8083/connectors
```
Query the connector to see if it worked `curl -H “Accept:application/json” localhost:8083/connectors/`

if successful, the transactions table should be seen as a TOPIC. Run the command
` docker exec -it <kafka-container-id> /bin/bash` to access the kafka container bash. In this case, "kafka" is the container name. You can also use the container ID
Once in the container bash, run the commmand `/usr/bin/kafka-topics — list — zookeeper zookeeper:2181` to view topics.

## Access Topics via KSQL
Since the KSQL-CLI server is running courtesy of docker compose, run the command ` docker exec -it <ksqldb-cli-container-id> /bin/ksql http://ksqldb-server:8088 ` 
Once in the CLI enter the command `SHOW TOPICS`
In the KSQL interface, create a stream and table for mirroring the transactions table in the postgres DB

```
CREATE STREAM transaction_src (id INTEGER, account_action VARCHAR, user-id INTEGER, tx_id VARCHAR, amount DOUBLE PRECISION)
WITH (KAFKA_TOPIC=’dbserver1.public.transactions, VALUE_FORMAT=’AVRO’);

CREATE STREAM transaction_rekey WITH (PARTITIONS=1) AS 
SELECT * FROM transaction_src PARTITION BY user-id;

SHOW STREAMS;

CREATE TABLE transactions (id INTEGER, account_action VARCHAR, user-id INTEGER, tx_id VARCHAR, amount DOUBLE PRECISION)
WITH (KAFKA_TOPIC=TRANSACTIONS_REKEY, VALUE_FORMAT=’AVRO’, KEY=’user-id’);

SHOW TABLES;
```

## Perform basic analysis with KSQL
Assume that transactions above 8,000,000 are considered suspicious, we would create a table with suspicious transactions using the SQL statement below
```
CREATE TABLE TRANSACTIONS_SUSPECT AS
SELECT AMOUNT, TIMESTAMP, USER-ID, TX_ID, ACCOUNT_ACTION  FROM TRANSACTIONS_REKEY WHERE AMOUNT > 8000000 WITH (KAFKA_TOPIC=TRANSACTIONS_SUSPECT, VALUE_FORMAT=’delimited’, KEY=TX_ID) ;
```

## Submit Sink Config to Connect Registry
Run the curl command
```
curl -X POST -H “Accept:application/json” -H “Content-Type: application/json” --data @sink.json http://localhost:8083/connectors
```
## Inspect Data in Postgres
Access the running postgres container defined in the docker-compose file by running 
`docker exec -it <postgres_container_id> psql -U postgres -W postgres ecommerce`

View the data brought in by Kafka connect by running the SQL commands
```
SELECT * FROM  TRANSACTIONS_SUSPECT;
SELECT COUNT(TX_ID) FROM TRANSACTIONS_SUSPECT;
```
When you add new data in the source database by copying csv data, the data should go through the whole process, get processed via the simple KSQL query and upon re running the above query, the results will be different.