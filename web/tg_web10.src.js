/* ===== Мини-игры: броски в чате и игры вдвоём (крестики-нолики, шашки, морской бой) ===== */
P.gamepad='<path d="M7 8h10a5 5 0 0 1 4.6 7l-.9 2.1a2.6 2.6 0 0 1-4.3.7L14.6 16H9.4l-1.8 1.8a2.6 2.6 0 0 1-4.3-.7L2.4 15A5 5 0 0 1 7 8z"/><path d="M7.5 10.5v3M6 12h3"/><circle cx="16" cy="11" r=".6" fill="currentColor"/><circle cx="18" cy="13" r=".6" fill="currentColor"/>';
const LG_GAMES_HTML=__GAMES_HTML__;
const LG_TITLES={ttt:'Крестики-нолики',checkers:'Шашки',sea:'Морской бой'};
const LG_THROWS=[['dice','Кубик'],['darts','Дартс'],['basket','Баскетбол'],['football','Футбол'],['coin','Монетка']];
(function(){ const st=document.createElement('style'); st.textContent=`
.lgsh{display:grid;grid-template-columns:repeat(5,1fr);gap:8px;margin:6px 0 4px}
.lgsh button{border:0;background:var(--panel2);border-radius:16px;padding:12px 4px 9px;color:var(--text);font:inherit;font-size:12px;font-weight:700;display:flex;flex-direction:column;align-items:center;gap:6px;cursor:pointer;transition:transform .12s,background .2s}
.lgsh button:hover{background:var(--active)}.lgsh button:active{transform:scale(.94)}
.lgsh svg{width:38px;height:38px}
.lghd{font-size:12px;font-weight:800;letter-spacing:.4px;color:var(--muted);margin:14px 2px 8px}
.lgg{display:flex;flex-direction:column;gap:8px}
.lgg button{display:flex;align-items:center;gap:12px;border:2px solid transparent;background:var(--panel2);border-radius:16px;padding:10px 12px;color:var(--text);font:inherit;text-align:left;cursor:pointer;transition:border-color .2s}
.lgg button.on{border-color:var(--a1)}
.lgg button i{width:44px;height:44px;border-radius:13px;display:grid;place-items:center;flex:none}
.lgg button i svg{width:28px;height:28px}
.lgg button b{display:block;font-size:15px}.lgg button span{display:block;font-size:12.5px;color:var(--muted)}
.lgst{display:flex;gap:6px;flex-wrap:wrap;margin-top:4px}
.lgst button{border:0;border-radius:12px;padding:8px 12px;background:var(--panel2);color:var(--text);font:inherit;font-weight:700;font-size:13.5px;cursor:pointer;display:flex;align-items:center;gap:5px}
.lgst button.on{background:linear-gradient(135deg,var(--a1),var(--a2));color:#fff}
.lgst button svg{width:14px;height:14px}
.lgst input{width:96px;border:0;border-radius:12px;padding:8px 10px;background:var(--panel2);color:var(--text);font:inherit;font-weight:700;font-size:13.5px;outline:0}
.lgnote{font-size:12.5px;color:var(--muted);margin-top:8px;line-height:1.4}
.b.lgdb{padding:8px 10px 6px;min-width:150px;text-align:center}
.lgd{width:132px;height:132px;margin:2px auto 0;display:block}
.lgd.anim{animation:lgRoll 1.1s cubic-bezier(.3,.6,.4,1)}
.lgd.anim.coin{animation:lgFlip 1.1s cubic-bezier(.3,.6,.4,1)}
@keyframes lgRoll{0%{transform:translateY(-30px) rotate(-200deg) scale(.6);opacity:.2}55%{transform:translateY(6px) rotate(20deg) scale(1.05);opacity:1}75%{transform:translateY(-6px) rotate(-6deg)}100%{transform:none}}
@keyframes lgFlip{0%{transform:translateY(-34px) rotateY(0) scale(.7)}60%{transform:translateY(4px) rotateY(1440deg) scale(1.05)}100%{transform:rotateY(1800deg)}}
.lgres{font-weight:800;font-size:15px;margin-top:2px}
.lgd.anim+.lgres{animation:lgIn .3s ease 1s both}
@keyframes lgIn{from{opacity:0;transform:translateY(6px)}to{opacity:1;transform:none}}
.b.lggb{min-width:240px;max-width:300px}
.lggh{display:flex;gap:11px;align-items:center}
.lggh i{width:46px;height:46px;border-radius:14px;display:grid;place-items:center;flex:none}
.lggh i svg{width:30px;height:30px}
.lggh b{display:block;font-size:15.5px}.lggh span{display:block;font-size:13px;opacity:.78}
.lggp{margin-top:8px;font-size:13.5px;display:flex;align-items:center;gap:6px;flex-wrap:wrap}
.lggp .vs{opacity:.6;font-size:12px;font-weight:800}
.lggst{display:inline-flex;align-items:center;gap:4px;font-weight:800;color:#f5b942}
.lggst svg{width:14px;height:14px}
.lggbtn{margin-top:10px;width:100%;height:40px;border:0;border-radius:12px;font:inherit;font-weight:800;font-size:14.5px;cursor:pointer;background:rgba(255,255,255,.18);color:inherit}
.m:not(.me) .lggbtn{background:linear-gradient(135deg,var(--a1),var(--a2));color:#fff}
.m:not(.me) .lggbtn.ghost{background:var(--panel2);color:var(--text)}
#lgOv{position:fixed;inset:0;z-index:9000;background:var(--bg);transform:translateY(100%);transition:transform .38s cubic-bezier(.2,.9,.3,1)}
#lgOv.on{transform:none}
#lgOv iframe{width:100%;height:100%;border:0;display:block}
@media(min-width:900px){#lgOv{inset:auto;left:50%;top:50%;width:480px;height:min(860px,94vh);border-radius:26px;overflow:hidden;box-shadow:0 30px 80px rgba(0,0,0,.5);transform:translate(-50%,-40%) scale(.96);opacity:0;transition:transform .3s,opacity .3s}#lgOv.on{transform:translate(-50%,-50%);opacity:1}}
#lgBg{position:fixed;inset:0;z-index:8999;background:rgba(0,0,0,.45);opacity:0;transition:opacity .3s}#lgBg.on{opacity:1}
`; document.head.appendChild(st); })();

