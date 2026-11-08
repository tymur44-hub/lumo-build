/* ===== TG3: большие файлы — до 100 МБ, с Premium до 200 МБ. Хранилище берёт до 50 МБ за раз, поэтому режем на части по 45 МБ и склеиваем у получателя ===== */
(function(){
const CH=45*1024*1024;
window.tgLim=()=>((S.me&&S.me.premium)?200:100)*1024*1024;
window.tgLimTxt=()=>(S.me&&S.me.premium)?'200 МБ':'100 МБ (с Premium — 200 МБ)';
window.tgBigUp=async(f,ext)=>{ if(f.size<=CH) return null; const parts=[];
  for(let off=0,i=0;off<f.size;off+=CH,i++){ const b=f.slice(off,Math.min(f.size,off+CH),'application/octet-stream'); parts.push(await upload(b,ext+'.p'+i)); }
  return parts; };
const st=document.createElement('style'); st.setAttribute('data-lumo-own','1');
st.textContent='.file[data-big] .fi{position:relative}.file[data-big] .fi b{position:absolute;inset:0;display:grid;place-items:center;font-size:11px;font-weight:800;color:#fff;border-radius:50%}';
document.head.appendChild(st);
const busy=new Set(), done=new Map();
function findMsg(id){ for(const l of S.msgs.values()) for(const m of l) if(m.id===id) return m; return null; }
async function fetchBig(m,el){ if(done.has(m.id)) return done.get(m.id); if(busy.has(m.id)) return null; busy.add(m.id);
  const parts=m.meta.parts, out=[]; const fi=el&&el.querySelector('.fi'); const fs=el&&el.querySelector('.fs'); const total=m.meta.size||0;
  try{ for(let i=0;i<parts.length;i++){ const r=await fetch(pxu(parts[i])); if(!r.ok) throw new Error('HTTP '+r.status); out.push(await r.blob());
      const k=(i+1)/parts.length; if(fi) fi.innerHTML=`${ic('dl')}<b>${Math.round(k*100)}</b>`; if(fs&&total) fs.textContent=fmtSize(Math.round(total*k))+' из '+fmtSize(total); }
    const name=m.meta.name||'file'; const ext=(name.match(/\.([a-z0-9]{1,8})$/i)||[])[1]||'';
    const type=m.kind==='video'?('video/'+(ext==='mov'?'quicktime':(ext||'mp4'))):'';
    const blob=new Blob(out,type?{type}:{}); const url=URL.createObjectURL(blob); done.set(m.id,url); return url; }
  catch(e){ toast('Не удалось скачать файл'); return null; }
  finally{ busy.delete(m.id); if(fi) fi.innerHTML=ic(m.kind==='video'?'play':'dl'); if(fs&&total) fs.textContent=(m.kind==='video'?'Видео · ':'')+fmtSize(total); } }
document.addEventListener('click',async e=>{ const a=e.target.closest&&e.target.closest('[data-big]'); if(!a) return; e.preventDefault(); e.stopPropagation();
  const m=findMsg(+a.dataset.big); if(!m||!m.meta||!m.meta.parts) return; const url=await fetchBig(m,a); if(!url) return;
  if(m.kind==='video'){ modal(esc(m.meta.name||'Видео'),`<video src="${url}" controls autoplay playsinline style="width:100%;max-height:70vh;border-radius:14px;background:#000"></video>`,[['Сохранить','ghost',()=>{ const d=document.createElement('a'); d.href=url; d.download=m.meta.name||'video.mp4'; d.click(); }],['Закрыть','primary']]); }
  else { const d=document.createElement('a'); d.href=url; d.download=m.meta.name||'file'; document.body.appendChild(d); d.click(); d.remove(); } },true);
})();
