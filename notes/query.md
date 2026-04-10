## Experiment: PK lookup on stg_311_requests

### Query
SELECT * FROM stg_311_requests WHERE unique_key = '45337895';

### Prediction
Should use primary key index.

### Actual Plan
Index Scan ...

### What I learned
CTAS did not preserve PK; after re-adding PK, plan changed from Seq Scan to Index Scan.