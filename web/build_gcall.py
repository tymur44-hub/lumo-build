# Собирает страницу группового звонка для приложений из web/gcall.js
import os
root = os.path.dirname(os.path.abspath(__file__))
js = open(os.path.join(root, 'gcall.js'), encoding='utf-8').read()
V = '2.18.10'
html = f'''<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,viewport-fit=cover">
<style>html,body{{margin:0;background:#0b0b10;height:100%;overflow:hidden}}</style>
<script src="https://cdn.jsdelivr.net/npm/livekit-client@{V}/dist/livekit-client.umd.js"></script>
<script>{js}</script></head><body><script>/*CFG*/
function bye(){{ try{{window.webkit.messageHandlers.lumo.postMessage('leave')}}catch(e){{}} try{{LumoBridge.leave()}}catch(e){{}} }}
function go(){{ GCall.open(Object.assign({{}}, window.LUMO_CALL||{{}}, {{onLeave:bye}})); }}
if(window.LivekitClient) go(); else {{ var s=document.createElement('script'); s.src='https://unpkg.com/livekit-client@{V}/dist/livekit-client.umd.js'; s.onload=go; s.onerror=go; document.head.appendChild(s); }}
</script></body></html>'''
a = os.path.join(root, '..', 'android', 'app', 'src', 'main', 'assets')
os.makedirs(a, exist_ok=True)
open(os.path.join(a, 'gcall.html'), 'w', encoding='utf-8').write(html)
assert '"""#' not in html
open(os.path.join(root, '..', 'native', 'Sources', 'Calls', 'GCallHTML.swift'), 'w', encoding='utf-8').write(
    '// Сгенерировано web/build_gcall.py — страница группового звонка (LiveKit)\nlet gcallHTML = #"""\n' + html + '\n"""#\n')
print('ok', len(html))
