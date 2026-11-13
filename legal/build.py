#!/usr/bin/env python3
"""Политика конфиденциальности: один источник legal/privacy.md → копии в приложения.
Данные оператора — в legal/operator.json (ФИО, ИНН, e-mail, сведения о хранилище)."""
import json, os, pathlib
root = pathlib.Path(__file__).resolve().parent.parent
src = (root / 'legal/privacy.md').read_text(encoding='utf-8')
op = json.loads((root / 'legal/operator.json').read_text(encoding='utf-8'))
for k, v in op.items():
    src = src.replace('{{' + k + '}}', v)
for dst in ['windows/Lumo/Assets/privacy.md',
            'android/app/src/main/assets/privacy.md',
            'native/Resources/privacy.md']:
    p = root / dst
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(src, encoding='utf-8')
    print('→', dst)
missing = [k for k in ('OPERATOR', 'INN', 'EMAIL', 'STORAGE') if '{{' + k + '}}' in src or op.get(k, '').startswith('[')]
if missing: print('ВНИМАНИЕ: не заполнено в legal/operator.json:', ', '.join(missing))
