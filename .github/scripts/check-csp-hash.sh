#!/usr/bin/env bash
# CSP hash check: a page whose Content-Security-Policy allows its inline scripts or styles by
# hash ('sha256-...') must list the hash of every inline <script> and <style> it has. When the
# script or style changes and its hash is not updated, the browser blocks it and the page
# silently loses behaviour (script) or styling (style).
# It also forbids 'unsafe-inline' in script-src and style-src, and rejects inline style="..."
# attributes, which a hash cannot cover and which would need 'unsafe-inline' to work.
# Checks every tracked .html file with a CSP <meta> (or the files given as arguments).
# The hash is base64(sha256(element text as UTF-8)), as the browser computes it. CR LF is
# read as LF first, like the HTML parser does, so a CRLF (Windows) checkout passes too.
# Needs bash, git and perl. Used by CI (lint job).
set -u
cd "$(dirname "$0")/../.." || exit 1
if [ "$#" -gt 0 ]; then files=("$@")
else files=(); while IFS= read -r f; do files+=("$f"); done < <(git ls-files '*.html' | xargs grep -l 'http-equiv="Content-Security-Policy"'); fi
[ "${#files[@]}" -gt 0 ] || { echo "FAIL: no page with a Content-Security-Policy found"; exit 1; }

fail=0
for f in "${files[@]}"; do
  perl -MDigest::SHA=sha256_base64 -0777 -ne '
    my $f = $ARGV; my $fail = 0; s/\r\n?/\n/g;
    my ($csp) = /<meta http-equiv="Content-Security-Policy" content="([^"]*)"/i;
    defined $csp or do { print "FAIL: $f: no Content-Security-Policy meta\n"; exit 1 };

    my ($src) = $csp =~ /(?:^|;)\s*script-src\s([^;]*)/;
    defined $src or do { print "FAIL: $f: CSP has no script-src\n"; exit 1 };
    if ($src =~ /\x27unsafe-inline\x27/) { print "FAIL: $f: script-src still has \x27unsafe-inline\x27\n"; $fail = 1 }
    # style-src is optional, but when present it must not re-open the inline hole either.
    my ($ssrc) = $csp =~ /(?:^|;)\s*style-src\s([^;]*)/;
    if (defined $ssrc && $ssrc =~ /\x27unsafe-inline\x27/) { print "FAIL: $f: style-src still has \x27unsafe-inline\x27\n"; $fail = 1 }

    my $n = 0;
    while (/<script\b([^>]*)>(.*?)<\/script>/gs) {
      my ($attr, $body) = ($1, $2);
      next if $attr =~ /\bsrc\s*=/i;    # external file: not an inline script
      # A type that is not JavaScript (like text/xml data) is not run, so it needs no hash.
      if ($attr =~ /\btype\s*=\s*["\x27]?([^"\x27\s>]+)/i) { next unless $1 =~ m{^(text/javascript|application/javascript|text/ecmascript|application/ecmascript|module)$}i }
      $n++; my $h = sha256_base64($body) . "=";
      if (index($src, "\x27sha256-$h\x27") >= 0) { printf "ok: %s: script %d (%d bytes) sha256-%s\n", $f, $n, length($body), $h }
      else { printf "FAIL: %s: script %d (%d bytes) sha256-%s is not in script-src. Put \x27sha256-%s\x27 in the CSP.\n", $f, $n, length($body), $h, $h; $fail = 1 }
    }
    # A page can load all its JavaScript from a file; then there is no inline script to hash.
    if (!$n) { print "ok: $f: no inline script (nothing to hash)\n" }

    my $sn = 0;
    while (/<style\b([^>]*)>(.*?)<\/style>/gs) {
      my $body = $2;
      $sn++; my $h = sha256_base64($body) . "=";
      if (!defined $ssrc) { printf "FAIL: %s: style %d (%d bytes) has no style-src in the CSP. Add style-src with \x27sha256-%s\x27.\n", $f, $sn, length($body), $h; $fail = 1 }
      elsif (index($ssrc, "\x27sha256-$h\x27") >= 0) { printf "ok: %s: style %d (%d bytes) sha256-%s\n", $f, $sn, length($body), $h }
      else { printf "FAIL: %s: style %d (%d bytes) sha256-%s is not in style-src. Put \x27sha256-%s\x27 in the CSP.\n", $f, $sn, length($body), $h, $h; $fail = 1 }
    }
    # A page can load all its CSS from a file; then there is no inline style to hash.
    if (!$sn) { print "ok: $f: no inline style (nothing to hash)\n" }

    # Inline style="..." attributes cannot be hashed; they only work with \x27unsafe-inline\x27,
    # which we forbid above. Flag them so they are moved into the hashed <style> or a stylesheet.
    unless (defined $ssrc && $ssrc =~ /\x27unsafe-inline\x27/) {
      my $attrs = 0; $attrs++ while /<[a-zA-Z][^>]*\sstyle\s*=/gs;
      if ($attrs) { printf "FAIL: %s: %d inline style=\x22...\x22 attribute(s); a hash cannot cover these. Move them into the hashed <style> block or a linked stylesheet.\n", $f, $attrs; $fail = 1 }
    }

    exit $fail;
  ' "$f" || fail=1
done
[ "$fail" = 0 ] || { echo "CSP hash out of date or inline hole open. Fix the page (see above)."; exit 1; }
