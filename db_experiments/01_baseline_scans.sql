-- Q1: PK lookup (no index yet)
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM stg_311_requests
WHERE unique_key = '45337895';

-- observation:
-- seq scan, scanned entire table

/* without index
QUERY PLAN                                                   
----------------------------------------------------------------------------------------------------------------
 Seq Scan on stg_311_requests  (cost=0.00..4368.00 rows=1 width=215) (actual time=0.022..31.652 rows=1 loops=1)
   Filter: (unique_key = '45337895'::text)
   Rows Removed by Filter: 99999
   Buffers: shared hit=3118
 Planning Time: 0.128 ms
 Execution Time: 31.690 ms
(6 rows)
*/


EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM stg_311_requests
WHERE complaint_type = 'Noise - Residential';

/* on staging:
Bitmap Heap Scan on stg_311_requests  (cost=110.23..3347.48 rows=9540 width=215) (actual time=2.865..18.028 rows=9606 loops=1)
   Recheck Cond: (complaint_type = 'Noise - Residential'::text)
   Heap Blocks: exact=1496
   Buffers: shared hit=1496 read=10
   ->  Bitmap Index Scan on idx_stg_311_complaint_type  (cost=0.00..107.84 rows=9540 width=0) (actual time=2.562..2.563 rows=9606 loops=1)
         Index Cond: (complaint_type = 'Noise - Residential'::text)
         Buffers: shared read=10
 Planning Time: 0.991 ms
 Execution Time: 19.585 ms
(9 rows)
on raw:
Bitmap Heap Scan on raw_311_requests  (cost=128.89..16864.83 rows=9884 width=1481) (actual time=5.546..166.181 rows=9606 loops=1)
   Recheck Cond: (complaint_type = 'Noise - Residential'::text)
   Heap Blocks: exact=4381
   Buffers: shared hit=2067 read=2324
   ->  Bitmap Index Scan on idx_311_complaint_type  (cost=0.00..126.42 rows=9884 width=0) (actual time=4.008..4.008 rows=9606 loops=1)
         Index Cond: (complaint_type = 'Noise - Residential'::text)
         Buffers: shared hit=3 read=7
 Planning:
   Buffers: shared hit=131
 Planning Time: 1.565 ms
 Execution Time: 167.505 ms
*/


EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM stg_311_requests
ORDER BY created_date DESC
LIMIT 100;
/* 
Limit  (cost=0.29..10.33 rows=100 width=215) (actual time=1.427..1.874 rows=100 loops=1)
   Buffers: shared hit=93 read=2
   ->  Index Scan Backward using idx_stg_311_created_date on stg_311_requests  (cost=0.29..10039.66 rows=100000 width=215) (actual time=1.323..1.604 rows=100 loops=1)
         Buffers: shared hit=93 read=2
 Planning:
   Buffers: shared hit=11
 Planning Time: 0.736 ms
 Execution Time: 2.052 ms
*/