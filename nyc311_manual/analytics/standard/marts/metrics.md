# fct_daily_metrics

## Purpose
Daily operational metrics for 311 complaints (volume + resolution)

## Key Metrics Notes

### resolution_hours
- Includes instant closures (closed_at = created_at)
- These are administrative (dedup / routing), not real resolution

Impact:
- lowers median
- affects distribution shape
- contributes to long tail behavior

Decision:
- kept for now, but metric mixes different processes

---

### daily_net_case_flow
- = created_count - closed_count

Limitation:
- closed_count includes administrative closures
- may overstate operational throughput

---

## Known Data Issues
- invalid_time_order exists (~0–4% on some days)

## Metric Stress Checklist

1. Distribution shape
   - avg vs median vs p95
   - detect skew / long tail

2. Structural anomalies
   - zero-duration / instant events
   - duplicates / repeated events

3. Sample size validity
   - are percentiles meaningful?

4. Composition
   - does metric mix different processes?

5. For each metric:
    - what does it measure?
    - what distorts it?
    - when should I distrust it?