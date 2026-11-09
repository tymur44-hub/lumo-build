/* ===== Экономия трафика: видео историй и полноэкранные видео скачиваются один раз и дальше играют из кэша браузера ===== */
(function(){
  const CN='lumo-video-v1', MAX_ONE=60*1024*1024, MAX_ALL=400*1024*1024, IDX='lumoVidIdx';
  const ok=('caches' in window)&&window.isSecureContext;
  const blobs=new Map(), pend=new Map();
  const isStorage=u=>/\/storage\/v1\/object\/public\//.test(u||'')&&!/^blob:/.test(u||'');
  const clean=u=>String(u||'').split('#')[0];
  const idx=()=>{ try{ return JSON.parse(localStorage.getItem(IDX)||'[]'); }catch(e){ return []; } };
  const setIdx=a=>{ try{ localStorage.setItem(IDX,JSON.stringify(a.slice(-300))); }catch(e){} };
  async function trim(cache){ let a=idx(), tot=a.reduce((s,x)=>s+(x.s||0),0); while(tot>MAX_ALL&&a.length){ const x=a.shift(); tot-=x.s||0; try{ await cache.delete(x.u); }catch(e){} } setIdx(a); }
  async function get(u){
    if(blobs.has(u)) return blobs.get(u);
    if(pend.has(u)) return pend.get(u);
    const p=(async()=>{
      const cache=await caches.open(CN);
      let r=await cache.match(u);
      if(!r){
        const head=await fetch(u,{method:'GET',headers:{Range:'bytes=0-0'}}).catch(()=>null);
        const total=head&&+(((head.headers.get('content-range')||'').split('/')[1])||0);
        if(!total||total>MAX_ONE) return null;
        const full=await fetch(u); if(!full.ok) return null;
        const b=await full.blob();
        await cache.put(u,new Response(b,{headers:{'Content-Type':b.type||'video/mp4','Content-Length':String(b.size)}}));
        const a=idx().filter(x=>x.u!==u); a.push({u,s:b.size}); setIdx(a); trim(cache);
        r=await cache.match(u);
      } else { const a=idx(); const i=a.findIndex(x=>x.u===u); if(i>=0){ a.push(a.splice(i,1)[0]); setIdx(a); } }
      if(!r) return null;
      const url=URL.createObjectURL(await r.blob()); blobs.set(u,url); return url;
    })().catch(()=>null).finally(()=>pend.delete(u));
    pend.set(u,p); return p;
  }
  const SEL='.stmedia video,#vplayer video,#lightbox video,.ov .modal video[controls]';
  function take(v){
    if(v.dataset.lvc) return; const src=v.getAttribute('src'); if(!isStorage(src)) return;
    v.dataset.lvc=1; const u=clean(src), frag=src.includes('#')?'#'+src.split('#')[1]:'';
    const auto=v.autoplay||v.hasAttribute('autoplay');
    v.removeAttribute('src'); try{ v.load(); }catch(e){}
    get(u).then(b=>{ if(!b) v.dataset.lvc='skip'; v.src=(b||src)+(b?frag:''); if(auto){ const pp=v.play(); if(pp&&pp.catch) pp.catch(()=>{}); } });
  }
  if(ok){
    new MutationObserver(ms=>{ for(const m of ms){ for(const n of m.addedNodes){ if(n.nodeType!==1) continue;
      if(n.matches&&n.matches(SEL)) take(n); n.querySelectorAll&&n.querySelectorAll(SEL).forEach(take); }
      if(m.type==='attributes'&&m.target.dataset&&m.target.dataset.lvc!=='skip'&&m.target.matches&&m.target.matches(SEL)&&isStorage(m.target.getAttribute('src'))){ delete m.target.dataset.lvc; take(m.target); } } })
      .observe(document.documentElement,{childList:true,subtree:true,attributes:true,attributeFilter:['src']});
  }
})();
