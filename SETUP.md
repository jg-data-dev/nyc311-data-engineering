# “How do I get this running again on my machine?”

# Virtual env
python3 -m venv venv
source venv/bin/activate

pip install requests "psycopg[binary]"

# Postgres
Start:
brew services start postgresql

Enter:
psql postgres

Create DB:
CREATE DATABASE nyc311;

Connect:
\c nyc311

Run schema:
\i sql/create_tables.sql


# Short-cuts
block comments: /* shit-option-A */



