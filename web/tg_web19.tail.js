(function(){
  const st=document.createElement('style');
  st.textContent='.lgcv{width:150px!important;height:150px!important;display:block;margin:2px auto 0}.lgres.lgwait{opacity:0}.lgres{transition:opacity .25s}';
  document.head.appendChild(st);
  const started=new Map();
  function handle(cv){
    if(cv.dataset.done) return; cv.dataset.done=1;
    const k=cv.dataset.k, v=+cv.dataset.v, id=cv.dataset.id, res=cv.nextElementSibling;
    const show=()=>{ if(res) res.classList.remove('lgwait'); };
    if(cv.dataset.fresh&&!started.has(id)) started.set(id,performance.now());
    const t0=started.get(id), D=LumoThrows.duration(k,v);
    if(t0==null||(performance.now()-t0)/1000>=D){ LumoThrows.final(cv,k,v); show(); return; }
    if(res) res.classList.add('lgwait');
    let hit=false; const hitAt={dice:.62,coin:1.08,basket:1.1,football:1.35,darts:.76}[k]||1;
    const step=()=>{ if(!cv.isConnected) return; const t=(performance.now()-t0)/1000; LumoThrows.frame(cv,k,v,t);
      if(!hit&&t>=hitAt){ hit=true; try{ navigator.vibrate&&navigator.vibrate(18); }catch(e){} }
      if(t<D) requestAnimationFrame(step); else show(); };
    requestAnimationFrame(step);
  }
  const scan=()=>document.querySelectorAll('canvas.lgcv:not([data-done])').forEach(handle);
  new MutationObserver(scan).observe(document.body,{childList:true,subtree:true}); scan();
})();
