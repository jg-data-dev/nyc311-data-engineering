\echo '== Raw null & unique key check =='

\if :{?raw_table}
    \set table_name :raw_table
\else
    \set table_name 'raw_311_requests'
\endif

\ir ../common/validate_common.sql