const LG_COL={ttt:'linear-gradient(135deg,#22c1ff,#3a7bff)',checkers:'linear-gradient(135deg,#a7743f,#6b4426)',sea:'linear-gradient(135deg,#2bb3ff,#1460c8)'};
function lgIcon(k){
  if(k==='ttt') return '<svg viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.4" stroke-linecap="round"><path d="M4 4l6 6M10 4 4 10"/><circle cx="17" cy="17" r="3.4"/><path d="M8.5 13v7M15.5 4v7M13 8.5h7M4 15.5h7" opacity=".45" stroke-width="1.6"/></svg>';
  if(k==='checkers') return '<svg viewBox="0 0 24 24"><ellipse cx="12" cy="15.5" rx="8" ry="3.4" fill="#2a1a10"/><rect x="4" y="10" width="16" height="5.5" fill="#2a1a10"/><ellipse cx="12" cy="10" rx="8" ry="3.4" fill="#f4ead6"/><ellipse cx="12" cy="10" rx="4.6" ry="1.9" fill="none" stroke="#c9a46a" stroke-width="1.2"/></svg>';
  return '<svg viewBox="0 0 24 24" fill="#fff"><path d="M3 15h18l-2.6 4.2a2 2 0 0 1-1.7.8H7.3a2 2 0 0 1-1.7-.8z"/><path d="M11 3.5v10H5.5z" opacity=".9"/><path d="M12.5 6v7.5H18z" opacity=".65"/></svg>'; }
