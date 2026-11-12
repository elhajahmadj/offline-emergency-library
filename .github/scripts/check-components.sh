#!/usr/bin/env bash
# One component table as data (#67). components.tsv is the single list of what the kit downloads,
# each row carrying a license, a license link and an upstream source. This check fails CI if:
#   - any row is missing a license, a license link or a source (so a new source cannot land
#     unlicensed — the whole point of #67);
#   - a license link or source is not a URL;
#   - a row does not have exactly five tab-separated columns;
#   - the row's `piece` is not a real id in catalog.json (keeps the two from drifting);
#   - a catalog.json piece has no component row (so nothing ships unlisted);
#   - a row's `source` host is not health-checked by check-links.sh, so a documented download
#     could silently go unmonitored (#67 wanted the table and the link list to stop drifting).
#     One-directional on purpose: check-links.sh also probes bundled libraries (sqlite-jdbc,
#     maplibre, pmtiles, OffRoad) that carry no license row, and those extra probes are fine.
# Offline, no network. Pairs with check-catalog.sh (which checks the installers against catalog.json)
# and check-links.sh (which actually fetches each source; this only checks the two lists agree).
set -u
cd "$(dirname "$0")/../.." || exit 1
TSV="components.tsv"
CAT="catalog.json"
[ -f "$TSV" ] || { echo "FAIL: $TSV is missing"; exit 1; }
[ -f "$CAT" ] || { echo "FAIL: $CAT is missing"; exit 1; }

# Valid piece ids from catalog.json (no jq: read the "id" fields), space-padded for exact matching.
pieces=" $(grep -oE '"id"[[:space:]]*:[[:space:]]*"[^"]+"' "$CAT" | sed -E 's/.*"([^"]+)"$/\1/' | tr '\n' ' ') "
[ "$pieces" = "  " ] && { echo "FAIL: no piece ids found in $CAT"; exit 1; }

# awk -F'\t' keeps empty fields (bash `read` collapses consecutive tabs, hiding an empty column).
awk -F'\t' -v pieces="$pieces" '
  function bad(m){ print "FAIL: " m; fail=1 }
  /^#/ || $0 ~ /^[ \t]*$/ { next }          # comment or blank
  $1=="component" { next }                   # column header
  {
    rows++
    name=$1
    if (NF!=5) { bad(name ": has " NF " tab-separated columns, want 5"); next }
    if ($2=="")                         bad(name ": empty piece")
    else if (index(pieces," " $2 " ")==0) bad(name ": piece \x27" $2 "\x27 is not an id in catalog.json")
    else seen[$2]=1
    if ($3=="") bad(name ": empty license")
    if ($4=="") bad(name ": empty license link"); else if ($4 !~ /^https?:\/\//) bad(name ": license link is not a URL (" $4 ")")
    if ($5=="") bad(name ": empty source");       else if ($5 !~ /^https?:\/\//) bad(name ": source is not a URL (" $5 ")")
  }
  END {
    if (rows==0) bad("no component rows")
    n=split(pieces,ps," ")
    for(i=1;i<=n;i++) if(ps[i]!="" && !(ps[i] in seen)) bad("catalog piece \x27" ps[i] "\x27 has no row")
    if (fail) { print "components.tsv check failed."; exit 1 }
    printf "OK: %s — %d components, each with a license, a link, a source and a known catalog piece.\n", "'"$TSV"'", rows
  }
' "$TSV" || exit 1

# #67 drift guard: every component's upstream source must be exercised by check-links.sh, so a
# documented download can never go unmonitored. Match by host, except for github.com where the
# owner/repo is matched (check-links references those via api.github.com/repos/<owner>/<repo>,
# a release check, or the hardcoded llama.cpp build). One-directional: check-links may probe more.
LINKS=".github/scripts/check-links.sh"
if [ ! -f "$LINKS" ]; then
  echo "WARN: $LINKS not found; skipped the source/health-check cross-check."
else
  links_txt="$(cat "$LINKS")"
  miss=0
  while IFS= read -r src; do
    [ -n "$src" ] || continue
    rest="${src#*://}"; host="${rest%%/*}"
    if [ "$host" = "github.com" ]; then
      path="${rest#*/}"; owner="${path%%/*}"; repo="${path#*/}"; repo="${repo%%/*}"
      needle="$owner/$repo"
    else
      needle="$host"
    fi
    if ! printf '%s' "$links_txt" | grep -qF "$needle"; then
      echo "FAIL: source $src ($needle) is not health-checked in $LINKS"; miss=1
    fi
  done < <(awk -F'\t' '/^#/||/^[ \t]*$/{next} $1=="component"{next} {print $5}' "$TSV")
  if [ "$miss" -ne 0 ]; then
    echo "Add the source's host (or its GitHub owner/repo) to $LINKS, or remove the component row."
    exit 1
  fi
  echo "OK: every component source is health-checked by $LINKS."
fi
