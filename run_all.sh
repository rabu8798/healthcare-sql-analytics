#!/usr/bin/env bash
# Builds the database, loads the data, runs every query and saves the
# output to results/. Usage:  ./run_all.sh   (add -u root -p if needed:
#   MYSQL_OPTS="-u root -p" ./run_all.sh)
set -euo pipefail
cd "$(dirname "$0")"
OPTS=${MYSQL_OPTS:-}
[ -f data/csv/patients.csv ] || ./data/download_data.sh
mysql $OPTS < sql/01_schema.sql
mysql $OPTS --local-infile=1 < sql/02_load_data.sql
mkdir -p results
for q in queries/*.sql; do
  name=$(basename "$q" .sql)
  { echo "# Results: $name"; echo; echo '```'; mysql $OPTS --table < "$q"; echo '```'; } > "results/$name.md"
  echo "ran $name"
done
