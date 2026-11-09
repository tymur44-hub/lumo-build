/* ===== Видеозвонок: кнопки прячутся через 5 секунд, касание возвращает; «картинка в картинке» при сворачивании ===== */
(function(){
  const st=document.createElement('style'); st.textContent=`
#call .cbtns,#call .spkl,#call #cui>div[style*="position:absolute"],#cPip{transition:opacity .45s ease,transform .45s ease}
#call.cidle .cbtns,#call.cidle .spkl,#call.cidle #cui>div[style*="position:absolute"],#call.cidle #cPip{opacity:0;transform:translateY(24px);pointer-events:none}
#call.cidle #cui>div[style*="position:absolute"],#call.cidle #cPip{transform:translateY(-16px)}
#cPip{position:absolute;top:calc(14px + env(safe-area-inset-top));right:16px;z-index:5;width:44px;height:44px;border-radius:50%;border:0;background:rgba(0,0,0,.35);color:#fff;display:none;place-items:center;cursor:pointer;-webkit-backdrop-filter:blur(10px);backdrop-filter:blur(10px)}
#cPip svg{width:22px;height:22px}
#call.vid #cPip{display:grid}
#call.vid #lv{top:calc(66px + env(safe-area-inset-top))}`; document.head.appendChild(st);
  const PIP_IC='<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2.5" y="4.5" width="19" height="15" rx="2.5"/><rect x="12" y="11" width="7" height="6" rx="1.2" fill="currentColor" stroke="none"/></svg>';
  let last=Date.now(), swallow=0;
  const vidOn=c=>{ const rv=c.querySelector('#rv'); return !!(rv&&!rv.classList.contains('hidden')&&rv.srcObject) || ['#rimg','#rcv'].some(q=>{ const e=c.querySelector(q); return e&&!e.classList.contains('hidden'); }); };
  const pipOk=()=>!!(document.pictureInPictureEnabled||(HTMLVideoElement.prototype.webkitSetPresentationMode));
  async function pip(){ const rv=document.querySelector('#call #rv'); if(!rv||rv.classList.contains('hidden')) return;
    try{ if(document.pictureInPictureElement) return await document.exitPictureInPicture();
      if(rv.requestPictureInPicture) return await rv.requestPictureInPicture();
      if(rv.webkitSetPresentationMode) rv.webkitSetPresentationMode(rv.webkitPresentationMode==='picture-in-picture'?'inline':'picture-in-picture');
    }catch(e){} }
  function wake(){ last=Date.now(); const c=document.getElementById('call'); if(c) c.classList.remove('cidle'); }
  document.addEventListener('pointerdown',e=>{ const c=document.getElementById('call'); if(!c||!c.contains(e.target)) return;
    if(c.classList.contains('cidle')){ e.preventDefault(); e.stopPropagation(); swallow=Date.now(); } wake(); },true);
  document.addEventListener('click',e=>{ if(Date.now()-swallow<700&&document.getElementById('call')&&document.getElementById('call').contains(e.target)){ swallow=0; e.preventDefault(); e.stopPropagation(); } },true);
  setInterval(()=>{ const c=document.getElementById('call'); if(!c) return;
    const on=vidOn(c); c.classList.toggle('vid',on&&pipOk());
    let b=document.getElementById('cPip');
    if(!b){ b=document.createElement('button'); b.id='cPip'; b.title='Картинка в картинке'; b.innerHTML=PIP_IC; b.onclick=e=>{ e.stopPropagation(); pip(); }; c.appendChild(b); }
    const rv=c.querySelector('#rv'); if(rv&&!rv.dataset.pipset){ rv.dataset.pipset=1; rv.autoPictureInPicture=true; rv.setAttribute('autopictureinpicture',''); }
    if(!on){ c.classList.remove('cidle'); return; }
    if(Date.now()-last>5000) c.classList.add('cidle');
  },1000);
  // свернули вкладку во время видеозвонка — браузер может сам открыть окошко с собеседником
  try{ navigator.mediaSession&&navigator.mediaSession.setActionHandler('enterpictureinpicture',()=>pip()); }catch(e){}
  document.addEventListener('visibilitychange',()=>{ const c=document.getElementById('call'); if(!c) return;
    if(document.hidden&&vidOn(c)&&!document.pictureInPictureElement){ pip(); }
    if(!document.hidden) wake(); });
})();
