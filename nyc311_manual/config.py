import os

# Production
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql:///nyc311")