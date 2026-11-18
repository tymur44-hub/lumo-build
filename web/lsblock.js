/* ===== точка «не прослушано» у голосовых и кружков (meta.lb — кто прослушал) ===== */
(function(){ if(document.getElementById('lscss')) return; const st=document.createElement('style'); st.id='lscss'; st.textContent=`
.vdw{display:flex;align-items:center;gap:6px}.lsd{width:7px;height:7px;border-radius:50%;background:var(--a1);flex:none;transition:transform .25s,opacity .25s}
.out .lsd,.m.out .lsd{background:#fff}.lsd.gone{transform:scale(0);opacity:0}
.vn .lsd{position:absolute;right:20px;bottom:20px;width:13px;height:13px;border:2.5px solid var(--bg);box-sizing:content-box;background:var(--a1)}`; document.head.appendChild(st); })();
const LS_LOCAL=new Set(), LS_SENT=new Set();
function lsUnheard(m){ if(!m||(m.kind!=='voice'&&m.kind!=='video_note')||!(m.id>0)||!S.me) return false;
  const lb=Array.isArray(m.meta&&m.meta.lb)?m.meta.lb:[];
  if(m.sender_id===S.me.id){ const c=S.chatMap.get(m.chat_id); if(c&&c.type==='private'&&c.peer_id===S.me.id) return false; return lb.length===0; }
  return !LS_LOCAL.has(m.id)&&!lb.includes(S.me.id); }
function lsDot(m){ return lsUnheard(m)?`<span class="lsd" data-lsd="${m.id}"></span>`:''; }
function lsMark(m){ if(!m||!S.me||m.sender_id===S.me.id||!lsUnheard(m)) return; LS_LOCAL.add(m.id);
  document.querySelectorAll(`[data-lsd="${m.id}"]`).forEach(d=>{ d.classList.add('gone'); setTimeout(()=>d.remove(),300); });
  if(LS_SENT.has(m.id)) return; LS_SENT.add(m.id); try{ sb.rpc('lm_voice_listen',{p_msg:m.id}).then(()=>{},()=>{}); }catch{} }
function lsOnlyLb(a,b){ try{ if(!a||!b||a.body!==b.body||a.media_url!==b.media_url||a.deleted!==b.deleted||a.edited_at!==b.edited_at) return false;
  const x=Object.assign({},a.meta||{}), y=Object.assign({},b.meta||{}); delete x.lb; delete y.lb; return JSON.stringify(x)===JSON.stringify(y); }catch{ return false; } }
function lsRefresh(m){ if(!lsUnheard(m)) document.querySelectorAll(`[data-lsd="${m.id}"]`).forEach(d=>{ d.classList.add('gone'); setTimeout(()=>d.remove(),300); }); }
