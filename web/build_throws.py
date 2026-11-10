"""Собирает страницу анимаций бросков для приложений и финальные кадры (PNG) для старых сообщений."""
import os, subprocess, json, sys
root = os.path.dirname(os.path.abspath(__file__)); repo = os.path.dirname(root)
js = open(os.path.join(root, 'throws.js'), encoding='utf-8').read()
page = open(os.path.join(root, 'throws_page.html'), encoding='utf-8').read().replace('/*THROWS*/', js)
for d in [os.path.join(repo, 'native/Resources'), os.path.join(repo, 'android/app/src/main/assets')]:
    open(os.path.join(d, 'throws.html'), 'w', encoding='utf-8').write(page)
print('throws.html ok')
