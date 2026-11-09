/* ===== «Моя история»: долгое нажатие / правая кнопка — как в приложении (добавить, опубликованные, архив) ===== */
(function(){
  const st=document.createElement('style'); st.textContent='.setgrp.pesg{margin:0 0 14px}'; document.head.appendChild(st);
  const fire=id=>{ const d=document.createElement('div'); d.id=id; d.style.display='none'; document.body.appendChild(d); d.click(); d.remove(); };
  const mine=t=>{ const b=t.closest&&t.closest('.stbar .stit'); return b&&b===b.parentElement.querySelector('.stit')?b:null; };
  function menu(b){ dropMenu(b,[['plus','Добавить историю',()=>{ const a=b.querySelector('[data-st-add]'); if(a) a.click(); }],
    ['tgrid','Опубликованные истории',()=>fire('tgSPosts')],['tarch','Архив историй',()=>fire('tgSArc')]]); }
  document.addEventListener('contextmenu',e=>{ const b=mine(e.target); if(!b) return; e.preventDefault(); e.stopPropagation(); menu(b); },true);
  let lp=null, lpFired=false;
  document.addEventListener('touchstart',e=>{ const b=mine(e.target); if(!b) return; lpFired=false; clearTimeout(lp); lp=setTimeout(()=>{ lpFired=true; navigator.vibrate&&navigator.vibrate(15); menu(b); },480); },{passive:true,capture:true});
  ['touchend','touchmove','touchcancel'].forEach(ev=>document.addEventListener(ev,()=>clearTimeout(lp),{passive:true,capture:true}));
  document.addEventListener('click',e=>{ if(lpFired&&mine(e.target)){ lpFired=false; e.preventDefault(); e.stopPropagation(); } },true);
})();
