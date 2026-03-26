#!/usr/bin/env bash
set -euo pipefail

OMGLOL_API_KEY="${OMGLOL_API_KEY:-$(fish -c 'echo $OMGLOL_API_KEY')}"
OMGLOL_ADDRESS="h14h"
API_BASE="https://api.omg.lol/address/${OMGLOL_ADDRESS}/weblog"
DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Pushing profile page"
python3 -c "
import json, sys
html = open('${DIR}/profile.html').read()
css = open('${DIR}/profile.css').read()
content = html.replace('{{CSS}}', css)
print(json.dumps({'content': content, 'publish': True}))
" | curl -s -X POST \
    -H "Authorization: Bearer ${OMGLOL_API_KEY}" \
    -H "Content-Type: application/json" \
    -d @- \
    "https://api.omg.lol/address/${OMGLOL_ADDRESS}/web" | jq -r '.response.message'

echo "==> Pushing weblog configuration"
curl -s -X POST \
    -H "Authorization: Bearer ${OMGLOL_API_KEY}" \
    -H "Content-Type: text/plain" \
    --data-binary @"${DIR}/configuration.conf" \
    "${API_BASE}/configuration" | jq -r '.response.message'

echo "==> Pushing main template"
curl -s -X POST \
    -H "Authorization: Bearer ${OMGLOL_API_KEY}" \
    -H "Content-Type: text/plain" \
    --data-binary @"${DIR}/template.html" \
    "${API_BASE}/template" | jq -r '.response.message'

echo "==> Pushing landing page template"
curl -s -X POST \
    -H "Authorization: Bearer ${OMGLOL_API_KEY}" \
    -H "Content-Type: text/plain" \
    --data-binary @"${DIR}/landing-page-template.html" \
    "${API_BASE}/entry/landing-page-template" | jq -r '.response.message'

echo "==> Done: https://blog.h14h.com"
