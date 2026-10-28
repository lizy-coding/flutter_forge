const offlineOverviewUrl = 'forge-lesson://overview';
const offlineCounterUrl = 'forge-lesson://counter';

bool isOfflineDocument(String url) =>
    url == offlineOverviewUrl || url == offlineCounterUrl;

String offlineDocumentHtml(String url) {
  if (!isOfflineDocument(url)) throw ArgumentError.value(url, 'url');
  final body = url == offlineOverviewUrl
      ? '<h1>网页容器与本地内容</h1><p>这份 HTML 随应用安装，不访问网站。</p>'
            '<p>Flutter 管理页面生命周期，系统 WebView 负责排版和绘制。</p>'
            '<p>使用上方教学页按钮，观察页面切换、前进、后退与刷新。</p>'
      : '<h1>JavaScript 与页面状态</h1><p>点击按钮，观察页面内的局部更新。</p>'
            '<button onclick="document.getElementById(\'count\').textContent = ++count">增加计数</button>'
            '<p>计数：<span id="count">0</span></p><script>let count = 0;</script>';
  return '''<!doctype html><html lang="zh-CN"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; script-src 'unsafe-inline'; connect-src 'none'; form-action 'none'">
<style>body{font-family:sans-serif;padding:20px;line-height:1.7;color:#172735;background:#f1f6f9}h1{font-size:22px}button{padding:12px;border-radius:8px}</style>
</head><body>$body</body></html>''';
}