function lgThrowSvg(k,v){
  if(k==='dice'){ const P_={1:[[50,50]],2:[[30,30],[70,70]],3:[[28,28],[50,50],[72,72]],4:[[30,30],[70,30],[30,70],[70,70]],5:[[28,28],[72,28],[50,50],[28,72],[72,72]],6:[[30,26],[70,26],[30,50],[70,50],[30,74],[70,74]]}[v]||[];
    return `<svg viewBox="0 0 100 100"><defs><linearGradient id="lgdg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#ffffff"/><stop offset="1" stop-color="#dcd8f4"/></linearGradient></defs><rect x="10" y="10" width="80" height="80" rx="20" fill="url(#lgdg)" stroke="rgba(0,0,0,.12)" stroke-width="2"/>${P_.map(p=>`<circle cx="${p[0]}" cy="${p[1]}" r="8" fill="${v===1?'#e0284f':'#25264a'}"/>`).join('')}</svg>`; }
  if(k==='darts'){ const R_={6:[50,50],5:[56,42],4:[38,58],3:[66,64],2:[30,34],1:[88,14]}[v]||[50,50];
    return `<svg viewBox="0 0 100 100"><circle cx="50" cy="50" r="42" fill="#25264a"/><circle cx="50" cy="50" r="34" fill="#f2efe4"/><circle cx="50" cy="50" r="26" fill="#e0284f"/><circle cx="50" cy="50" r="18" fill="#f2efe4"/><circle cx="50" cy="50" r="10" fill="#2bb673"/><circle cx="50" cy="50" r="4" fill="#e0284f"/>
      <g transform="translate(${R_[0]} ${R_[1]}) rotate(-35)"><rect x="-1.6" y="-26" width="3.2" height="24" rx="1.4" fill="#5a5d86"/><path d="M0-30l-7-8h14z" fill="#7c5cff"/><path d="M-1.6-2h3.2L0 3z" fill="#ccc"/></g></svg>`; }
  if(k==='basket'){ const ok=v>=4;
    return `<svg viewBox="0 0 100 100"><rect x="18" y="8" width="64" height="40" rx="5" fill="#f2efe4" stroke="#c7c3b5" stroke-width="2"/><rect x="38" y="22" width="24" height="16" fill="none" stroke="#e0284f" stroke-width="2.5"/>
      <path d="M32 44h36l-6 22H38z" fill="none" stroke="#fff" stroke-width="2" stroke-dasharray="3 3"/><rect x="30" y="41" width="40" height="5" rx="2.5" fill="#ff6a2b"/>
      <g transform="translate(${ok?50:74} ${ok?62:76})"><circle r="13" fill="#ff8a3d"/><path d="M-13 0h26M0-13v26M-9-9q9 9 0 18M9-9q-9 9 0 18" stroke="#7a2e0a" stroke-width="1.6" fill="none"/></g></svg>`; }
  if(k==='football'){ const ok=v>=3;
    return `<svg viewBox="0 0 100 100"><path d="M10 70V24h80v46" fill="none" stroke="#f2efe4" stroke-width="4"/><path d="M14 28h72v40H14z" fill="none" stroke="rgba(255,255,255,.35)" stroke-width="1" stroke-dasharray="4 4"/><rect x="0" y="80" width="100" height="20" fill="#2bb673" opacity=".7"/>
      <g transform="translate(${ok?40:88} ${ok?48:22})"><circle r="12" fill="#fff" stroke="#222" stroke-width="1.5"/><path d="M0-5l5 3.6-2 6h-6l-2-6z" fill="#222"/></g></svg>`; }
  return `<svg viewBox="0 0 100 100"><defs><radialGradient id="lgcg" cx=".35" cy=".3"><stop offset="0" stop-color="#ffe7a1"/><stop offset="1" stop-color="#d79b22"/></radialGradient></defs><circle cx="50" cy="50" r="40" fill="url(#lgcg)" stroke="#b07a12" stroke-width="3"/><circle cx="50" cy="50" r="31" fill="none" stroke="#b07a12" stroke-width="1.5" stroke-dasharray="2 3"/>
    <text x="50" y="62" text-anchor="middle" font-size="34" font-weight="800" fill="#8a5c08" font-family="Georgia,serif">${v===1?'О':'Р'}</text></svg>`; }
function lgThrowLabel(k,v){
  if(k==='dice') return 'Выпало '+v;
  if(k==='darts') return v===6?'В яблочко!':v===1?'Мимо':'Очков: '+v;
  if(k==='basket') return v>=4?'Попал!':'Мимо';
  if(k==='football') return v>=3?'Гол!':'Мимо';
  return v===1?'Орёл':'Решка'; }
const lgSeen=new Set();
function lgWrap(m,inner,cls){ const mine=m.sender_id===S.me.id; const c=cur()||{};
  const nm=c.type==='group'&&!mine?`<div style="font-weight:700;font-size:13px;color:var(--a2);margin-bottom:4px;text-align:left">${esc(profName(m.sender_id))}</div>`:'';
  return `<div class="m ${mine?'me':''} tail grp first" data-id="${m.id}"><div class="b ${cls}">${nm}${inner}<div class="tm">${hm(new Date(m.created_at))}</div>${reactsHtml(m)}</div></div>`; }
