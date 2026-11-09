/* ===== Черновики: недописанный текст хранится по чатам (и после перезагрузки), в списке чатов — «Черновик: …» ===== */
function lmDraftKey(){ return S.me&&S.me.id?'lm_drafts_'+S.me.id:null; }
function lmDraftsSave(){ const k=lmDraftKey(); if(!k) return; try{ const o={}; drafts.forEach((v,id)=>{ if(id&&v&&v.trim()) o[id]=v.slice(0,4000); }); if(Object.keys(o).length) localStorage.setItem(k,JSON.stringify(o)); else localStorage.removeItem(k); }catch(e){} }
(function(){
  const st=document.createElement('style'); st.textContent='.row .pv .drf{color:#e5484d;font-weight:600}'; document.head.appendChild(st);
  let loaded=false;
  const ld=setInterval(()=>{ const k=lmDraftKey(); if(!k) return; clearInterval(ld); loaded=true;
    try{ const o=JSON.parse(localStorage.getItem(k)||'{}'); for(const id in o){ if(!drafts.has(id)&&o[id]) drafts.set(id,o[id]); } }catch(e){}
    if(S.cur&&drafts.get(S.cur)&&!$('#txt').value){ $('#txt').value=drafts.get(S.cur); try{ autoGrow(); }catch(e){} }
    try{ renderList(); }catch(e){} },300);
  let t;
  document.addEventListener('input',e=>{ if(!e.target||e.target.id!=='txt'||!S.cur||!loaded) return; clearTimeout(t); t=setTimeout(saveDraft,400); },true);
  const flush=()=>{ if(S.cur&&loaded) saveDraft(); };
  addEventListener('pagehide',flush); document.addEventListener('visibilitychange',()=>{ if(document.hidden) flush(); });
  document.addEventListener('click',e=>{ if(e.target.closest&&e.target.closest('#sDrafts')) setTimeout(()=>{ if(!Object.keys(localStorage).some(k=>/^lm_drafts_/.test(k))){ drafts.clear(); try{ renderList(); }catch(e){} } },600); },true);
})();
