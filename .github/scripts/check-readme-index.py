"""Check a README.html index built from file names with ' # % & in them (#278).

usage: check-readme-index.py ROOT INDEX LABEL

Every link must open a file under ROOT the way a browser reads it (a '#' starts a
fragment, a '?' a query), and the page must link every fixture file and show every
cell as text.
"""
import html.parser
import os
import sys
import urllib.parse

root, index, label = sys.argv[1], sys.argv[2], sys.argv[3]


class Page(html.parser.HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.links, self.text = [], []

    def handle_starttag(self, tag, attrs):
        if tag == "a":
            self.links.append(dict(attrs).get("href", ""))

    def handle_data(self, data):
        self.text.append(data)


page = Page()
with open(index, encoding="utf-8") as f:
    page.feed(f.read())
text = " ".join(page.text)

fail = []
opened = set()
for href in page.links:
    path = urllib.parse.unquote(urllib.parse.urlsplit(href).path)
    full = os.path.join(root, path)
    if not os.path.isfile(full):
        fail.append(f"link does not open a file: href={href!r} -> {path!r}")
    else:
        opened.add(os.path.normpath(full))

for dirpath, _, files in os.walk(root):
    for name in files:
        full = os.path.normpath(os.path.join(dirpath, name))
        if name == "README.html" or not name.startswith("odd"):
            continue
        if not name.endswith((".pdf", ".zim", ".sh", ".apk", ".html")):
            continue
        if full not in opened:
            fail.append(f"no working link to {os.path.relpath(full, root)!r}")
        if "&" not in text or "'" not in text:
            fail.append("cell text lost its & or '")

for msg in dict.fromkeys(fail):
    print(f"FAIL {label}: {msg}")
if not fail:
    print(f"  OK   {label}: {len(page.links)} links open their files")
sys.exit(1 if fail else 0)
