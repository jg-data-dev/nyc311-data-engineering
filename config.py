import os

# Production
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql:///nyc311")

# Local
DB_CONFIG = {
    "host": "localhost",
    "port": 5432,
    "dbname": "nyc311",
    "user": "janeguo",
    "password": "",
}
