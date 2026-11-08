#!/usr/bin/env bash
# Generate web/about.html from CONTRIBUTORS.md so credits live in one place (#189).
# Adding a name to CONTRIBUTORS.md is the only step needed for it to show up on the page.
#
#   build-about.sh            regenerate web/about.html from CONTRIBUTORS.md
#   build-about.sh --check    regenerate into a temp file and fail if web/about.html differs
#                             (CI lint job; same idea as the docs .md/.html mirror checks)
#
# Plain static HTML, works from file://, no server, no internet. Needs bash and perl.
# The --check ignores CR/LF so a Windows checkout (autocrlf) does not false-fail.
set -u
cd "$(git rev-parse --show-toplevel)" 2>/dev/null || cd "$(dirname "$0")/../.." || exit 1

SRC="CONTRIBUTORS.md"
OUT="web/about.html"
[ -f "$SRC" ] || { echo "FAIL: $SRC not found"; exit 1; }

render() {
  perl -0777 -e '
    binmode(STDIN,  ":encoding(UTF-8)");
    binmode(STDOUT, ":encoding(UTF-8)");
    my $md = do { local $/; <STDIN> };
    $md =~ s/\r//g;
    my $BLOB = "https://github.com/elhajahmadj/offline-emergency-library/blob/main";

    # inline markdown -> HTML (escape first, then re-introduce the few tags we emit)
    sub esc { my $s = shift; $s =~ s/&/&amp;/g; $s =~ s/</&lt;/g; $s =~ s/>/&gt;/g; return $s; }
    sub inline {
      my $s = esc(shift);
      $s =~ s/\[([^\]]+)\]\((https?:[^)]+)\)/<a href="$2">$1<\/a>/g;   # [text](abs url)
      $s =~ s/\[([^\]]+)\]\(([^)]+)\)/<a href="$BLOB\/$2">$1<\/a>/g;    # [text](repo-relative)
      $s =~ s/`([^`]+)`/<code>$1<\/code>/g;                            # `code`
      $s =~ s/\*\*([^*]+)\*\*/<strong>$1<\/strong>/g;                  # **bold**
      return $s;
    }

    # pull the "## People" section (up to the next "## " or end)
    my ($people) = $md =~ /^##\s+People\s*\n(.*?)(?=^##\s|\z)/ms;
    die "could not find a \"## People\" section in CONTRIBUTORS.md\n" unless defined $people;
    # Split at the first blank line: the list is the contiguous bullet block right after the
    # heading; everything after the blank line is the trailing "Want to help?" prose. A blank
    # line *inside* the list would otherwise silently drop every contributor after it, so if the
    # tail still contains top-level bullets, that is a split list and we fail loudly.
    my ($list, $tail) = split /\n[ \t]*\n/, $people, 2;
    $tail = "" unless defined $tail;
    my $tail_bullets = () = $tail =~ /^-\s+/mg;
    die sprintf("a blank line splits the \"## People\" list: %d contributor bullet(s) after it ".
                "would be dropped; remove the blank line\n", $tail_bullets) if $tail_bullets > 0;
    $people = $list;
    my $bullets = () = $people =~ /^-\s+/mg;   # count every top-level bullet (one per contributor)

    # each person is a top-level "- " bullet; continuation lines are indented
    my @items;
    for my $block (split /\n(?=- )/, $people) {
      next unless $block =~ /^-\s+/;
      $block =~ s/^-\s+//;
      $block =~ s/\s*\n\s+/ /g;   # join wrapped continuation lines into one
      $block =~ s/\s+$//;
      next if $block eq "";
      # leading: **[@handle](url)** optional (Real Name)
      my ($handle, $url) = $block =~ /^\*\*\[\@?([^\]]+)\]\((https?:[^)]+)\)\*\*/;
      next unless defined $handle;
      my $rest = $block;
      $rest =~ s/^\*\*\[[^\]]+\]\([^)]+\)\*\*\s*//;
      my $name = "";
      if ($rest =~ /^\(([^)]+)\)\s*/) { $name = $1; $rest =~ s/^\([^)]+\)\s*//; }
      $rest =~ s/^[\x{2014}\x{2013}-]\s*//;   # strip leading em/en dash or hyphen
      push @items, { handle => $handle, url => $url, name => $name, desc => $rest };
    }
    die "no contributors parsed from the People section\n" unless @items;
    # every bullet must parse into exactly one person; otherwise someone was silently dropped
    # (e.g. a handle without the **bold** link form, or a stray blank line splitting the list).
    die sprintf("parsed %d contributor(s) but found %d bullet(s) under \"## People\"; ".
                "every person must be a top-level \"- **[\@handle](url)**\" bullet with no blank ".
                "lines inside the list\n", scalar(@items), $bullets)
      unless scalar(@items) == $bullets;

    for my $p (@items) {
      my $h    = esc($p->{handle});
      my $url  = esc($p->{url});
      my $name = $p->{name} ne "" ? " <span class=\"name\">".esc($p->{name})."</span>" : "";
      my $desc = inline($p->{desc});
      print "<article class=\"person\">\n";
      print "  <h2><a href=\"$url\">\@$h</a>$name</h2>\n";
      print "  <p>$desc</p>\n";
      print "</article>\n";
    }
  ' < "$SRC"
}

build() {
  local body; body="$(render)" || return 1
  cat <<EOF
<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>About — Sine Nexu</title>
<!-- Generated from CONTRIBUTORS.md by .github/scripts/build-about.sh. Do not edit by hand;
     add yourself to CONTRIBUTORS.md and CI regenerates this. The mission and code of conduct
     sections are part of this template (folded in from #204). -->
<style>:root{--bg:#0f1420;--card:#171f2e;--ink:#e7ecf3;--muted:#9fb0c3;--accent:#4fd1c5;--accent2:#f6ad55;--line:#273246;--code:#0b0f17}
@media(prefers-color-scheme:light){:root{--bg:#f4f6fb;--card:#fff;--ink:#15202b;--muted:#56657a;--accent:#0d9488;--accent2:#b45309;--line:#e2e8f0;--code:#f1f5f9}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.65 -apple-system,Segoe UI,Roboto,Arial,sans-serif}
.wrap{max-width:900px;margin:0 auto;padding:28px 20px 80px}
h1{font-size:28px;background:linear-gradient(135deg,var(--accent),var(--accent2));-webkit-background-clip:text;background-clip:text;color:transparent;margin:0 0 6px}
h2.sec{font-size:20px;margin:30px 0 8px}
.lead{color:var(--muted);margin:0 0 20px}
.topbar{display:flex;align-items:baseline;justify-content:space-between;gap:12px;flex-wrap:wrap;margin-bottom:6px}
.topnav a{color:var(--muted);text-decoration:none;font-size:14px;border:1px solid var(--line);border-radius:999px;padding:5px 12px;white-space:nowrap;margin-left:6px}
.topnav a:hover{color:var(--ink);border-color:var(--accent)}
.note{color:var(--muted);font-size:14px;margin:0 0 10px}
a{color:var(--accent)}code{background:var(--code);padding:2px 6px;border-radius:6px;font-family:Consolas,monospace;font-size:14px}
.person{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:16px 18px;margin:14px 0}
.box{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:16px 18px;margin:14px 0}.box p{margin:0;color:var(--ink)}
.person h2{font-size:18px;margin:0 0 6px}.person .name{color:var(--muted);font-weight:400;font-size:15px}
.person p{margin:0;color:var(--ink)}
footer{margin-top:30px;color:var(--muted);font-size:14px;border-top:1px solid var(--line);padding-top:16px}</style>
</head><body><div class="wrap">
<div class="topbar"><h1>About Sine Nexu</h1><nav class="topnav"><a href="landing.html">Home</a><a href="index.html">Picker</a><a href="sources.html">Sources</a></nav></div>
<p class="lead">Sine Nexu is a free, offline emergency library — survival, medical, repair, food and reference knowledge, plus an offline AI, on a drive that works with <strong>no internet and no power grid</strong> behind it.</p>

<h2 class="sec">Our mission</h2>
<div class="box">
  <p>To help people when it matters most: when disaster strikes and the power or the internet is gone, and for people in remote parts of the world who have little or no access to the internet. Everyone should be able to hold the essentials — how to stay safe, treat an injury, grow food, repair things, and find their way — on a drive that keeps working offline, anywhere.</p>
</div>

<h2 class="sec">Code of conduct</h2>
<div class="box">
  <p>Be kind and assume good faith. Everyone is welcome here, and testing and bug reports count just as much as code. We don't tolerate harassment, discrimination, or hostility of any kind. Keep discussion focused on the work, and help newcomers get started — we were all new once.</p>
</div>

<h2 class="sec">Contributors</h2>
<p class="note">Everyone who has improved Sine Nexu. Per-fix detail is in the <a href="https://github.com/elhajahmadj/offline-emergency-library/blob/main/CHANGELOG.md">CHANGELOG</a>.</p>
$body<footer>Add yourself by editing <code>CONTRIBUTORS.md</code> — the contributor list on this page is generated from it. ❤️</footer>
</div></body></html>
EOF
}

mkdir -p web
if [ "${1:-}" = "--check" ]; then
  tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
  build > "$tmp" || { echo "FAIL: could not generate about page from $SRC"; exit 1; }
  if ! diff -q <(tr -d '\015' < "$tmp") <(tr -d '\015' < "$OUT") >/dev/null 2>&1; then
    echo "FAIL: $OUT is out of date with $SRC."
    echo "Run: bash .github/scripts/build-about.sh  (then commit $OUT)"
    diff -u <(tr -d '\015' < "$OUT") <(tr -d '\015' < "$tmp") 2>/dev/null | head -40
    exit 1
  fi
  echo "OK: $OUT matches $SRC ($(grep -c '<article class="person">' "$OUT") contributors)."
else
  # Build into a temp first so a failure (e.g. a malformed CONTRIBUTORS.md) cannot leave a
  # truncated/empty $OUT behind; only replace it once generation succeeds.
  tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
  build > "$tmp" || { echo "FAIL: could not generate $OUT"; exit 1; }
  mv "$tmp" "$OUT"
  echo "Wrote $OUT ($(grep -c '<article class="person">' "$OUT") contributors)."
fi
