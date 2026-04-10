## Experiment 1: PK lookup

### Query
SELECT * FROM stg_311_requests WHERE unique_key = '45337895';

### Prediction
Should use index (high selectivity)

### Actual (before index)
Seq Scan, 30ms, scanned 100k rows

### After index
Index Scan, ~1ms

### Insight
Planner chooses seq scan because no index exists.
High selectivity makes index extremely effective.

### Concepts
primary keys
foreign keys
indexes
constraints
defaults
triggers
cases where keeping or dropping constraints changes query plans and performance dramatically

A buffer = a PostgreSQL memory page (usually 8KB)