function lgDiceHtml(m){ const mt=m.meta||{}, k=mt.g||'dice', v=+mt.v||1;
  const fresh=!lgSeen.has(m.id)&&Date.now()-new Date(m.created_at).getTime()<6000; lgSeen.add(m.id);
  return lgWrap(m,`<div class="lgd ${k}${fresh?' anim':''}">${lgThrowSvg(k,v)}</div><div class="lgres">${esc(lgThrowLabel(k,v))}</div>`,'lgdb'); }
function lgGameStatus(mt,me){
  const st=mt.st||'invite';
  if(st==='invite') return mt.p1===me?'Ждём соперника':'Приглашение сыграть';
  if(st==='setup') return 'Расстановка кораблей';
  if(st==='active') return 'Идёт игра';
  if(st==='declined') return 'Приглашение отклонено';
  if(st==='canceled') return 'Игра отменена';
  return mt.winner?(mt.winner===me?'Вы победили':'Победил(а) '+(mt.wn||'')):'Ничья'; }
function lgGameHtml(m){ const mt=m.meta||{}, me=S.me.id, k=mt.g||'ttt', st=mt.st||'invite';
  const players=mt.p2?`<b>${esc(mt.p1n||'')}</b><span class="vs">VS</span><b>${esc(mt.p2n||'')}</b>`:`<b>${esc(mt.p1n||profName(m.sender_id))}</b><span class="vs">VS</span><span style="opacity:.7">ждём соперника</span>`;
  const btn=st==='invite'&&mt.p1!==me&&m.sender_id!==me?'Принять':st==='invite'?'Открыть':st==='active'||st==='setup'?((mt.p1===me||mt.p2===me)?'Играть':'Смотреть'):'Посмотреть';
  return lgWrap(m,`<div class="lggh"><i style="background:${LG_COL[k]}">${lgIcon(k)}</i><div><b>${LG_TITLES[k]||'Игра'}</b><span>${esc(lgGameStatus(mt,me))}</span></div></div>
<div class="lggp">${players}${mt.stake?`<span style="flex:1"></span><span class="lggst">${ic('gem')}${mt.stake}</span>`:''}</div>
<button class="lggbtn${btn==='Посмотреть'?' ghost':''}" data-lgopen="${esc(mt.game||'')}">${btn}</button>`,'lggb'); }
{ const _lf=window.lfMsg; window.lfMsg=m=>{ if(m&&!m.deleted){ if(m.kind==='dice') return lgDiceHtml(m); if(m.kind==='game') return lgGameHtml(m); } return _lf?_lf(m):null; }; }

function lgDark(){ const c=getComputedStyle(document.body).backgroundColor.match(/\d+/g)||[0,0,0]; return (+c[0]*.3+ +c[1]*.59+ +c[2]*.11)<128; }
async function lgOpen(gameId){ if(!gameId) return; const {data:{session}}=await sb.auth.getSession(); if(!session) return toast('Войдите заново');
  document.getElementById('lgOv')?.remove(); document.getElementById('lgBg')?.remove();
  const cfg={api:SUPABASE_URL+'/functions/v1/lumo-games',apikey:SUPABASE_KEY,token:session.access_token,gameId,theme:lgDark()?'dark':'light'};
  const bg=document.createElement('div'); bg.id='lgBg'; const o=document.createElement('div'); o.id='lgOv';
  const fr=document.createElement('iframe'); fr.srcdoc=LG_GAMES_HTML.replace('/*CFG*/','window.LUMO_GAME='+JSON.stringify(cfg)+';'); o.appendChild(fr);
  document.body.appendChild(bg); document.body.appendChild(o); requestAnimationFrame(()=>requestAnimationFrame(()=>{ o.classList.add('on'); bg.classList.add('on'); }));
  bg.onclick=lgClose; }
