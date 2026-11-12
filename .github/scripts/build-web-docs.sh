#!/usr/bin/env bash
# Publish the on-drive guides to the website's Docs page (#205). docs/*.html are copied into
# web/docs/ with their links fixed for the site (#253); the rules are in build-web-docs.py.
#   build-web-docs.sh            build web/docs/ from docs/*.html
#   build-web-docs.sh --check    verify web/docs/ is in sync and every link resolves (CI)
set -eu
cd "$(dirname "$0")/../.." || exit 1
# python3 first; on Windows "python3" can be a Store stub that does not run
for py in python3 python; do "$py" -c '' 2>/dev/null && exec "$py" .github/scripts/build-web-docs.py "$@"; done
echo "build-web-docs.sh needs Python 3"; exit 1
