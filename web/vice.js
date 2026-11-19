/* ===== временная тема Vice Nights (до 1 декабря): закат, неон, пальмы — поверх обычного оформления (стекло и формы остаются) ===== */
(function(){
  const svgUrl=s=>"url(\"data:image/svg+xml;utf8,"+encodeURIComponent(s)+"\")";
  const SKY_SVG=`<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 390 260' preserveAspectRatio='xMidYMax slice'><defs><linearGradient id='s' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#2a0f52'/><stop offset='.35' stop-color='#6d2483'/><stop offset='.62' stop-color='#ff4f8b'/><stop offset='.84' stop-color='#ff9a3d'/><stop offset='1' stop-color='#ffd36b'/></linearGradient><linearGradient id='u' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#ffe58a'/><stop offset='1' stop-color='#ff8a3d'/></linearGradient><clipPath id='c'><circle cx='195' cy='238' r='62'/></clipPath></defs><rect width='390' height='260' fill='url(#s)'/><g fill='#fff'><circle cx='40' cy='30' r='1.2'/><circle cx='120' cy='18' r='1'/><circle cx='260' cy='26' r='1.3'/><circle cx='340' cy='44' r='1'/><circle cx='300' cy='12' r='.9'/><circle cx='70' cy='60' r='.9'/></g><g clip-path='url(#c)'><rect x='130' y='176' width='130' height='90' fill='url(#u)'/><g fill='#ff4f8b' opacity='.9'><rect x='130' y='222' width='130' height='3'/><rect x='130' y='232' width='130' height='4'/><rect x='130' y='243' width='130' height='5'/><rect x='130' y='254' width='130' height='6'/></g></g><path fill='#1a0b33' d='M0 260 L0 236 L26 236 L26 222 L44 222 L44 232 L62 232 L62 204 L78 204 L78 232 L110 232 L110 226 L128 226 L128 244 L262 244 L262 212 L274 212 L274 194 L284 194 L284 212 L298 212 L298 230 L330 230 L330 218 L350 218 L350 234 L390 234 L390 260 Z'/><g stroke='#120826' fill='none' stroke-linecap='round'><path stroke-width='5' d='M34 260 C36 230 40 190 48 156'/><path stroke-width='4.5' d='M48 156 C34 148 18 152 6 162 M48 156 C60 144 80 144 92 152 M48 156 C42 140 30 132 18 132 M48 156 C62 156 76 166 82 178 M48 156 C36 162 26 174 24 188'/><path stroke-width='5' d='M352 260 C350 234 346 206 338 176'/><path stroke-width='4.5' d='M338 176 C326 166 310 168 300 178 M338 176 C350 162 368 162 380 170 M338 176 C332 160 320 152 308 152 M338 176 C352 178 362 188 368 200'/></g></svg>`;
  const NIGHT_SVG=`<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 800 800' preserveAspectRatio='xMidYMid slice'><g stroke='#2fd6d0' stroke-opacity='.18'><path d='M0 500H800M0 520H800M0 550H800M0 590H800M0 640H800M0 700H800M0 770H800'/></g><g stroke='#ff4f8b' stroke-opacity='.16'><path d='M400 500V800M370 500L190 800M340 500L-20 800M430 500L610 800M460 500L820 800M310 500L-230 800M490 500L1030 800'/></g><g stroke='#ff9a3d' stroke-opacity='.18' fill='none' stroke-linecap='round'><path stroke-width='7' d='M640 500C640 420 634 340 620 250'/><path stroke-width='6' d='M620 250C600 236 572 240 556 258M620 250C640 228 672 228 692 242M620 250C610 222 590 210 570 212M620 250C646 254 662 274 668 296M620 250C602 262 588 284 586 306'/></g></svg>`;
  const PALM_SVG=`<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 300 300' preserveAspectRatio='xMidYMid slice'><rect width='300' height='300' fill='#0f0828'/><circle cx='210' cy='90' r='54' fill='#ff4f8b' opacity='.18'/><g stroke='#ff4f8b' fill='none' stroke-linecap='round' stroke-width='6'><path d='M150 300 C152 240 160 170 176 110'/><path d='M176 110 C150 92 120 98 98 116 M176 110 C198 86 236 86 262 102 M176 110 C166 80 142 66 120 68 M176 110 C204 112 228 132 238 156 M176 110 C152 122 136 146 132 172'/></g><g stroke='#2fd6d0' fill='none' stroke-linecap='round' stroke-width='5' opacity='.85'><path d='M70 300 C70 262 74 226 82 196'/><path d='M82 196 C66 186 46 190 32 202 M82 196 C96 182 118 182 134 192 M82 196 C88 212 92 228 90 246'/></g></svg>`;
  const SKY=svgUrl(SKY_SVG), NIGHT=svgUrl(NIGHT_SVG), PALM=svgUrl(PALM_SVG);
  const STAR='<svg viewBox="0 0 24 24"><path d="M12 2.5l2.9 6 6.6.9-4.8 4.6 1.2 6.5L12 17.4 6.1 20.5l1.2-6.5L2.5 9.4l6.6-.9z"/></svg>';
  const st=document.createElement('style'); st.id='vicecss'; st.setAttribute('data-lumo-own','1'); st.textContent=`
@import url('https://fonts.googleapis.com/css2?family=Anton&display=swap');
body.vice{--out:linear-gradient(135deg,#ff4f8b,#ff8a3d);--vglass:rgba(22,10,48,.34);--vline:rgba(255,255,255,.28)}
/* небо за шапкой */
body.vice #side::before{content:'';position:absolute;left:0;right:0;top:0;height:calc(272px + env(safe-area-inset-top));background:${SKY} center bottom/cover no-repeat;pointer-events:none;z-index:-1;
  -webkit-mask-image:linear-gradient(#000 66%,transparent);mask-image:linear-gradient(#000 66%,transparent);animation:viceSky 1s ease both}
@keyframes viceSky{from{opacity:0;transform:translateY(-14px)}to{opacity:1;transform:none}}
/* шапка: то же стекло, только тёмное поверх заката */
body.vice #tghead .mid b{font-family:Anton,Impact,sans-serif;font-weight:400;font-size:27px;letter-spacing:.6px;text-transform:uppercase;color:#fff;text-shadow:0 2px 0 #2a0f52,0 0 18px rgba(255,79,139,.8)}
body.vice #tghead .gb{background:var(--vglass);border-color:var(--vline);color:#fff;-webkit-backdrop-filter:blur(18px) saturate(1.6);backdrop-filter:blur(18px) saturate(1.6)}
body.vice #tghead .pair button{color:#fff}
body.vice #tghead .cmp{background:linear-gradient(135deg,#ff4f8b,#ff8a3d);box-shadow:0 0 0 2px #140a2e,3px 3px 0 2px #140a2e;transition:transform .15s}
body.vice #tghead .cmp:active{transform:translate(2px,2px);box-shadow:0 0 0 2px #140a2e,1px 1px 0 2px #140a2e}
body.vice #tghead .stk>*{background:transparent}
.vstars{display:none;gap:1px;margin-left:2px}
body.vice .vstars{display:inline-flex}
.vstars svg{width:13px;height:13px;fill:rgba(255,255,255,.28);stroke:#140a2e;stroke-width:1.5}
.vstars svg.on{fill:#ffd36b;filter:drop-shadow(0 0 4px rgba(255,211,107,.9));animation:vstar 1.4s ease-in-out infinite}
.vstars svg.on:nth-child(2){animation-delay:.12s}.vstars svg.on:nth-child(3){animation-delay:.24s}.vstars svg.on:nth-child(4){animation-delay:.36s}.vstars svg.on:nth-child(5){animation-delay:.48s}
@keyframes vstar{50%{transform:scale(1.18)}}
/* поиск */
body.vice #qbox .search{background:var(--vglass)!important;border:1px solid var(--vline)!important;box-shadow:none!important;-webkit-backdrop-filter:blur(18px) saturate(1.6);backdrop-filter:blur(18px) saturate(1.6)}
body.vice #q{background:transparent!important;color:#fff!important;border:0!important;box-shadow:none!important;outline:0}
body.vice #qbox .search svg,body.vice #qbox [data-i] svg{color:rgba(255,255,255,.85)}
body.vice #q::placeholder{color:rgba(255,255,255,.75)}
body.vice #qbox svg{color:#fff}
/* папки: стеклянная полоса, активная — жёлтая плашка */
body.vice #folders{background:var(--vglass);border:1px solid var(--vline);border-radius:20px;margin-left:10px;margin-right:10px;-webkit-backdrop-filter:blur(18px) saturate(1.6);backdrop-filter:blur(18px) saturate(1.6)}
body.vice #folders button{color:#fff!important;background:transparent!important;text-shadow:0 1px 2px rgba(0,0,0,.35);border-radius:10px;transition:transform .2s}
body.vice #folders button.on{background:#ffd36b!important;color:#140a2e!important;text-shadow:none;font-family:Anton,Impact,sans-serif;font-weight:400;letter-spacing:.6px;text-transform:uppercase;box-shadow:2px 2px 0 #140a2e;transform:rotate(-2deg)}
body.vice #folders .fc{background:#ff4f8b;color:#fff}
body.vice #folders .find{opacity:0}
/* список чатов */
body.vice .row .badge:not(.mute){background:linear-gradient(135deg,#ff4f8b,#ff8a3d);color:#fff;box-shadow:0 0 10px rgba(255,79,139,.55)}
body.vice .row.on{background:linear-gradient(90deg,rgba(255,79,139,.2),rgba(47,214,208,.08))}
/* нижняя панель */
body.vice #tabs{border-color:rgba(255,79,139,.45);box-shadow:0 8px 30px rgba(0,0,0,.25),0 0 22px rgba(255,79,139,.25)}
body.vice #tabs button.on{color:#ff4f8b;background:rgba(255,79,139,.14)}
body.vice #tabs button.on .ti svg{filter:drop-shadow(0 0 6px rgba(255,79,139,.75))}
/* переписка */
body.vice #chat{background:var(--wall, ${NIGHT} center/cover no-repeat, linear-gradient(180deg,#1a0b3a,#2b0f4f 45%,#4a1559 72%,#6b1d55))}
body.vice .day span{background:#ffd36b!important;color:#140a2e!important;font-family:Anton,Impact,sans-serif;font-weight:400;letter-spacing:.8px;text-transform:uppercase;border:0!important;
  border-radius:7px;box-shadow:3px 3px 0 #0c0620;display:inline-block;transform:rotate(-2deg);-webkit-backdrop-filter:none;backdrop-filter:none}
body.vice .m.me .b{box-shadow:0 2px 12px rgba(255,79,139,.28)}
body.vice #composer .cbox{box-shadow:0 0 0 1px rgba(47,214,208,.45),0 0 18px rgba(47,214,208,.22)}
body.vice #toast{border:2px solid #140a2e;box-shadow:4px 4px 0 #140a2e;background:#ffd36b;color:#140a2e}
/* заставка при запуске */
body.vice #splash{visibility:hidden!important}
/* звонки */
body.vice #call{background:${NIGHT} center/cover no-repeat,linear-gradient(180deg,#1a0b3a,#2b0f4f 45%,#4a1559 72%,#6b1d55)}
body.vice #call:has(#cAcc){background:${SKY} center bottom/cover no-repeat,${NIGHT} center/cover no-repeat,#140a2e}
body.vice #call .cinfo h2{font-family:Anton,Impact,sans-serif;font-weight:400;font-size:42px;letter-spacing:1px;text-transform:uppercase;text-shadow:0 3px 0 #2a0f52,0 0 18px rgba(255,79,139,.8)}
body.vice #call .cinfo .av{box-shadow:0 0 0 4px #ffd36b,0 0 0 7px #0c0620,0 0 40px rgba(255,79,139,.7)}
body.vice #call:has(#cAcc) .cinfo::before{content:'ВХОДЯЩИЙ ЗВОНОК';display:inline-block;margin-bottom:18px;padding:5px 14px;background:#ffd36b;color:#140a2e;font-family:Anton,Impact,sans-serif;font-size:17px;letter-spacing:1.2px;border-radius:6px;box-shadow:4px 4px 0 #0c0620;transform:rotate(-3deg);text-shadow:none}
body.vice #call .cinfo p:has(#ctime)::after{content:'ОТЛИЧНАЯ СВЯЗЬ';display:block;width:max-content;margin:12px auto 0;padding:4px 12px;background:#ffd36b;color:#140a2e;font-family:Anton,Impact,sans-serif;font-size:14px;letter-spacing:1px;border-radius:6px;box-shadow:3px 3px 0 #0c0620;transform:rotate(-2deg);text-shadow:none;opacity:1}
body.vice #call .cbtns button{background:rgba(22,10,48,.45);border:1px solid rgba(255,255,255,.22)}
body.vice #call .cbtns button.off{background:#ffd36b;color:#140a2e;border:0;box-shadow:3px 3px 0 #0c0620}
body.vice #call .cbtns button.end{background:linear-gradient(135deg,#ff3b5c,#ff8a3d);border:0;box-shadow:0 0 0 2px #0c0620,4px 4px 0 2px #0c0620}
body.vice #call .cbtns button.acc{background:#2bd67b;border:0;box-shadow:0 0 0 2px #0c0620,4px 4px 0 2px #0c0620}
/* переключатель в «Оформлении» */
.vicesw{display:flex;align-items:center;gap:12px;padding:12px 14px;border-radius:16px;background:var(--panel2);margin:10px 14px;cursor:pointer}
.vicesw .ic{width:32px;height:32px;border-radius:9px;background:linear-gradient(135deg,#ff4f8b,#ff8a3d);display:flex;align-items:center;justify-content:center;flex:none}
.vicesw b{display:block;font-size:15px}.vicesw .t span{display:block;font-size:12.5px;color:var(--muted)}.vicesw .t{flex:1}
.vicesw input{width:22px;height:22px;accent-color:#ff4f8b}
/* вступление: комикс-панели, логотип и плашка */
#vintro{position:fixed;inset:0;z-index:99996;background:#140a2e;overflow:hidden;cursor:pointer;animation:viOut .55s cubic-bezier(.7,0,.3,1) 2.15s forwards}
@keyframes viOut{to{clip-path:polygon(100% 0,100% 0,100% 100%,100% 100%);visibility:hidden}}
#vintro .pn{position:absolute;border:4px solid #0c0620;box-shadow:0 0 0 5px #fff,10px 10px 0 5px rgba(0,0,0,.35);background-size:cover;background-position:center;opacity:0}
#vintro .p1{left:-4%;top:-3%;width:66%;height:46%;background-image:${SKY};transform:rotate(-4deg);animation:viP1 .5s cubic-bezier(.2,.9,.3,1.2) .05s forwards}
#vintro .p2{right:-6%;top:22%;width:52%;height:44%;background-image:${PALM};transform:rotate(5deg);animation:viP2 .5s cubic-bezier(.2,.9,.3,1.2) .2s forwards}
#vintro .p3{left:-6%;bottom:-4%;width:72%;height:40%;background:${NIGHT} center/cover,linear-gradient(180deg,#2b0f4f,#6b1d55);transform:rotate(3deg);animation:viP3 .5s cubic-bezier(.2,.9,.3,1.2) .35s forwards}
@keyframes viP1{from{opacity:0;transform:translate(-60px,-40px) rotate(-12deg)}to{opacity:1;transform:rotate(-4deg)}}
@keyframes viP2{from{opacity:0;transform:translate(80px,0) rotate(14deg)}to{opacity:1;transform:rotate(5deg)}}
@keyframes viP3{from{opacity:0;transform:translate(-40px,70px) rotate(-6deg)}to{opacity:1;transform:rotate(3deg)}}
#vintro .lg{position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);text-align:center;z-index:2}
#vintro .lg b{display:block;font-family:Anton,Impact,sans-serif;font-weight:400;font-size:min(30vw,150px);line-height:.9;letter-spacing:2px;
  background:linear-gradient(180deg,#ffe58a 0%,#ffb347 40%,#ff4f8b 100%);-webkit-background-clip:text;background-clip:text;color:transparent;
  -webkit-text-stroke:4px #140a2e;paint-order:stroke fill;filter:drop-shadow(7px 7px 0 #140a2e) drop-shadow(0 0 30px rgba(255,79,139,.6));
  opacity:0;animation:viLogo .5s cubic-bezier(.2,1.4,.4,1) .6s forwards}
@keyframes viLogo{from{opacity:0;transform:scale(2.6) rotate(-10deg)}to{opacity:1;transform:rotate(-4deg)}}
#vintro .lg i{display:inline-block;margin-top:14px;font-style:normal;font-family:Anton,Impact,sans-serif;font-size:min(6vw,26px);letter-spacing:2px;color:#140a2e;background:#ffd36b;
  padding:4px 14px;border-radius:6px;box-shadow:4px 4px 0 #0c0620;opacity:0;animation:viStamp .35s cubic-bezier(.2,1.6,.4,1) 1s forwards}
@keyframes viStamp{from{opacity:0;transform:scale(1.8) rotate(8deg)}to{opacity:1;transform:rotate(3deg)}}
#vintro .fl{position:absolute;inset:0;background:#fff;opacity:0;animation:viFlash .35s ease .6s;pointer-events:none;z-index:3}
@keyframes viFlash{0%{opacity:.85}100%{opacity:0}}
`;
  document.head.appendChild(st);

  let avail=false; try{ const c=JSON.parse(localStorage.getItem('vice_av')||'null'); avail=!!(c&&c.on&&(!c.until||new Date(c.until)>new Date())); }catch{}
  const offNow=()=>{ try{ return localStorage.getItem('vice_off')==='1'; }catch{ return false; } };
  const meta=document.querySelector('meta[name="theme-color"]'); const meta0=meta&&meta.getAttribute('content');
  function intro(){
    // вступление показывает сама страница при запуске; здесь — только если она его не показала, а Lumo ещё грузится
    if(document.getElementById('vintro')||document.documentElement.classList.contains('vice')) return;
    const sp=document.getElementById('splash'); if(!sp||sp.classList.contains('out')) return;
    const o=document.createElement('div'); o.id='vintro'; o.setAttribute('aria-hidden','true');
    o.innerHTML='<div class="pn p1"></div><div class="pn p2"></div><div class="pn p3"></div><div class="fl"></div><div class="lg"><b>LUMO</b><i>VICE NIGHTS</i></div>';
    const done=()=>o.remove(); o.addEventListener('animationend',e=>{ if(e.animationName==='viOut') done(); }); o.onclick=done; setTimeout(done,3200);
    document.body.appendChild(o);
  }
  function apply(){ const on=avail&&!offNow(); const was=document.body.classList.contains('vice'); document.body.classList.toggle('vice',on);
    if(meta) meta.setAttribute('content',on?'#2a0f52':(meta0||''));
    if(on&&!was) intro(); }
  // уровень «розыска»: сколько чатов с непрочитанными (до пяти звёзд)
  function stars(){ const mid=document.querySelector('#tghead .mid'); if(!mid) return; let s=mid.querySelector('.vstars');
    if(!s){ s=document.createElement('span'); s.className='vstars'; s.title='Уровень розыска: чаты с непрочитанными'; s.innerHTML=STAR.repeat(5); const b=mid.querySelector('b'); b?b.after(s):mid.appendChild(s); }
    const n=Math.min(5,(window.S&&S.chats?S.chats:(typeof S!=='undefined'&&S.chats?S.chats:[])).filter(c=>c.unread&&!c.muted).length);
    s.querySelectorAll('svg').forEach((e,i)=>e.classList.toggle('on',i<n)); }
  const check=async()=>{ try{ const {data}=await sb.rpc('lm_get_config'); const e=data&&data.look&&data.look.event;
      avail=!!(e&&e.id==='vice'&&(!e.until||new Date(e.until)>new Date()));
      try{ localStorage.setItem('vice_av',JSON.stringify({on:avail,until:e&&e.until||null})); }catch{} }catch{} apply(); };
  window.viceToggle=on=>{ try{ localStorage.setItem('vice_off',on?'0':'1'); }catch{} apply(); };
  window.viceAvail=()=>avail;
  apply(); setTimeout(check,800); setInterval(check,30*60*1000); setInterval(()=>{ if(document.body.classList.contains('vice')) stars(); },1500);
  // переключатель в «Оформлении»
  new MutationObserver(()=>{ if(!avail||typeof SP==='undefined'||SP.page!=='look') return; const hd=document.querySelector('.sphead'); if(!hd||!hd.parentNode||hd.parentNode.querySelector('.vicesw')) return;
    const d=document.createElement('label'); d.className='vicesw';
    d.innerHTML=`<span class="ic"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.2" stroke-linecap="round"><path d="M3 18h18M6 18a6 6 0 0 1 12 0M12 6V3M5 9 3.5 7.5M19 9l1.5-1.5"/></svg></span><span class="t"><b>Vice Nights</b><span>Закат, неон и пальмы — до 1 декабря</span></span><input type="checkbox" ${offNow()?'':'checked'}>`;
    d.querySelector('input').onchange=e=>viceToggle(e.target.checked);
    hd.after(d); }).observe(document.body,{childList:true,subtree:true});
})();
