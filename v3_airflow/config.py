from pathlib import Path
import os
from dotenv import load_dotenv

VERSION_ROOT = Path(__file__).resolve().parent
load_dotenv(VERSION_ROOT / ".env")

PROJECT_DB = os.environ["PROJECT_DB"]
DATABASE_URL = os.environ["DATABASE_URL"]