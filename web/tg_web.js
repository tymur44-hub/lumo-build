/* ===== TG: истории как в Telegram, публикации, оформление и музыка профиля ===== */
(function(){
Object.assign(P,{
  tgrid:'<rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/>',
  tarch:'<rect x="3" y="4" width="18" height="5" rx="1.5"/><path d="M5 9v10a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V9M10 13h4"/>',
  tnote:'<path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/>',
  tok:'<circle cx="12" cy="12" r="9"/><path d="M8 12l3 3 5-6"/>',
  tcirc:'<circle cx="12" cy="12" r="9"/>',
  tchev:'<path d="M9 6l6 6-6 6"/>'
});
const TGC=[['#6f8cff','#3d4fd8'],['#b06bff','#6a2fd8'],['#ff6fae','#d8336f'],['#ff8a4c','#e0442a'],['#ffc24c','#e08a12'],['#4cd98a','#1f9e5c'],['#3cc6e0','#1a7fa8'],['#7a8296','#434a5e'],['#ff5f6d','#c0263a'],['#9be15d','#4caf2e'],['#5ee7df','#2a9d8f'],['#2b2d42','#101120']];
const PSVG={
  'star.fill':'<path d="M12 2l3 6.5 7 .8-5.2 4.8 1.5 7L12 17.6 5.7 21.1l1.5-7L2 9.3l7-.8z"/>',
  'heart.fill':'<path d="M12 21s-8-5.2-8-11a4.5 4.5 0 0 1 8-2.8A4.5 4.5 0 0 1 20 10c0 5.8-8 11-8 11z"/>',
  'sparkles':'<path d="M12 2l2 6 6 2-6 2-2 6-2-6-6-2 6-2z"/>',
  'moon.stars.fill':'<path d="M20 15A8 8 0 1 1 9 4a7 7 0 0 0 11 11z"/>',
  'leaf.fill':'<path d="M4 20C4 9 11 4 21 3c-1 10-6 17-17 17z"/>',
  'bolt.fill':'<path d="M13 2L4 14h7l-1 8 9-12h-7z"/>',
  'music.note':'<path d="M9 17V5l11-2v12"/><circle cx="6" cy="17" r="3"/><circle cx="17" cy="15" r="3"/>',
  'pawprint.fill':'<circle cx="6" cy="10" r="2"/><circle cx="10" cy="6" r="2"/><circle cx="14" cy="6" r="2"/><circle cx="18" cy="10" r="2"/><path d="M12 11c-3 0-6 4-6 6.5S8 20 12 20s6-.5 6-2.5S15 11 12 11z"/>',
  'snowflake':'<path d="M11 2h2v20h-2zM2 11h20v2H2zM4.9 6.3l1.4-1.4 12.8 12.8-1.4 1.4zM17.7 4.9l1.4 1.4L6.3 19.1l-1.4-1.4z"/>',
  'flame.fill':'<path d="M12 2c1 4 6 6 6 12a6 6 0 0 1-12 0c0-3 2-5 3-6 0 2 1 3 2 3 0-4-1-6 1-9z"/>',
  'gamecontroller.fill':'<path d="M7 7h10a5 5 0 0 1 4.8 6.4l-1 3.4A2.5 2.5 0 0 1 16.5 18L14 15h-4l-2.5 3a2.5 2.5 0 0 1-4.3-1.2l-1-3.4A5 5 0 0 1 7 7z"/>',
  'crown.fill':'<path d="M3 7l4.5 4L12 4l4.5 7L21 7l-2 12H5z"/>',
  'cloud.fill':'<path d="M7 19a5 5 0 0 1-.6-10A7 7 0 0 1 20 10.5 4.3 4.3 0 0 1 18 19z"/>',
  'camera.fill':'<path d="M4 7h3l2-3h6l2 3h3a1 1 0 0 1 1 1v11a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V8a1 1 0 0 1 1-1z"/>',
  'airplane':'<path d="M21 16v-2l-8-5V3.5a1.5 1.5 0 0 0-3 0V9l-8 5v2l8-2.5V19l-2 1.5V22l3.5-1 3.5 1v-1.5L13 19v-5.5z"/>',
  'sun.max.fill':'<circle cx="12" cy="12" r="5"/><path d="M11 1h2v4h-2zM11 19h2v4h-2zM1 11h4v2H1zM19 11h4v2h-4z"/>'
};
const tst=document.createElement('style'); tst.setAttribute('data-lumo-own','1'); tst.textContent=`
.tgsty{position:relative;isolation:isolate;color:#fff}
.tgsty>.tgbg{position:absolute;left:-40px;right:-40px;top:-220px;bottom:0;z-index:-1;overflow:hidden;border-radius:0 0 26px 26px}
.tgsty h1,.tgsty h2,.tgsty .st,.tgsty .stt,.tgsty .st.live{color:#fff!important}
.tgsty .st,.tgsty .stt{opacity:.86}
.tgsty .iact button,.tgsty .tga button{background:rgba(255,255,255,.18)!important;color:#fff!important;border:.7px solid rgba(255,255,255,.22)}
.tgglow{position:absolute;width:420px;height:420px;transform:translate(-50%,-50%);background:radial-gradient(circle,rgba(255,255,255,.32),rgba(255,255,255,0) 62%);pointer-events:none}
.tgpat{position:absolute;width:0;height:0;animation:tgdrift 7s ease-in-out infinite alternate;pointer-events:none}
.tgpat i{position:absolute;display:grid;place-items:center}
.tgpat i svg{width:100%;height:100%;fill:currentColor}
@keyframes tgdrift{from{transform:rotate(-7deg) scale(.97)}to{transform:rotate(7deg) scale(1.05)}}
.tgmus{display:flex;align-items:center;gap:10px;margin:12px auto 0;max-width:420px;padding:8px 10px;border-radius:16px;background:var(--panel);cursor:pointer;text-align:left}
.tgsty .tgmus{background:rgba(255,255,255,.18);color:#fff}
.tgmus .pb{width:32px;height:32px;border-radius:50%;display:grid;place-items:center;background:var(--a1);color:#fff;flex:none}
.tgsty .tgmus .pb{background:#fff;color:#000}
.tgmus .pb svg{width:16px;height:16px}
.tgmus .tx{flex:1;min-width:0}.tgmus .tx b{display:block;font-size:15px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.tgmus .tx span{font-size:13px;opacity:.75}
.tgmus .wv{display:flex;gap:2px;align-items:center;height:18px}.tgmus .wv i{width:3px;height:5px;border-radius:2px;background:currentColor;opacity:.8}
.tgmus.on .wv i{animation:tgwv .45s ease-in-out infinite alternate}.tgmus.on .wv i:nth-child(2){animation-delay:.1s}.tgmus.on .wv i:nth-child(3){animation-delay:.2s}.tgmus.on .wv i:nth-child(4){animation-delay:.3s}
@keyframes tgwv{to{height:16px}}
.tgposts{display:grid;grid-template-columns:repeat(3,1fr);gap:2px;border-radius:14px;overflow:hidden}
.tgposts .t{position:relative;aspect-ratio:9/16;background:#000;cursor:pointer;overflow:hidden}
.tgposts .t img,.tgposts .t video{width:100%;height:100%;object-fit:cover;display:block}
.tgposts .t span{position:absolute;left:6px;bottom:5px;font-size:11px;font-weight:800;color:#fff;text-shadow:0 1px 3px rgba(0,0,0,.6);display:flex;gap:3px;align-items:center}
.tgposts .t span svg{width:12px;height:12px}
.tgposts .t .pn{position:absolute;right:5px;top:5px;width:20px;height:20px;border-radius:50%;background:rgba(0,0,0,.45);display:grid;place-items:center;color:#fff}
.tgposts .t .pn svg{width:11px;height:11px}
.tgempty{color:var(--muted);text-align:center;padding:22px 10px}
#tgst{position:fixed;inset:0;z-index:99500;background:#000;color:#fff;display:flex;flex-direction:column;padding:max(8px,env(safe-area-inset-top)) 10px max(8px,env(safe-area-inset-bottom));animation:tgin .22s ease}
@keyframes tgin{from{opacity:0;transform:translateY(16px)}}
#tgst .pv{flex:1;min-height:0;border-radius:22px;overflow:hidden;background:#141414;position:relative;display:grid;place-items:center}
#tgst .pv img,#tgst .pv video{max-width:100%;max-height:100%;object-fit:contain}
#tgst .rb{width:42px;height:42px;border-radius:50%;display:grid;place-items:center;background:rgba(255,255,255,.12);color:#fff}
#tgst .pv .rb{position:absolute;top:10px;background:rgba(0,0,0,.4)}
#tgst .cap{margin-top:10px;border-radius:24px;background:rgba(255,255,255,.12);padding:12px 16px}
#tgst .cap textarea{width:100%;background:none;border:0;outline:0;color:#fff;font-size:16px;resize:none;max-height:96px}
#tgst .bt{display:flex;align-items:center;margin-top:10px}
#tgst .nx{margin-left:auto;display:flex;align-items:center;gap:4px;background:#2f8cff;color:#fff;font-weight:800;border-radius:22px;padding:12px 20px}
#tgst .nx svg{width:18px;height:18px}
#tgsh{position:fixed;inset:0;z-index:99600;background:#121217;color:#fff;overflow:auto;animation:tgup .28s cubic-bezier(.2,.9,.3,1)}
@keyframes tgup{from{transform:translateY(100%)}}
#tgsh .w{max-width:560px;margin:0 auto;padding:max(10px,env(safe-area-inset-top)) 16px 120px}
#tgsh .hd{position:relative;height:50px;display:flex;align-items:center;justify-content:center;font-weight:800;font-size:17px}
#tgsh .hd button{position:absolute;left:0;width:34px;height:34px;border-radius:50%;background:rgba(255,255,255,.12);display:grid;place-items:center;color:#fff}
#tgsh .hd button svg{width:18px;height:18px}
#tgsh .cd{background:#212128;border-radius:14px;overflow:hidden}
#tgsh .me{display:flex;align-items:center;gap:12px;padding:12px}
#tgsh .me small{display:block;color:rgba(255,255,255,.55);font-size:13px}
#tgsh .lb{color:rgba(255,255,255,.55);font-size:12.5px;margin:18px 14px 6px}
#tgsh .hn{color:rgba(255,255,255,.55);font-size:12.5px;margin:6px 14px 0}
#tgsh .ar{display:flex;align-items:center;gap:12px;padding:9px 12px;cursor:pointer;border-bottom:1px solid rgba(255,255,255,.08)}
#tgsh .ar:last-child{border-bottom:0}
#tgsh .ar .rd svg{width:24px;height:24px;color:rgba(255,255,255,.3)}
#tgsh .ar.on .rd svg{color:#2f8cff}
#tgsh .ar .ico{width:38px;height:38px;border-radius:50%;display:grid;place-items:center;color:#fff;flex:none}
#tgsh .ar .ico svg{width:20px;height:20px}
#tgsh .ar b{display:block;font-weight:600;font-size:16px}
#tgsh .ar a{color:#2f8cff;font-size:13px;cursor:pointer}
#tgsh .tr{display:flex;align-items:center;justify-content:space-between;padding:0 14px;height:50px;border-bottom:1px solid rgba(255,255,255,.08);cursor:pointer}
#tgsh .tr:last-child{border-bottom:0}
#tgsh .sw{width:50px;height:30px;border-radius:15px;background:rgba(255,255,255,.2);position:relative;transition:background .2s}
#tgsh .sw:after{content:'';position:absolute;left:2px;top:2px;width:26px;height:26px;border-radius:50%;background:#fff;transition:transform .2s}
#tgsh .sw.on{background:#34c759}#tgsh .sw.on:after{transform:translateX(20px)}
#tgsh .hr{display:flex;gap:4px}#tgsh .hr button{padding:5px 9px;border-radius:10px;color:#2f8cff;font-weight:700;font-size:13.5px}#tgsh .hr button.on{background:#2f8cff;color:#fff}
#tgsh .ft{position:fixed;left:0;right:0;bottom:0;padding:12px 16px max(12px,env(safe-area-inset-bottom));background:rgba(18,18,23,.96)}
#tgsh .ft button{display:block;width:100%;max-width:528px;margin:0 auto;height:52px;border-radius:26px;background:#2f8cff;color:#fff;font-weight:700;font-size:17px}
#tgsh .ft button.dis{opacity:.5}
#tgsh .ft button.loading{opacity:.7;pointer-events:none}
.tgpick .row{cursor:pointer}.tgpick .row .ck{margin-left:auto;width:22px;height:22px;border-radius:50%;border:2px solid var(--muted)}.tgpick .row.on .ck{background:var(--a1);border-color:var(--a1)}
.tgemo{display:inline-flex;vertical-align:middle;margin-left:6px;cursor:pointer}
#stv .stmedia{-webkit-user-select:none;user-select:none;-webkit-touch-callout:none}
.tgsw{display:flex;flex-wrap:wrap;gap:10px;margin:6px 0 12px}.tgsw b{width:40px;height:40px;border-radius:50%;cursor:pointer;display:grid;place-items:center;border:3px solid transparent}.tgsw b.on{border-color:var(--text)}
.tgpg{display:grid;grid-template-columns:repeat(6,1fr);gap:8px}.tgpg b{aspect-ratio:1;border-radius:12px;background:var(--panel2);display:grid;place-items:center;cursor:pointer;border:2px solid transparent}.tgpg b.on{border-color:var(--a1)}.tgpg b svg{width:22px;height:22px;fill:currentColor}
.tgprev{height:200px;border-radius:20px;position:relative;overflow:hidden;display:flex;flex-direction:column;align-items:center;justify-content:center;background:var(--panel2);margin-bottom:12px}
`; document.head.appendChild(tst);

/* ---------- узор и цвет шапки ---------- */
const DOTS=(()=>{ const o=[]; const cn=[7,11,15], rr=[92,140,190], sz=[22,19,16]; for(let r=0;r<3;r++) for(let k=0;k<cn[r];k++){ const a=k/cn[r]*Math.PI*2+r*.35; o.push([Math.cos(a)*rr[r],Math.sin(a)*rr[r]*.82,sz[r],.42-r*.1]); } return o; })();
function bgHtml(bg,pat,status){
  const c=TGC[bg]; let h='';
  if(c) h+=`<div style="position:absolute;inset:0;background:linear-gradient(180deg,${c[0]},${c[1]})"></div><div class="tgglow" data-c></div>`;
  if(pat){ const useS=pat==='@status'&&status; const svg=PSVG[pat==='@status'?'star.fill':pat]||PSVG['star.fill'];
    h+=`<div class="tgpat" data-c>${DOTS.map(d=>`<i style="left:${d[0]-d[2]/2}px;top:${d[1]-d[2]/2}px;width:${d[2]}px;height:${d[2]}px;opacity:${(useS?.9:(c?.8:.6))*d[3]};color:${c?'#fff':'var(--a1)'}">${useS?emoHtml(status):`<svg viewBox="0 0 24 24">${svg}</svg>`}</i>`).join('')}</div>`; }
  return h; }
function place(host,av){ requestAnimationFrame(()=>{ const hb=host.getBoundingClientRect(), ab=(av||host).getBoundingClientRect(); const x=ab.left-hb.left+ab.width/2+40, y=ab.top-hb.top+ab.height/2+220;
  host.querySelectorAll('[data-c]').forEach(e=>{ e.style.left=x+'px'; e.style.top=y+'px'; if(e.classList.contains('tgpat')) e.style.transformOrigin='0 0'; }); }); }
const AU={a:null,u:null};
function musHtml(p){ if(!p||!p.profile_music||!p.profile_music.url) return ''; const m=p.profile_music;
  return `<div class="tgmus ${AU.u===m.url?'on':''}" data-mu="${esc(m.url)}"><span class="pb">${ic(AU.u===m.url?'pause':'play','f')}</span><span class="tx"><b>${esc(m.title||'Без названия')}</b>${m.artist?`<span>${esc(m.artist)}</span>`:''}</span><span class="wv"><i></i><i></i><i></i><i></i></span>${ic('tnote')}</div>`; }
document.addEventListener('click',e=>{ const t=e.target.closest&&e.target.closest('[data-mu]'); if(!t) return; e.stopPropagation(); const u=t.dataset.mu;
  const sync=()=>document.querySelectorAll('[data-mu]').forEach(x=>{ const on=AU.u===x.dataset.mu; x.classList.toggle('on',on); x.querySelector('.pb').innerHTML=ic(on?'pause':'play','f'); });
  if(AU.u===u){ AU.a&&AU.a.pause(); AU.u=null; sync(); return; }
  if(AU.a) AU.a.pause(); AU.a=new Audio(pxu(u)); AU.u=u; AU.a.onended=()=>{ AU.u=null; sync(); }; AU.a.play().catch(()=>{ AU.u=null; sync(); }); sync(); },true);
window.tgDecor=(host,p,mine)=>{ if(!host||!p) return; host.querySelector(':scope>.tgbg')?.remove(); host.querySelector(':scope>.tgmus')?.remove();
  const bg=(p.profile_bg===null||p.profile_bg===undefined)?null:+p.profile_bg; const pat=p.profile_pattern||null;
  host.classList.toggle('tgsty',bg!==null);
  if(bg!==null||pat){ const d=document.createElement('div'); d.className='tgbg'; if(bg===null){ d.style.cssText='position:absolute;left:-40px;right:-40px;top:-220px;bottom:0;z-index:-1;overflow:hidden'; host.style.position='relative'; host.style.isolation='isolate'; }
    d.innerHTML=bgHtml(bg,pat,p.premium?p.emoji_status:null); host.prepend(d); place(host,host.querySelector('.av,.ibig,.avatar,img')); }
  const mh=musHtml(p); if(mh) host.insertAdjacentHTML('beforeend',mh); };

/* ---------- публикации в профиле ---------- */
function postView(s,mine,onCh){ const u=pxu(s.media_url); let pinned=s.pinned!==false;
  const close=modal(s.caption?esc(s.caption):'Публикация',`<div style="text-align:center">${s.kind==='video'?`<video src="${esc(u)}" controls playsinline autoplay style="max-width:100%;max-height:68vh;border-radius:16px"></video>`:`<img src="${esc(u)}" style="max-width:100%;max-height:68vh;border-radius:16px">`}</div>`,
    mine?[['Удалить','danger',c=>confirmBox('Удалить эту историю навсегда?','Удалить',async()=>{ c(); await sb.rpc('lm_story_delete',{p_id:s.id}); loadStories(); onCh&&onCh(); })],[pinned?'Убрать из профиля':'В профиль','ghost',async c=>{ c(); await sb.rpc('lm_story_set_pinned',{p_id:s.id,p_on:!pinned}); toast(pinned?'Убрано из профиля':'Опубликовано в профиле'); onCh&&onCh(); }],['Закрыть','primary']]:[['Закрыть','primary']]); }
function gridHtml(L,showPin){ return `<div class="tgposts">${L.map((s,i)=>{ const th=s.kind==='video'?(s.meta&&s.meta.thumb):s.media_url;
  return `<div class="t" data-pi="${i}">${th?`<img src="${esc(pxu(th))}" loading="lazy" alt="">`:`<video src="${esc(pxu(s.media_url))}#t=0.1" preload="metadata" playsinline muted></video>`}<span>${s.kind==='video'?ic('play','f'):''}${s.views?ic('eye')+s.views:''}</span>${showPin&&s.pinned?`<b class="pn">${ic('pin')}</b>`:''}</div>`; }).join('')}</div>`; }
window.tgPosts=async(box,uid)=>{ if(!box) return; box.innerHTML='<div class="tgempty">Загрузка…</div>';
  const {data}=await sb.rpc('lm_profile_posts',{p_user:uid}); const L=data||[]; const mine=uid===S.me.id;
  box.innerHTML=L.length?gridHtml(L,false):`<div class="tgempty">${mine?'Опубликуйте историю в профиле — она останется здесь':'Пока нет публикаций'}</div>`;
  box.querySelectorAll('[data-pi]').forEach(el=>el.onclick=()=>postView(L[+el.dataset.pi],mine,()=>window.tgPosts(box,uid))); };
async function archiveBox(postsOnly){ const close=modal(postsOnly?'Опубликованные истории':'Архив историй','<div id="tgArc"><div class="tgempty">Загрузка…</div></div>',[['Закрыть','ghost']]);
  const load=async()=>{ const box=document.getElementById('tgArc'); if(!box) return; const {data}=postsOnly?await sb.rpc('lm_profile_posts',{p_user:S.me.id}):await sb.rpc('lm_story_archive'); const L=data||[];
    box.innerHTML=L.length?gridHtml(L,!postsOnly):`<div class="tgempty">${postsOnly?'Нет опубликованных историй':'Архив пуст. Здесь хранятся все ваши истории, их видите только вы.'}</div>`;
    box.querySelectorAll('[data-pi]').forEach(el=>el.onclick=()=>postView(L[+el.dataset.pi],true,load)); }; load(); }

/* ---------- выбор людей ---------- */
async function pickPeople(title,initial,done){ const sel=new Set(initial||[]); const ids=(S.contacts||[]).slice(); if(ids.length) await profGet(ids).catch(()=>{});
  const row=id=>{ const p=S.profiles.get(id)||{}; return `<div class="row ${sel.has(id)?'on':''}" data-pp="${id}">${avatar({name:p.name,avatar:p.avatar_url,color:p.color},'s')}<div class="mid"><div class="t1"><span class="nm">${esc(p.name||'')}</span></div></div><span class="ck"></span></div>`; };
  modal(esc(title),`<div class="tgpick" style="max-height:56vh;overflow:auto">${ids.length?ids.map(row).join(''):'<div class="tgempty">В контактах пока никого</div>'}</div>`,[['Отмена','ghost'],['Готово','primary',c=>{ c(); done(sel); }]]);
  const ov=[...document.querySelectorAll('.ov')].pop(); ov&&ov.querySelectorAll('[data-pp]').forEach(r=>r.onclick=()=>{ const id=r.dataset.pp; sel.has(id)?sel.delete(id):sel.add(id); r.classList.toggle('on',sel.has(id)); }); }

/* ---------- новая история: предпросмотр → «Поделиться историей» ---------- */
function videoThumb(blob){ return new Promise(r=>{ const v=document.createElement('video'); v.muted=true; v.playsInline=true; v.preload='auto'; v.src=URL.createObjectURL(blob);
  v.onloadeddata=()=>{ v.currentTime=Math.min(.1,v.duration||0); }; v.onseeked=()=>{ try{ const k=540/Math.max(v.videoWidth,1); const cv=document.createElement('canvas'); cv.width=Math.round(v.videoWidth*Math.min(1,k)); cv.height=Math.round(v.videoHeight*Math.min(1,k)); cv.getContext('2d').drawImage(v,0,0,cv.width,cv.height); cv.toBlob(b=>{ URL.revokeObjectURL(v.src); r(b); },'image/jpeg',.72); }catch(e){ r(null); } }; v.onerror=()=>r(null); setTimeout(()=>r(null),6000); }); }
function tgAddStory(){ const inp=document.createElement('input'); inp.type='file'; inp.accept='image/*,video/*'; inp.style.cssText='position:fixed;left:-9999px;opacity:0';
  document.body.appendChild(inp); inp.onchange=async()=>{ const f=inp.files&&inp.files[0]; inp.remove(); if(!f) return;
    const isV=/^video\//.test(f.type); if(!isV&&!/^image\//.test(f.type)) return toast('Можно выбрать фото или видео');
    if(isV&&f.size>60*1024*1024) return toast('Видео слишком большое (до 60 МБ)');
    let meta={}; if(isV){ meta=await new Promise(r=>{ const v=document.createElement('video'); v.preload='metadata'; v.onloadedmetadata=()=>{ r({dur:v.duration,w:v.videoWidth,h:v.videoHeight}); URL.revokeObjectURL(v.src); }; v.onerror=()=>r({}); v.src=URL.createObjectURL(f); });
      if(meta.dur>61) return toast('Видео для истории — не длиннее 60 секунд'); }
    const blob=isV?f:await compressImage(f); const prev=URL.createObjectURL(blob);
    const st={choice:'all',excl:new Set(),sel:new Set(),pinned:true,shots:true,hours:24,cap:''};
    const ed=document.createElement('div'); ed.id='tgst';
    ed.innerHTML=`<div class="pv">${isV?`<video src="${prev}" playsinline autoplay loop></video>`:`<img src="${prev}" alt="">`}<button class="rb" data-k="x" style="right:10px">${ic('x')}</button></div>
<div class="cap"><textarea rows="1" maxlength="300" placeholder="Добавить подпись…"></textarea></div><div class="bt"><button class="rb" data-k="x">${ic('back')}</button><button class="nx" data-k="n">ДАЛЕЕ${ic('tchev')}</button></div>`;
    document.body.appendChild(ed); const ta=ed.querySelector('textarea'); ta.oninput=()=>{ ta.style.height='auto'; ta.style.height=Math.min(96,ta.scrollHeight)+'px'; };
    const shut=()=>{ ed.remove(); URL.revokeObjectURL(prev); document.getElementById('tgsh')?.remove(); };
    ed.querySelectorAll('[data-k=x]').forEach(b=>b.onclick=shut);
    ed.querySelector('[data-k=n]').onclick=()=>{ st.cap=ta.value; ed.querySelector('video')?.pause(); share(); };
    const share=async()=>{ let close=new Set(); sb.rpc('lm_close_friends_get').then(({data})=>{ close=new Set((data||[]).map(x=>typeof x==='string'?x:x.lm_close_friends_get)); draw(); });
      const sh=document.createElement('div'); sh.id='tgsh'; document.body.appendChild(sh);
      const ar=(k,icon,col,t,sub,act)=>`<div class="ar ${st.choice===k?'on':''}" data-a="${k}"><span class="rd">${ic(st.choice===k?'tok':'tcirc')}</span><span class="ico" style="background:${col}">${ic(icon)}</span><span><b>${t}</b><a data-s="${act}">${sub} ›</a></span></div>`;
      const draw=()=>{ const me=S.me; const ok=!(st.choice==='only'&&!st.sel.size);
        sh.innerHTML=`<div class="w"><div class="hd"><button data-k="b">${ic('x')}</button>Поделиться историей</div>
<div class="cd me">${avatar({name:me.name,avatar:me.avatar_url,color:me.color},'s')}<div><b>${esc(me.name)}</b>${pMark(me)}<small>личный аккаунт</small></div></div>
<div class="lb">КТО ВИДИТ ЭТУ ИСТОРИЮ</div><div class="cd">
${ar('all','megaphone','#2f8cff','Все',st.choice==='all'&&st.excl.size?'кроме '+st.excl.size+' чел.':'добавить исключения','excl')}
${ar('contacts','user','#9b5cff','Мои контакты',st.choice==='contacts'&&st.excl.size?'кроме '+st.excl.size+' чел.':'добавить исключения','excl')}
${ar('close','star','#34c759','Близкие друзья',close.size?close.size+' чел. · изменить':'выбрать','close')}
${ar('only','users','#ff9500','Выбранные пользователи',st.sel.size?st.sel.size+' чел. · изменить':'выбрать','only')}</div>
<div class="hn">Выберите пользователей, которые не будут видеть Вашу историю.</div>
<div class="cd" style="margin-top:14px"><div class="tr" data-t="shots">Разрешить снимки экрана<span class="sw ${st.shots?'on':''}"></span></div><div class="tr" data-t="pinned">Опубликовать в моём профиле<span class="sw ${st.pinned?'on':''}"></span></div></div>
<div class="hn">История в профиле останется после 24 часов. Её смогут увидеть только те, кого Вы выбрали выше.</div>
<div class="cd" style="margin-top:14px"><div class="tr" style="cursor:default">Срок<span class="hr">${[[24,'24 ч'],[48,'48 ч'],[72,'3 дня'],[168,'7 дней']].map(h=>`<button data-h="${h[0]}" class="${st.hours===h[0]?'on':''}">${h[1]}</button>`).join('')}</span></div></div></div>
<div class="ft"><button data-k="p" class="${ok?'':'dis'}">Опубликовать историю</button></div>`;
        sh.querySelector('[data-k=b]').onclick=()=>{ sh.remove(); ed.querySelector('video')?.play().catch(()=>{}); };
        sh.querySelectorAll('[data-a]').forEach(r=>r.onclick=e=>{ if(e.target.closest('[data-s]')) return; st.choice=r.dataset.a; if(st.choice==='only'&&!st.sel.size) return pick('only'); if(st.choice==='close'&&!close.size) return pick('close'); draw(); });
        sh.querySelectorAll('[data-s]').forEach(a=>a.onclick=e=>{ e.stopPropagation(); pick(a.dataset.s); });
        sh.querySelectorAll('[data-t]').forEach(r=>r.onclick=()=>{ st[r.dataset.t]=!st[r.dataset.t]; draw(); });
        sh.querySelectorAll('[data-h]').forEach(b=>b.onclick=()=>{ const h=+b.dataset.h; if(h>24&&!premOk()) return; st.hours=h; draw(); });
        sh.querySelector('[data-k=p]').onclick=publish; };
      const pick=k=>{ if(k==='excl') pickPeople('Скрыть от',st.excl,s=>{ st.excl=s; draw(); });
        else if(k==='only') pickPeople('Кто увидит',st.sel,s=>{ st.sel=s; st.choice='only'; draw(); });
        else pickPeople('Близкие друзья',close,async s=>{ close=s; await sb.rpc('lm_close_friends_set',{p_ids:[...s]}); draw(); }); };
      const publish=async()=>{ if(st.choice==='only'&&!st.sel.size) return; const b=sh.querySelector('[data-k=p]'); b.classList.add('loading'); b.textContent='Публикуем…';
        try{ const url=await upload(blob,isV?extOf(f,'mp4'):'jpg'); const m=Object.assign({},meta); if(!st.shots) m.noshot=true;
          if(isV){ const tb=await videoThumb(blob); if(tb){ try{ m.thumb=await upload(tb,'jpg'); }catch(e){} } }
          let aud='all', allow=[]; if(st.choice==='contacts'){ aud='contacts'; allow=[...st.excl]; } else if(st.choice==='close') aud='close'; else if(st.choice==='only'){ aud='only'; allow=[...st.sel]; } else if(st.excl.size){ aud='except'; allow=[...st.excl]; }
          const {error}=await sb.rpc('lm_story_add3',{p_kind:isV?'video':'image',p_url:url,p_caption:st.cap,p_meta:m,p_hours:st.hours,p_aud:aud,p_allow:allow,p_pinned:st.pinned}); if(error) throw error;
          shut(); toast('История опубликована'); loadStories(); refreshMe(); }
        catch(err){ b.classList.remove('loading'); b.textContent='Опубликовать историю'; toast('Ошибка: '+(err.message||err)); } };
      draw(); };
  }; inp.click(); }
addStory=tgAddStory;

/* ---------- оформление и музыка профиля (настройки) ---------- */
function styleBox(){ const me=S.me; let bg=me.profile_bg??null, pat=me.profile_pattern||null;
  const opts=[null,...(me.emoji_status?['@status']:[]),...Object.keys(PSVG)];
  const close=modal('Оформление профиля',`<div class="tgprev" id="tgPv"></div><div class="k" style="color:var(--muted);font-size:12.5px">ЦВЕТ</div><div class="tgsw" id="tgSw"></div><div class="k" style="color:var(--muted);font-size:12.5px;margin-bottom:6px">УЗОР · PREMIUM</div><div class="tgpg" id="tgPg"></div>`,
    [['Отмена','ghost'],['Сохранить','primary',async c=>{ const {error}=await sb.rpc('lm_set_profile_style',{p_bg:bg,p_pattern:pat}); if(error) return toast(error.message); c(); await refreshMe(); renderSettings(); toast('Оформление сохранено'); }]]);
  const draw=()=>{ const pv=document.getElementById('tgPv'); if(!pv) return;
    pv.innerHTML=`${avatar({name:me.name,avatar:me.avatar_url,color:me.color},'l')}<b style="margin-top:8px;font-size:19px">${esc(me.name)}</b>`; window.tgDecor(pv,Object.assign({},me,{profile_bg:bg,profile_pattern:pat,profile_music:null}),true);
    pv.querySelector('.tgbg')&&(pv.querySelector('.tgbg').style.cssText='position:absolute;inset:0;z-index:-1;overflow:hidden');
    place(pv,pv.querySelector('.av,.avatar,img')); pv.querySelectorAll('[data-c]').forEach(e=>{ requestAnimationFrame(()=>{ const a=pv.querySelector('.av,.avatar,img'); if(!a) return; const hb=pv.getBoundingClientRect(), ab=a.getBoundingClientRect(); e.style.left=(ab.left-hb.left+ab.width/2)+'px'; e.style.top=(ab.top-hb.top+ab.height/2)+'px'; }); });
    document.getElementById('tgSw').innerHTML=`<b data-bg="" class="${bg===null?'on':''}" style="background:var(--panel2)">${ic('x')}</b>`+TGC.map((c,i)=>`<b data-bg="${i}" class="${bg===i?'on':''}" style="background:linear-gradient(180deg,${c[0]},${c[1]})"></b>`).join('');
    document.getElementById('tgPg').innerHTML=opts.map(o=>`<b data-pt="${o||''}" class="${pat===o?'on':''}">${o===null?ic('x'):o==='@status'?emoHtml(me.emoji_status):`<svg viewBox="0 0 24 24">${PSVG[o]}</svg>`}</b>`).join('');
    document.querySelectorAll('#tgSw [data-bg]').forEach(b=>b.onclick=()=>{ bg=b.dataset.bg===''?null:+b.dataset.bg; draw(); });
    document.querySelectorAll('#tgPg [data-pt]').forEach(b=>b.onclick=()=>{ const v=b.dataset.pt||null; if(v&&!premOk()) return; pat=v; draw(); }); };
  draw(); }
function musicBox(){ const me=S.me; const m=me.profile_music;
  const close=modal('Музыка профиля',`<p style="margin:0 0 10px;color:var(--muted)">Трек будет играть у тех, кто откроет ваш профиль, по нажатию.</p>${m&&m.url?musHtml(me):'<div class="tgempty">Трек не выбран</div>'}`,
    [...(m&&m.url?[['Убрать','danger',async c=>{ await sb.rpc('lm_set_profile_music',{p:null}); c(); await refreshMe(); renderSettings(); }]]:[]),['Выбрать файл','primary',c=>{
      const inp=document.createElement('input'); inp.type='file'; inp.accept='audio/*'; inp.style.cssText='position:fixed;left:-9999px;opacity:0'; document.body.appendChild(inp);
      inp.onchange=async()=>{ const f=inp.files&&inp.files[0]; inp.remove(); if(!f) return; if(f.size>15*1024*1024) return toast('Файл больше 15 МБ'); c(); toast('Загружаем трек…');
        try{ const ext=(extOf(f,'mp3')||'mp3').replace(/[^a-z0-9]/g,''); const url=await upload(f,['mp3','m4a','wav','ogg'].includes(ext)?ext:'mp3');
          const title=(f.name||'').replace(/\.[^.]+$/,''); const {error}=await sb.rpc('lm_set_profile_music',{p:{url,title,artist:''}}); if(error) throw error; await refreshMe(); renderSettings(); toast('Музыка профиля установлена'); }
        catch(err){ toast('Ошибка: '+(err.message||err)); } }; inp.click(); }]]); }
const prevRows=window.lfRows;
window.lfRows=()=>(prevRows?prevRows():'')+srow('tgSStyle','palette','#ff6fae','Оформление профиля',S.me&&(S.me.profile_bg!=null||S.me.profile_pattern)?'Своё':'Стандартное')
  +srow('tgSMus','music','#ff2d55','Музыка профиля',S.me&&S.me.profile_music&&S.me.profile_music.url?esc(S.me.profile_music.title||'Выбрана'):'Не выбрана')
  +srow('tgSPosts','tgrid','#2f8cff','Опубликованные истории','Истории, закреплённые в профиле')
  +srow('tgSArc','tarch','#8e8e93','Архив историй','Все ваши истории, видите только вы');
document.addEventListener('click',e=>{ const t=e.target.closest&&e.target.closest('#tgSStyle,#tgSMus,#tgSPosts,#tgSArc'); if(!t) return; e.stopPropagation();
  if(t.id==='tgSStyle') styleBox(); else if(t.id==='tgSMus') musicBox(); else archiveBox(t.id==='tgSPosts'); },true);

/* ---------- эмодзи-статус рядом с «Чаты» ---------- */
setInterval(()=>{ const t=document.getElementById('tabTitle'); if(!t||!S||!S.me) return; let sp=t.querySelector('.tgemo');
  const want=t.firstChild&&String(t.firstChild.textContent||'').trim()==='Чаты'&&S.me.premium;
  if(!want){ sp&&sp.remove(); return; }
  const h=S.me.emoji_status?emoHtml(S.me.emoji_status):ic('star','f');
  if(!sp){ sp=document.createElement('span'); sp.className='tgemo'; sp.onclick=e=>{ e.stopPropagation(); emojiStatusDlg(); }; t.appendChild(sp); }
  if(sp.__h!==h){ sp.__h=h; sp.innerHTML=h; } },1200);
document.addEventListener('contextmenu',e=>{ if(e.target.closest&&e.target.closest('#stv .stmedia')) e.preventDefault(); },true);
})();
