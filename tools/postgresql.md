cat > tools/postgresql.md <<'EOF'
# PostgreSQL / psql Notes

Reusable PostgreSQL commands for the NYC 311 project.

## Basic idea

PostgreSQL is the database server.

psql is the command-line tool used to enter PostgreSQL, inspect databases, run SQL, create databases, and check tables.

This project uses separate databases per project version:

v1_manual  -> nyc311_v1
v2_dbt     -> nyc311_v2
v3_airflow -> nyc311_v3

---

## Enter PostgreSQL

Plain `psql` may fail if there is no database with the same name as the macOS user.

Example error:

psql: error: connection to server on socket "/tmp/.s.PGSQL.5432" failed:
FATAL: database "janeguo" does not exist

Use the default admin database instead:

```bash
psql -d postgres


Quit PostgreSQL

Inside psql:

\q
List databases

Inside psql:

\l
Connect to a database

Inside psql:

\c nyc311_v1

Or from the shell:

psql -d nyc311_v1

Check current database:

SELECT current_database();
Create project databases

From the shell:

createdb nyc311_v1
createdb nyc311_v2
createdb nyc311_v3

Or inside psql after connecting to postgres:

CREATE DATABASE nyc311_v1;
CREATE DATABASE nyc311_v2;
CREATE DATABASE nyc311_v3;
Drop a database

Only do this when intentionally deleting the database.

From the shell:

dropdb nyc311_v1

Or inside psql:

DROP DATABASE nyc311_v1;

If currently connected to the database, first switch away:

\c postgres
DROP DATABASE nyc311_v1;
List schemas

Inside a project database:

\dn

Common schemas:

public
raw
staging
marts

List tables

List tables in the current schema:

\dt

List tables across all schemas:

\dt *.*

More detailed table list:

SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY table_schema, table_name;
Inspect a table

Show columns and types:

\d table_name

If the table is in a schema:

\d raw.raw_311_requests

Preview rows:

SELECT *
FROM raw.raw_311_requests
LIMIT 10;

Count rows:

SELECT COUNT(*)
FROM raw.raw_311_requests;
Check database size
SELECT pg_size_pretty(pg_database_size(current_database()));

Check table sizes:

SELECT
  schemaname,
  relname AS table_name,
  pg_size_pretty(pg_total_relation_size(relid)) AS total_size
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC;
Create schema
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS marts;
Delete all rows from a table

Use with care.

TRUNCATE TABLE raw.raw_311_requests;

If other tables depend on it:

TRUNCATE TABLE raw.raw_311_requests CASCADE;
Delete a table

Use with care.

DROP TABLE raw.raw_311_requests;
Common shell commands

Check whether Postgres is running:

pg_isready

Enter version database:

psql -d nyc311_v1

Create version database:

createdb nyc311_v1

Drop version database:

dropdb nyc311_v1