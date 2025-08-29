#!/usr/bin/env bash
set -euo pipefail

# Default to SQLite file inside container unless overridden
export POSTGRES_DB_URL="${POSTGRES_DB_URL:-sqlite:///spending.db}"

echo "Using DB URL: ${POSTGRES_DB_URL}"

# Initialize database tables if missing
python - <<'PY'
from server import app
from model import db, connect_to_db
import os

connect_to_db(app, os.getenv('POSTGRES_DB_URL'))
db.create_all()
print('DB initialized')
PY

# Seed minimal categories if categories table empty (avoid FK errors)
python - <<'PY'
from server import app
from model import db, connect_to_db, Category
import os

connect_to_db(app, os.getenv('POSTGRES_DB_URL'))
if db.session.query(Category).count() == 0:
    seeds = [
        (1,'Online Purchase'),
        (2,'Travel'),
        (3,'Food'),
        (4,'Groceries'),
        (5,'Clothing'),
        (6,'Entertainment'),
    ]
    for cid, name in seeds:
        db.session.add(Category(id=cid, category=name))
    db.session.commit()
    print('Seeded base categories')
else:
    print('Categories already present')
PY

exec "$@"


