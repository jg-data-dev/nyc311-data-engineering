/*
Investigate time lapse between complaint closed time and resolution update time

Goal:
- discover signifcant time lapse (>1 hour)

Current Conlusion:
- 2% >1 hour

*/
SELECT * from (
Select complaint_type,
closed_at,
resolution_action_updated_at,
(Resolution_action_updated_at-closed_at) as diff
FROM fact_311_complaint
JOIN dim_complaint_type USING (complaint_type_id)
where Closed_at!=resolution_action_updated_at
) as t
where diff > INTERVAL '1 hour'
Order by diff DESC;
-- (1644 rows)

SELECT complaint_type,
count(*) as cnt
from (
Select complaint_type,
closed_at,
resolution_action_updated_at,
(Resolution_action_updated_at-closed_at) as diff
FROM fact_311_complaint
JOIN dim_complaint_type USING (complaint_type_id)
where Closed_at!=resolution_action_updated_at
) as t
where diff > INTERVAL '1 hour'
group by complaint_type
Order by cnt DESC;
/* 
             complaint_type              | cnt 
-----------------------------------------+-----
 DERELICT VEHICLES                       | 857
 GRAFFITI                                | 509
 FOOD POISONING                          | 103
 REQUEST LARGE BULKY ITEM COLLECTION     |  90
 LOST PROPERTY                           |  21
 FOR HIRE VEHICLE COMPLAINT              |  17
 RODENT                                  |  14
 NOISE                                   |   7
 TAXI COMPLAINT                          |   4
 SPECIAL PROJECTS INSPECTION TEAM (SPIT) |   3
 SEWER                                   |   3
 STREET CONDITION                        |   2
 DAMAGED TREE                            |   2
 BROKEN PARKING METER                    |   2
 WATER SYSTEM                            |   2
 SANITATION CONDITION                    |   1
 UNSANITARY CONDITION                    |   1
 AIR QUALITY                             |   1
 OVERFLOWING LITTER BASKETS              |   1
 MISSED COLLECTION (ALL MATERIALS)       |   1
 BUILDING/USE                            |   1
 ILLEGAL TREE DAMAGE                     |   1
 VACANT LOT                              |   1
(23 rows)
 */