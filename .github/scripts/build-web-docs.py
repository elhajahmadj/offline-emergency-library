"""Publish the on-drive guides to the website's Docs page (#205, #253).

docs/*.html are the source (they ship on the drive). The site serves web/ only and shows each
guide in an iframe, so links are rewritten while copying into web/docs/:
  - a link to another guide (by its place on the drive, from place_doc in get-offline-library.sh)
    becomes the sibling X.html and stays in the frame; a .md link becomes its .html;
  - a link to a drive-only file (PDFs, folders, generated pages) becomes plain text;
  - <base target="_blank"> sends external links to a new tab (many sites refuse to be framed).
--check rebuilds in memory, compares with web/docs/ (ignoring CR/LF) and fails on any relative
link that does not resolve inside web/docs/.
Usage: build-web-docs.py [--check]   (run from anywhere; build-web-docs.sh wraps it)
"""
import posixpath, re, sys
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[2]
SRC, DST = ROOT / 'docs', ROOT / 'web' / 'docs'
# guide base name -> its path on the drive without extension, e.g. Medical-READ-ME-FIRST -> Medical/READ-ME-FIRST
PLACE = dict(re.findall(r'place_doc +"([^"]+)" +"\$ROOT/([^"]+)"',
                        (ROOT / 'get-offline-library.sh').read_text(encoding='utf-8')))
GUIDE_AT = {v: k for k, v in PLACE.items()}
LINK = re.compile(r'<a\b([^>]*?)\bhref="([^"]*)"([^>]*)>(.*?)</a>', re.S)
EXTERNAL = re.compile(r'^[a-z][a-z0-9+.-]*:', re.I)


def transform(name, text):
    here = posixpath.dirname(PLACE.get(name, name))

    def fix(m):
        pre, href, post, inner = m.groups()
        if EXTERNAL.match(href):
            return m.group(0)
        if href.startswith('#'):
            return f'<a{pre}href="{href}"{post} target="_self">{inner}</a>'
        path, _, frag = href.partition('#')
        target = posixpath.normpath(posixpath.join(here, unquote(path)))
        guide = GUIDE_AT.get(re.sub(r'\.(html|md)$', '', target)) if re.search(r'\.(html|md)$', target) else None
        if guide:
            return f'<a{pre}href="{guide}.html{"#" + frag if frag else ""}"{post} target="_self">{inner}</a>'
        return f'<span title="On the offline drive only">{inner}</span>'

    text = LINK.sub(fix, text)
    return text.replace('<head>', '<head><base target="_blank">', 1)


def norm(s):
    return s.replace('\r\n', '\n')


def main():
    check = sys.argv[1:] == ['--check']
    out = {f.name: transform(f.stem, f.read_text(encoding='utf-8')) for f in sorted(SRC.glob('*.html'))}
    missing = [n for n in out if n[:-5] not in PLACE]
    if missing:
        sys.exit(f'FAIL: no place_doc line for {missing} in get-offline-library.sh')
    if not check:
        DST.mkdir(parents=True, exist_ok=True)
        for f in DST.glob('*.html'):
            f.unlink()
        for n, t in out.items():
            (DST / n).write_text(t, encoding='utf-8', newline='\n')
        print(f'Wrote {len(out)} guides to web/docs/.')
        return
    bad = []
    for n, t in out.items():
        p = DST / n
        if not p.exists() or norm(p.read_text(encoding='utf-8')) != norm(t):
            bad.append(f'web/docs/{n} is missing or out of date')
        for href in re.findall(r'href="([^"#]+)', t):
            if not EXTERNAL.match(href) and not (DST / unquote(href)).is_file():
                bad.append(f'web/docs/{n} links {href}, which is not in web/docs/')
    bad += [f'web/docs/{p.name} has no source in docs/ (stale copy)' for p in DST.glob('*.html') if p.name not in out]
    for b in bad:
        print('FAIL: ' + b)
    if bad:
        sys.exit('web/docs/ is out of date. Run: bash .github/scripts/build-web-docs.sh')
    print(f'OK: web/docs/ matches docs/*.html ({len(out)} guides, every relative link resolves).')


if __name__ == '__main__':
    main()
