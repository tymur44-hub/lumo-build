#!/usr/bin/env python3
"""Веб-версия: согласие при регистрации, ссылка в настройках, страница lumomess.ru/?privacy.
Собирает патч web/patches/<имя>.json из legal/privacy.md (+ legal/operator.json)."""
import json, pathlib, re, sys, html
root = pathlib.Path(__file__).resolve().parent.parent
md = (root / 'legal/privacy.md').read_text(encoding='utf-8')
for k, v in json.loads((root / 'legal/operator.json').read_text(encoding='utf-8')).items():
    md = md.replace('{{' + k + '}}', v)

def inline(s):
    s = html.escape(s)
    return re.sub(r'\*\*(.+?)\*\*', r'<b>\1</b>', s)

out, ul = [], False
for line in md.splitlines():
    l = line.rstrip()
    if l.startswith('- '):
        if not ul: out.append('<ul>'); ul = True
        out.append('<li>' + inline(l[2:]) + '</li>'); continue
    if ul: out.append('</ul>'); ul = False
    if not l: continue
    if l.startswith('# '): out.append('<h1>' + inline(l[2:]) + '</h1>')
    elif l.startswith('## '): out.append('<h2>' + inline(l[3:]) + '</h2>')
    else: out.append('<p>' + inline(l) + '</p>')
if ul: out.append('</ul>')
body = '\n'.join(out)

js = r"""
/* ===== Политика конфиденциальности и согласие (152-ФЗ) ===== */
(()=>{
const POL=%s;
const st=document.createElement('style');
st.textContent=`#polv{position:fixed;inset:0;z-index:99999;background:var(--bg,#0c0d1a);color:var(--text,#eef0ff);overflow:auto;font:15px/1.55 system-ui,-apple-system,"Segoe UI",sans-serif}
#polv .pw{max-width:760px;margin:0 auto;padding:22px 20px 60px}#polv h1{font-size:26px;margin:8px 0 6px}#polv h2{font-size:18px;margin:22px 0 6px}
#polv p,#polv li{color:var(--text,#eef0ff);opacity:.92}#polv ul{padding-left:20px}#polv .pc{position:sticky;top:0;display:flex;justify-content:flex-end;padding:12px 16px;background:inherit}
#polv .pc button{border:0;border-radius:99px;width:38px;height:38px;background:rgba(255,255,255,.1);color:inherit;font-size:18px;cursor:pointer}
.lmagree{display:flex;gap:9px;align-items:flex-start;font-size:13px;line-height:1.4;color:var(--muted,#8d90b8);margin:8px 2px 2px;text-align:left}
.lmagree input{margin-top:2px;width:17px;height:17px;accent-color:var(--a1,#7c5cff);flex:none}.lmagree a{color:var(--a1,#7c5cff);font-weight:600;cursor:pointer;text-decoration:none}`;
document.head.appendChild(st);
window.lmPolicy=(page)=>{ let d=document.getElementById('polv'); if(d) d.remove(); d=document.createElement('div'); d.id='polv';
  d.innerHTML=(page?'':'<div class="pc"><button aria-label="Закрыть">✕</button></div>')+'<div class="pw">'+POL+'</div>';
  const b=d.querySelector('.pc button'); if(b) b.onclick=()=>d.remove(); document.body.appendChild(d); };
if(/[?&]privacy\b/.test(location.search)) { lmPolicy(true); document.title='Политика конфиденциальности — Lumo'; }
const ins=()=>{
  const err=document.getElementById('aErr'); if(!err||document.getElementById('aAgree')) return;
  const w=document.createElement('label'); w.className='lmagree'; w.id='aAgreeW';
  w.innerHTML='<input type="checkbox" id="aAgree"><span>Принимаю <a id="aPolL">Политику конфиденциальности</a> и даю согласие на обработку моих персональных данных</span>';
  err.parentNode.insertBefore(w,err);
  document.getElementById('aPolL').onclick=e=>{ e.preventDefault(); e.stopPropagation(); lmPolicy(); };
};
ins(); setTimeout(ins,600);
const need=()=>{ const c=document.getElementById('aAgree'); if(c&&!c.checked){ const e=document.getElementById('aErr'); if(e) e.textContent='Чтобы продолжить, примите Политику конфиденциальности'; return true; } return false; };
// регистрация (кнопка, Enter) и вход через Telegram
document.addEventListener('submit',e=>{ if(typeof regMode!=='undefined'&&regMode&&need()){ e.preventDefault(); e.stopImmediatePropagation(); } },true);
document.addEventListener('click',e=>{ const t=e.target.closest&&e.target.closest('#aBtn,#tgLogin,#tgLoginBtn,.tglogin'); if(!t) return;
  if((t.id==='aBtn'&&typeof regMode!=='undefined'&&regMode)||t.id!=='aBtn'){ if(need()){ e.preventDefault(); e.stopImmediatePropagation(); } } },true);
// ссылка в настройках — рядом с «Удалить аккаунт»
const setLink=()=>{ const del=document.getElementById('sDelAcc'); if(!del||document.getElementById('sPolicy')) return;
  const r=document.createElement('div'); r.className='perow'; r.id='sPolicy'; r.textContent='Политика конфиденциальности'; r.onclick=()=>lmPolicy();
  del.parentNode.insertBefore(r,del); };
new MutationObserver(setLink).observe(document.body,{childList:true,subtree:true});
})();
""" % json.dumps(body, ensure_ascii=False)

anchor = '\n\n\n\nboot();\n})();'
name = sys.argv[1] if len(sys.argv) > 1 else 'web58'
p = root / 'web/patches' / (name + '.json')
p.write_text(json.dumps([[anchor, js + anchor, 1]], ensure_ascii=False), encoding='utf-8')
print('→', p, len(js), 'символов')
