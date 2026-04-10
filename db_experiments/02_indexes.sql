-- create index
CREATE INDEX idx_311_unique_key
ON stg_311_requests (unique_key);

-- rerun query
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM stg_311_requests
WHERE unique_key = '45337895';

-- observation:
-- index scan, huge speedup

/* with index
 QUERY PLAN                                                                 
-------------------------------------------------------------------------------------------------------------------------------------------
 Index Scan using raw_311_requests_pkey on raw_311_requests  (cost=0.42..8.44 rows=1 width=1481) (actual time=0.523..0.527 rows=1 loops=1)
   Index Cond: (unique_key = '45337895'::text)
   Buffers: shared hit=3 read=1
 Planning:
   Buffers: shared hit=66 dirtied=2
 Planning Time: 0.823 ms
 Execution Time: 0.592 ms
(7 rows)
*/

