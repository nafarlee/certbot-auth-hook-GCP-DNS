#!/usr/bin/env sh
# vi: ft=sh
set -Euxo pipefail

missing_env() {
  echo "ERROR: $1: Required ENV variable not set"
  exit 1
}

if [ -z "$KEY_FILE"    ]; then missing_env KEY_FILE; fi
if [ -z "$GCP_PROJECT" ]; then missing_env GCP_PROJECT; fi
if [ -z "$GCP_ZONE"    ]; then missing_env GCP_ZONE; fi
if [ -z "$DNS_NAME"    ]; then missing_env DNS_NAME; fi

existing_record="TODO"

until gcloud auth activate-service-account --key-file="${KEY_FILE}"; do
  sleep 3
done

gcloud \
  dns \
  record-sets \
  transaction \
  start \
  --project "${GCP_PROJECT}" \
  -z "${GCP_ZONE}"

gcloud \
  dns \
  record-sets \
  transaction \
  add \
  --name "${DNS_NAME}" \
  --ttl 5 \
  --type TXT "${CERTBOT_VALIDATION}" \
  --project "${GCP_PROJECT}" \
  -z "${GCP_ZONE}"

gcloud \
  dns \
  record-sets \
  transaction \
  remove \
  --name "${DNS_NAME}" \
  --ttl 5 \
  --type TXT "${existing_record}" \
  --project "${GCP_PROJECT}" \
  -z "${GCP_ZONE}"

gcloud \
  dns \
  record-sets \
  transaction \
  execute \
  --project "${GCP_PROJECT}" \
  -z "${GCP_ZONE}"

while [ "$(dig @8.8.8.8 -t txt "${DNS_NAME}" +short)" != "\"$CERTBOT_VALIDATION\"" ]; do
  sleep 6
done

sleep 30
exit 0
