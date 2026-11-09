# Собирает страницу игр для приложений из web/games.html
import os
root = os.path.dirname(os.path.abspath(__file__))
html = open(os.path.join(root, 'games.html'), encoding='utf-8').read()
a = os.path.join(root, '..', 'android', 'app', 'src', 'main', 'assets')
os.makedirs(a, exist_ok=True)
open(os.path.join(a, 'games.html'), 'w', encoding='utf-8').write(html)
assert '"""#' not in html
open(os.path.join(root, '..', 'native', 'Sources', 'UI', 'GamesHTML.swift'), 'w', encoding='utf-8').write(
    '// Сгенерировано web/build_games.py — страница игр вдвоём\nlet gamesHTML = #"""\n' + html + '\n"""#\n')
print('ok', len(html))
