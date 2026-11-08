#!/usr/bin/env python3
"""Finish the Pages build: fill the site URL into the front page and 404, write robots.txt and a root sitemap.

Usage: site-meta.py SITE_DIR BASE_URL   (BASE_URL from actions/configure-pages, e.g. https://example.org)
The URL is only known at build time (it lives in the repo's Pages settings), so the repo itself never names it.
"""
import pathlib, re, sys, xml.etree.ElementTree as ET

site, base = pathlib.Path(sys.argv[1]), sys.argv[2].rstrip("/")
if not re.fullmatch(r"https://[A-Za-z0-9.-]+(/[A-Za-z0-9._-]+)*", base):
    sys.exit(f"site-meta: unexpected base URL {base!r}")

for page in site.glob("*.html"):
    text = page.read_text(encoding="utf-8")
    page.write_text(text.replace("@SITE_URL@", base), encoding="utf-8")
left = [p.name for p in site.glob("*.html") if "@SITE_URL@" in p.read_text(encoding="utf-8")]
if left:
    sys.exit(f"site-meta: placeholder left in {left}")

ns = {"s": "http://www.sitemaps.org/schemas/sitemap/0.9"}
docs = site / "docs" / "sitemap.xml"
urls = [f"{base}/"]
if docs.exists():
    urls += [loc.text.strip() for loc in ET.parse(docs).getroot().findall("s:url/s:loc", ns) if loc.text]
if len(urls) < 2:
    sys.exit("site-meta: docs sitemap is empty (site_url not set for mkdocs?)")
bad = [u for u in urls if not u.startswith(base + "/")]
if bad:
    sys.exit(f"site-meta: sitemap URLs outside {base}: {bad[:3]}")

body = "".join(f"  <url><loc>{u}</loc></url>\n" for u in urls)
(site / "sitemap.xml").write_text(
    '<?xml version="1.0" encoding="UTF-8"?>\n'
    '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' + body + "</urlset>\n", encoding="utf-8")
(site / "robots.txt").write_text(f"User-agent: *\nAllow: /\n\nSitemap: {base}/sitemap.xml\n", encoding="utf-8")
print(f"site-meta: {len(urls)} URLs, robots.txt, placeholders filled for {base}")
