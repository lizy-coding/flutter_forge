#!/usr/bin/env python3
"""Export the in-app offline privacy notice as a standalone static page."""
from html import escape
from pathlib import Path
import re


root = Path(__file__).resolve().parent.parent
source = root / 'apps/flutter_forge/lib/app/offline_privacy.dart'
match = re.search(r"const offlinePrivacyPolicy = '''(.*?)''';", source.read_text(), re.S)
if not match:
    raise SystemExit('Offline privacy notice not found')
paragraphs = match[1].strip().split('\n\n')
body = '\n'.join('<p>' + escape(part).replace('\n', '<br>') + '</p>' for part in paragraphs)
page = '''<!doctype html>
<html lang="zh-CN"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'">
<title>Flutter Forge 离线版隐私说明</title>
<style>body{margin:0;background:#f5f7fa;color:#172735;font:17px/1.8 system-ui,sans-serif}main{max-width:800px;margin:auto;padding:32px 20px}article{padding:24px;background:white;border-radius:16px}h1{font-size:26px}p{overflow-wrap:anywhere}</style>
</head><body><main><h1>Flutter Forge 离线版隐私说明</h1><article>
''' + body + '\n</article></main></body></html>\n'
destination = root / 'apps/flutter_forge/web/privacy-offline.html'
destination.write_text(page)
print(destination)
