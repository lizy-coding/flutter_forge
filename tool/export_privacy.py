#!/usr/bin/env python3
"""Generate the public full-edition policy from the in-app policy text."""
import argparse
from html import escape
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent.parent


def render(source):
    match = re.search(r"const fullPrivacyPolicy = '''(.*?)''';", source, re.S)
    if not match:
        raise ValueError('Full-edition privacy policy not found')
    paragraphs = match[1].strip().split('\n\n')
    body = '\n'.join('<p>' + escape(p).replace('\n', '<br>') + '</p>' for p in paragraphs)
    return '''<!doctype html>
<html lang="zh-CN"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'">
<title>Flutter Forge 完整版隐私说明</title>
<style>body{margin:0;background:#f5f7fa;color:#172735;font:17px/1.8 system-ui,sans-serif}main{max-width:800px;margin:auto;padding:32px 20px}article{padding:24px;background:white;border-radius:16px}h1{font-size:26px}p{overflow-wrap:anywhere}</style>
</head><body><main><h1>Flutter Forge 完整版隐私说明</h1><article>
''' + body + '\n</article></main></body></html>\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    html = render((ROOT / 'apps/flutter_forge/lib/app/full_privacy.dart').read_text(encoding='utf-8'))
    output = ROOT / 'apps/flutter_forge/web/privacy.html'
    if args.check:
        if not output.is_file() or output.read_text(encoding='utf-8') != html:
            raise SystemExit('Public privacy page differs from in-app policy; run python3 tool/export_privacy.py')
        print('privacy page: up to date')
    else:
        output.write_text(html, encoding='utf-8')
        print(output)


if __name__ == '__main__':
    main()
