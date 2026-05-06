# Migration Tests

These tests compare the original manually built `public` tables against the dbt-built tables in the active dbt target schema.

They are temporary migration tests. Once the dbt models become the source of truth, this folder can be deleted or excluded from normal test runs.

Run all migration tests:

```bash
dbt test --select path:tests/migration
```

Run normal data-contract tests without migration tests:

```bash
dbt test --exclude path:tests/migration
```

## Test categories

### 1. Column shape parity

Files named:

```text
assert_<model>_columns_match_public.sql
```

These compare:

```text
column_name
data_type
```

They intentionally do **not** compare physical constraints such as `NOT NULL`, primary keys, foreign keys, or indexes. Those contracts should be covered by standard dbt tests such as `not_null`, `unique`, `relationships`, `accepted_values`, and custom grain tests.

### 2. Row count parity

Files named:

```text
assert_<model>_row_count_matches_public.sql
```

These verify that the public/manual table and dbt-built table have the same number of rows.

Row count parity is a cheap migration check. It does not prove full value equality.

### 3. Key-set parity

Files named:

```text
assert_<model>_keys_match_public.sql
```

These verify that the two tables contain the same row identities. This is stronger than row count parity because two tables can have the same row count but different keys.

## Key choices

| dbt model | public table | migration key |
|---|---|---|
| `stg_311_requests` | `public.stg_311_requests` | `unique_key` |
| `dim_agency` | `public.dim_agency` | `agency`, `agency_name` |
| `dim_channel` | `public.dim_channel` | `open_data_channel_type` |
| `dim_complaint_type` | `public.dim_complaint_type` | `complaint_type` |
| `dim_status` | `public.dim_status` | `status` |
| `dim_date` | `public.dim_date` | `full_date` |
| `dim_location` | `public.dim_location` | full natural location attribute set, not `location_id` |
| `fct_311_complaint` | `public.fact_311_complaint` | `unique_key` |
| `fct_311_complaint_text` | `public.fact_311_complaint_text` | `unique_key` |
| `int_complaints_flagged` | `public.int_complaints_flagged` | `unique_key` |
| `fct_daily_metrics` | `public.fct_daily_metrics` | `metric_date` |
| `fct_monthly_metrics` | `public.fct_monthly_metrics` | `month_start` |
| `fct_borough_complaint_mix` | `public.fct_borough_complaint_mix` | `borough`, `complaint_type` |

## Why dimension keys avoid surrogate IDs

The dbt models may generate surrogate IDs differently from the manual tables. For dimension migration tests, compare natural keys instead of IDs.

Example:

```text
Use: dim_agency.agency + dim_agency.agency_name
Avoid: dim_agency.agency_id
```

## Dim location caveat

`dim_location` is compared using the full natural location attribute set because the public table may not have a single stable `location_key`. If the dbt/public schemas diverge for location columns, first inspect the column parity test and adjust the key-set test to match the actual shared natural-grain columns.
