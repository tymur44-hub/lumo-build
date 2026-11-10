/* ===== Игры вдвоём: страница игр берётся с сервера (lm_games_html), встроенная — запасная ===== */
(function(){ let t=0; const load=()=>{ if(Date.now()-t<300000) return; t=Date.now();
  try{ sb.rpc('lm_games_html').then(r=>{ const h=r&&r.data&&r.data.html; if(typeof h==='string'&&h.indexOf('/*CFG*/')>=0) window.__lgHtml=h; }).catch(()=>{}); }catch(e){} };
  setTimeout(load,4000); document.addEventListener('click',e=>{ if(e.target.closest&&e.target.closest('[data-lgopen],[data-th]')) load(); },true); })();
