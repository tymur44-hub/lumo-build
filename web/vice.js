/* ===== временная тема Vice Nights (до 1 декабря): закат, неон, пальмы — поверх обычного оформления ===== */
(function(){
  const SKY="url(\"data:image/svg+xml;utf8,"+encodeURIComponent(`<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 390 230' preserveAspectRatio='xMidYMax slice'><defs><linearGradient id='s' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#2a0f52'/><stop offset='.38' stop-color='#8a2c8f'/><stop offset='.66' stop-color='#ff4f8b'/><stop offset='.86' stop-color='#ff9a3d'/><stop offset='1' stop-color='#ffd36b'/></linearGradient><linearGradient id='u' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ffe58a'/><stop offset='1' stop-color='#ff8a3d'/></linearGradient></defs><rect width='390' height='230' fill='url(#s)'/><circle cx='195' cy='195' r='55' fill='url(#u)'/><rect x='140' y='200' width='110' height='3' fill='#ff4f8b' opacity='.85'/><rect x='140' y='212' width='110' height='4' fill='#ff4f8b' opacity='.85'/><path fill='#1a0b33' d='M0 230 L0 194 L28 194 L28 176 L46 176 L46 190 L68 190 L68 152 L84 152 L84 190 L118 190 L118 182 L140 182 L140 202 L242 202 L242 160 L256 160 L256 138 L268 138 L268 160 L284 160 L284 186 L322 186 L322 170 L346 170 L346 192 L390 192 L390 230 Z'/><g stroke='#120826' fill='none' stroke-linecap='round'><path stroke-width='5' d='M40 230 C42 196 44 150 52 112'/><path stroke-width='4.5' d='M52 112 C38 104 22 108 10 118 M52 112 C64 100 84 100 96 108 M52 112 C46 96 34 88 22 88 M52 112 C66 112 80 122 86 134 M52 112 C40 118 30 130 28 144'/><path stroke-width='5' d='M342 230 C340 200 336 168 328 134'/><path stroke-width='4.5' d='M328 134 C316 124 300 126 290 136 M328 134 C340 120 358 120 370 128 M328 134 C322 118 310 110 298 110 M328 134 C342 136 352 146 358 158'/></g></svg>`)+"\")";
  const NIGHT="url(\"data:image/svg+xml;utf8,"+encodeURIComponent(`<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 800 800' preserveAspectRatio='xMidYMid slice'><g stroke='#2fd6d0' stroke-opacity='.18'><path d='M0 500H800M0 520H800M0 550H800M0 590H800M0 640H800M0 700H800M0 770H800'/></g><g stroke='#ff4f8b' stroke-opacity='.16'><path d='M400 500V800M370 500L190 800M340 500L-20 800M430 500L610 800M460 500L820 800M310 500L-230 800M490 500L1030 800'/></g><g stroke='#ff9a3d' stroke-opacity='.18' fill='none' stroke-linecap='round'><path stroke-width='7' d='M640 500C640 420 634 340 620 250'/><path stroke-width='6' d='M620 250C600 236 572 240 556 258M620 250C640 228 672 228 692 242M620 250C610 222 590 210 570 212M620 250C646 254 662 274 668 296M620 250C602 262 588 284 586 306'/></g></svg>`)+"\")";
  const st=document.createElement('style'); st.id='vicecss'; st.textContent=`
@import url('https://fonts.googleapis.com/css2?family=Anton&display=swap');
body.vice{--out:linear-gradient(135deg,#ff4f8b,#ff8a3d)}
body.vice #side::before{content:'';position:absolute;left:0;right:0;top:0;height:230px;background:${SKY} center bottom/cover no-repeat;pointer-events:none;z-index:-1;
  -webkit-mask-image:linear-gradient(#000 62%,transparent);mask-image:linear-gradient(#000 62%,transparent);animation:viceIn .6s ease both}
@keyframes viceIn{from{opacity:0}to{opacity:1}}
body.vice #chat{background:var(--wall, ${NIGHT} center/cover no-repeat, linear-gradient(180deg,#1a0b3a,#2b0f4f 45%,#4a1559 72%,#6b1d55))}
body.vice .day span{background:#ffd36b!important;color:#140a2e!important;font-family:Anton,Impact,sans-serif;font-weight:400;letter-spacing:.8px;text-transform:uppercase;border:0!important;
  border-radius:7px;box-shadow:3px 3px 0 #0c0620;display:inline-block;transform:rotate(-2deg);-webkit-backdrop-filter:none;backdrop-filter:none}
body.vice .vtitle{font-family:Anton,Impact,sans-serif!important;font-weight:400!important;letter-spacing:.5px;text-transform:uppercase;color:#fff!important;text-shadow:0 2px 0 #2a0f52,0 0 16px rgba(255,79,139,.75)}
.vicesw{display:flex;align-items:center;gap:12px;padding:12px 14px;border-radius:16px;background:var(--panel2);margin:10px 0}
.vicesw .ic{width:32px;height:32px;border-radius:9px;background:linear-gradient(135deg,#ff4f8b,#ff8a3d);display:flex;align-items:center;justify-content:center;flex:none}
.vicesw b{display:block;font-size:15px}.vicesw span{display:block;font-size:12.5px;color:var(--muted)}.vicesw .t{flex:1}
.vicesw input{width:44px;height:26px;accent-color:#ff4f8b}`;
  document.head.appendChild(st);
  let avail=false;
  const apply=()=>{ let off=false; try{ off=localStorage.getItem('vice_off')==='1'; }catch{} document.body.classList.toggle('vice',avail&&!off);
    // заголовок списка чатов — неоновый капслок
    document.querySelectorAll('#side h1, #side .ttl, #side .title').forEach(e=>{ if(/^\s*Чаты\s*$/i.test(e.textContent)) e.classList.add('vtitle'); }); };
  const check=async()=>{ try{ const {data}=await sb.rpc('lm_get_config'); const e=data&&data.look&&data.look.event; avail=!!(e&&e.id==='vice'&&(!e.until||new Date(e.until)>new Date())); }catch{} apply(); };
  window.viceToggle=on=>{ try{ localStorage.setItem('vice_off',on?'0':'1'); }catch{} apply(); };
  window.viceAvail=()=>avail;
  setTimeout(check,1200); setInterval(check,30*60*1000);
  // переключатель в «Оформлении»
  new MutationObserver(()=>{ if(!avail) return; const pg=document.querySelector('.spage'); if(!pg||pg.querySelector('.vicesw')) return;
    if(!/Оформление/.test((pg.querySelector('h2,h3,.sh,.stitle')||{}).textContent||'')) return;
    let off=false; try{ off=localStorage.getItem('vice_off')==='1'; }catch{}
    const d=document.createElement('label'); d.className='vicesw';
    d.innerHTML=`<span class="ic"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.2" stroke-linecap="round"><path d="M3 18h18M6 18a6 6 0 0 1 12 0M12 6V3M5 9 3.5 7.5M19 9l1.5-1.5"/></svg></span><span class="t"><b>Vice Nights</b><span>Закат, неон и пальмы — до 1 декабря</span></span><input type="checkbox" ${off?'':'checked'}>`;
    d.querySelector('input').onchange=e=>viceToggle(e.target.checked);
    const at=pg.querySelector('h2,h3,.sh,.stitle'); (at&&at.parentNode===pg?at.nextSibling:pg.firstChild) ? pg.insertBefore(d, at&&at.parentNode===pg?at.nextSibling:pg.firstChild) : pg.appendChild(d);
    apply(); }).observe(document.body,{childList:true,subtree:true});
  new MutationObserver(()=>{ if(document.body.classList.contains('vice')) document.querySelectorAll('#side h1:not(.vtitle), #side .ttl:not(.vtitle), #side .title:not(.vtitle)').forEach(e=>{ if(/^\s*Чаты\s*$/i.test(e.textContent)) e.classList.add('vtitle'); }); }).observe(document.documentElement,{childList:true,subtree:true});
})();