function lgClose(){ const o=document.getElementById('lgOv'), bg=document.getElementById('lgBg'); if(!o) return; o.classList.remove('on'); bg&&bg.classList.remove('on'); setTimeout(()=>{ o.remove(); bg&&bg.remove(); },400); }
addEventListener('message',e=>{ if(e.data&&e.data.lumoGame==='close') lgClose(); });
addEventListener('keydown',e=>{ if(e.key==='Escape'&&document.getElementById('lgOv')) lgClose(); });
document.addEventListener('click',e=>{ const b=e.target.closest&&e.target.closest('[data-lgopen]'); if(!b) return; e.stopPropagation(); e.preventDefault(); lgOpen(b.dataset.lgopen); },true);

async function lgCall(body){ const {data:{session}}=await sb.auth.getSession();
  const r=await fetch(SUPABASE_URL+'/functions/v1/lumo-games',{method:'POST',headers:{'Content-Type':'application/json',apikey:SUPABASE_KEY,Authorization:'Bearer '+(session&&session.access_token)},body:JSON.stringify(body)});
  const j=await r.json().catch(()=>({error:'Ошибка сети'})); if(j.error) throw new Error(j.error); return j; }
window.lmGames=()=>{ const c=cur(); if(!c) return; const chatId=c.chat_id;
  if(c.type==='channel') return toast('Игры доступны в личных чатах и группах');
  let game='ttt', stake=0;
  const desc={ttt:'Три в ряд на поле 3×3',checkers:'Русские шашки, взятие обязательно',sea:'Флот 10 кораблей, поле 10×10'};
  const close=modal('Игры',`<div class="lghd">БРОСИТЬ В ЧАТ</div><div class="lgsh">${LG_THROWS.map(t=>`<button data-th="${t[0]}">${lgThrowSvg(t[0],t[0]==='dice'?5:t[0]==='coin'?1:t[0]==='darts'?6:5)}${t[1]}</button>`).join('')}</div>
<div class="lghd">ИГРАТЬ ВДВОЁМ</div><div class="lgg">${Object.keys(LG_TITLES).map(k=>`<button data-gk="${k}" class="${k===game?'on':''}"><i style="background:${LG_COL[k]}">${lgIcon(k)}</i><div><b>${LG_TITLES[k]}</b><span>${desc[k]}</span></div></button>`).join('')}</div>
<div class="lghd">СТАВКА ЛЮМЕНАМИ</div><div class="lgst">${[0,10,50,100,500].map(v=>`<button data-sk="${v}" class="${v===stake?'on':''}">${v?ic('gem')+v:'Без ставки'}</button>`).join('')}<input id="lgSk" type="number" min="0" max="1000" placeholder="Своя"></div>
<div class="lgnote">Ставку вносят оба игрока, победитель забирает обе. При ничьей ставки возвращаются. Если соперник не примет приглашение, ставку можно вернуть отменой. Максимум — 1000 люменов.</div>`,
   [['Отмена','ghost'],['Пригласить','primary',async cl=>{ const btn=document.querySelector('.ov .modal .btn.primary'); if(btn) btn.disabled=true;
      try{ const g=await lgCall({action:'new',chat_id:chatId,kind:game,stake}); cl(); toast('Приглашение отправлено'); lgOpen(g.id); }catch(err){ toast(err.message); if(btn) btn.disabled=false; } }]]);
  const ov=[...document.querySelectorAll('.ov')].pop(); if(!ov) return;
  ov.querySelectorAll('[data-th]').forEach(b=>b.onclick=async()=>{ close(); const {error}=await sb.rpc('lm_throw',{p_chat:chatId,p_kind:b.dataset.th}); if(error) toast(error.message); });
  ov.querySelectorAll('[data-gk]').forEach(b=>b.onclick=()=>{ game=b.dataset.gk; ov.querySelectorAll('[data-gk]').forEach(x=>x.classList.toggle('on',x===b)); });
  const inp=ov.querySelector('#lgSk');
  ov.querySelectorAll('[data-sk]').forEach(b=>b.onclick=()=>{ stake=+b.dataset.sk; inp.value=''; ov.querySelectorAll('[data-sk]').forEach(x=>x.classList.toggle('on',x===b)); });
  inp.oninput=()=>{ let v=Math.floor(+inp.value||0); if(v>1000){ v=1000; inp.value=1000; } stake=Math.max(0,v); ov.querySelectorAll('[data-sk]').forEach(x=>x.classList.toggle('on',!inp.value&&+x.dataset.sk===stake)); }; };
