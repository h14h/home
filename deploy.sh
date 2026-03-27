#!/usr/bin/env bash
set -euo pipefail

OMGLOL_ADDRESS="h14h"
OMGLOL_API="https://api.omg.lol/address/${OMGLOL_ADDRESS}/weblog/entry"
WEBLOG_BASE="https://blog.h14h.com"
CONTENT_DIR="content/gemlog"

# Convert gemtext links to markdown, rewriting gemini:// URLs
gmi_to_md() {
    gawk '{
        if ($1 == "=>") {
            url=$2; $1=""; $2=""; sub("  ", "");
            label = ($0 ~ /[^ ]/) ? $0 : url;
            print "[" label "](" url ")\n";
        } else { print }
    }' "$1" \
    | sed -E \
        -e '/^\* Published: [0-9]{4}-[0-9]{2}-[0-9]{2}$/d' \
        -e "s|\(gemini://gemini\.h14h\.com/gemlog/([0-9]{4})-([0-9]{2})-[0-9]{2}-([^)]+)\.gmi\)|(${WEBLOG_BASE}/\1/\2/\3)|g" \
        -e "s|\(gemini://([^)]+)\)|(https://portal.mozz.us/gemini/\1)|g"
}

# --- Main ---

echo "==> Deploying to Geminispace (fly.io)"
fly deploy

echo ""
echo "==> Publishing to omg.lol weblog"

if [[ -z "${OMGLOL_API_KEY:-}" ]]; then
    echo "  Error: OMGLOL_API_KEY not set"
    exit 1
fi

publish_failed=0

for file in "$CONTENT_DIR"/[0-9]*.gmi; do
    [[ -f "$file" ]] || continue
    filename=$(basename "$file" .gmi)

    [[ "$filename" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})-(.+)$ ]] || continue
    date="${BASH_REMATCH[1]}"
    slug="${BASH_REMATCH[2]}"

    echo "  Publishing: $filename"

    md_content=$(gmi_to_md "$file")

    if curl --fail-with-body -sS -X PUT \
        -H "Authorization: Bearer ${OMGLOL_API_KEY}" \
        -H "Content-Type: text/plain" \
        -d "---
Date: ${date}
Slug: ${slug}
---

${md_content}" \
        "${OMGLOL_API}/${slug}" >/dev/null; then
        echo "  OK"
    else
        echo "  FAILED"
        publish_failed=1
    fi
done

if (( publish_failed )); then
    echo ""
    echo "==> Publish completed with errors"
    exit 1
fi

echo ""
echo "==> Done"
echo "  Gemini: gemini://gemini.h14h.com/"
echo "  Web:    ${WEBLOG_BASE}/"
