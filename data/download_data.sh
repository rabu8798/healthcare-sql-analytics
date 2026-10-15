#!/usr/bin/env bash
# Downloads the public Synthea sample dataset (~60 MB zip, 1,163 synthetic
# patients) and extracts the CSVs this project uses into data/csv/.
set -euo pipefail
cd "$(dirname "$0")"
URL="https://github.com/synthetichealth/synthea-sample-data/raw/main/downloads/synthea_sample_data_csv_nov2021.zip"
curl -L -o synthea.zip "$URL"
unzip -o -j synthea.zip \
  'csv/patients.csv' 'csv/organizations.csv' 'csv/providers.csv' 'csv/payers.csv' \
  'csv/encounters.csv' 'csv/conditions.csv' 'csv/medications.csv' 'csv/observations.csv' \
  -d csv
rm synthea.zip
echo "CSVs ready in data/csv/"
