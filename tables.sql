CREATE DATABASE ecommerce;
\connect ecommerce;
-- create table and load data
CREATE TABLE transactions
(id INTEGER, account_action VARCHAR, user-id INTEGER, tx_id VARCHAR, amount DOUBLE PRECISION,
CONSTRAINT user-id_pk PRIMARY KEY (user-id));

\copy admission FROM '/home/data/mock_transaction_data.csv' DELIMITER ',' CSV HEADER