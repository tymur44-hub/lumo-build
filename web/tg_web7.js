/* ===== TG7: приглашения в групповой звонок, настройка звонков группы, «Изменить контакт» как в приложении ===== */
(function(){
const KEY7=SUPABASE_KEY;
const st=document.createElement('style'); st.setAttribute('data-lumo-own','1'); st.textContent=`
#gcinv{position:fixed;inset:0;z-index:2147482000;background:linear-gradient(#1b2a4a,#0b0b10);color:#fff;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:24px;text-align:center;animation:tgup .38s cubic-bezier(.2,.9,.3,1)}
#gcinv.out{animation:tgdown .3s ease forwards}
#gcinv .ring{position:relative;width:150px;height:150px;display:grid;place-items:center}
#gcinv .ring:before{content:'';position:absolute;inset:0;border-radius:50%;background:rgba(255,255,255,.12);animation:gcpulse 1.6s ease-out infinite}
@keyframes gcpulse{from{transform:scale(.95);opacity:1}to{transform:scale(1.3);opacity:0}}
#gcinv .ring .av{width:120px!important;height:120px!important;font-size:44px}
#gcinv h2{font-size:28px;margin:16px 0 4px}
#gcinv .s1{opacity:.7;font-size:16px}#gcinv .s2{font-size:15px;font-weight:600;margin-top:4px;opacity:.9}
#gcinv .who{margin-top:18px;background:rgba(255,255,255,.08);border-radius:18px;padding:14px 18px;max-width:420px;width:100%}
#gcinv .who small{display:block;font-size:12px;font-weight:800;opacity:.55;margin-bottom:6px}
#gcinv .bt{display:flex;gap:70px;margin-top:46px}
#gcinv .bt div{display:flex;flex-direction:column;align-items:center;gap:8px;font-size:14px;opacity:.9}
#gcinv .bt button{width:74px;height:74px;border-radius:50%;border:0;color:#fff;display:grid;place-items:center;cursor:pointer;transition:transform .15s}
#gcinv .bt button:active{transform:scale(.92)}
#gcinv .bt button svg{width:32px;height:32px}
#gcinv .no{background:#ff3b30}#gcinv .yes{background:#34c759}
.tggcm .r{display:flex;align-items:center;justify-content:space-between;padding:13px 16px;cursor:pointer;border-top:1px solid var(--line)}
.tggcm .r:first-child{border-top:0}.tggcm .r svg{width:20px;height:20px;color:var(--a1);opacity:0;transition:opacity .15s}.tggcm .r.on svg{opacity:1}
.tggcm{background:var(--panel2);border-radius:16px;overflow:hidden;margin-top:6px}
#tgce{position:fixed;inset:0;z-index:99700;background:var(--bg);color:var(--text);overflow:auto;animation:tgup .36s cubic-bezier(.2,.9,.3,1)}
#tgce.out{animation:tgdown .3s ease forwards}
#tgce .w{max-width:560px;margin:0 auto;padding:max(12px,env(safe-area-inset-top)) 16px 40px}
#tgce .tb{display:flex;justify-content:space-between;align-items:center;height:56px}
#tgce .tb button{width:48px;height:48px;border-radius:50%;border:1px solid var(--line);background:var(--panel2);display:grid;place-items:center;color:var(--text);cursor:pointer}
#tgce .tb button.ok{background:var(--a1);border-color:var(--a1);color:#fff}
#tgce .tb button svg{width:22px;height:22px}
#tgce .ava{display:grid;place-items:center;margin:4px 0 22px}
#tgce .ava .av,#tgce .ava img{width:116px!important;height:116px!important;border-radius:50%;object-fit:cover;font-size:42px}
#tgce .cd{background:var(--panel);border-radius:26px;overflow:hidden;margin-bottom:8px}
#tgce .cd input,#tgce .cd textarea{display:block;width:100%;box-sizing:border-box;border:0;outline:0;background:none;color:var(--text);font-size:17px;padding:16px 18px;font-family:inherit;resize:none}
#tgce .cd input+input{border-top:1px solid var(--line)}
#tgce .hint{color:var(--muted);font-size:13px;margin:0 20px 22px}
#tgce .act{display:flex;align-items:center;gap:14px;padding:16px 18px;color:var(--a1);cursor:pointer;font-size:16px}
#tgce .act+.act{border-top:1px solid var(--line)}
#tgce .act svg{width:22px;height:22px}
#tgce .del{color:var(--danger,#ff3b30)}`;
document.head.appendChild(st);

async function lk(chat,action,extra){ const ses=await sb.auth.getSession(); const tk=ses&&ses.data&&ses.data.session&&ses.data.session.access_token;
  const r=await fetch(`${SUPABASE_URL}/functions/v1/lumo-lk`,{method:'POST',headers:{'Content-Type':'application/json',apikey:KEY7,Authorization:'Bearer '+tk},body:JSON.stringify(Object.assign({chat_id:chat,action},extra||{}))});
  return await r.json().catch(()=>({})); }
window.tgLkApi=lk;

/* --- входящее приглашение --- */
function showInvite(p){ if(!p||!p.chat_id||(window.GCall&&GCall.active)||document.getElementById('gcinv')) return;
  const d=document.createElement('div'); d.id='gcinv';
  const names=(p.names||[]).filter(Boolean);
  d.innerHTML=`<div class="ring">${avatar({name:p.title,avatar:p.avatar,color:p.color||0},'l')}</div><h2>${esc(p.title||'Группа')}</h2><div class="s1">Входящий групповой звонок</div><div class="s2">${esc(p.from||'Участник')} приглашает вас</div>
${names.length?`<div class="who"><small>УЖЕ В ЗВОНКЕ</small>${esc(names.slice(0,6).join(', '))}${names.length>6?' и ещё '+(names.length-6):''}</div>`:''}
<div class="bt"><div><button class="no">${ic('phone')}</button>Отклонить</div><div><button class="yes">${ic('phone')}</button>Присоединиться</div></div>`;
  d.querySelector('.no svg').style.transform='rotate(135deg)';
  document.body.appendChild(d);
  try{ navigator.vibrate&&navigator.vibrate([300,200,300]); }catch(e){}
  const close=()=>{ if(!d.isConnected) return; d.classList.add('out'); setTimeout(()=>d.remove(),300); };
  d.querySelector('.no').onclick=close;
  d.querySelector('.yes').onclick=async()=>{ close(); const c=S.chatMap.get(p.chat_id)||{chat_id:p.chat_id,type:'group',title:p.title}; window.tgGcall&&window.tgGcall(c,false,true); };
  setTimeout(close,45000); }
let gcCh=null;
setInterval(()=>{ if(gcCh||!S||!S.me||!S.me.id) return;
  gcCh=sb.channel('lm-gc-'+S.me.id).on('broadcast',{event:'invite'},m=>showInvite(m&&m.payload)).subscribe(); },1500);

/* --- настройка «кто может звонить» в редактировании группы --- */
window.tgGcSet=async(box,c)=>{ if(!box||!c) return; const id=c.chat_id||c.id; const r=await lk(id,'status'); if(!r||!r.admin) return;
  let mode=r.mode||'all';
  const draw=()=>{ box.innerHTML=`<div class="field"><label>Групповые звонки</label><div class="tggcm">${[['all','Все могут начать звонок'],['admins','Только администраторы начинают'],['off','Звонки отключены']].map(([k,t])=>`<div class="r ${mode===k?'on':''}" data-m="${k}">${t}${ic('check')}</div>`).join('')}</div></div>`;
    box.querySelectorAll('[data-m]').forEach(el=>el.onclick=async()=>{ const old=mode; mode=el.dataset.m; draw(); const {error}=await sb.rpc('lm_set_group_calls',{p_chat:id,p_mode:mode}); if(error){ mode=old; draw(); toast(error.message); } }); };
  draw(); };

/* --- «Изменить контакт» (плавное окно, как в приложении) --- */
window.tgContactEdit=async(uid)=>{ const p=S.profiles.get(uid)||{}; if(p.is_bot){ toast('Имя бота изменить нельзя'); return; }
  const real=p.__real||p.name||''; const al=S.alias.get(uid)||'';
  const {data:row}=await sb.from('lm_contacts').select('note,photo').eq('contact_id',uid).maybeSingle();
  const full=al||real; const sp=full.indexOf(' ');
  let first=sp>0?full.slice(0,sp):full, last=sp>0?full.slice(sp+1):'', note=(row&&row.note)||'', photo=(row&&row.photo)||null, newFile=null, newUrl=null;
  const d=document.createElement('div'); d.id='tgce';
  const avHtml=()=>newUrl?`<img src="${newUrl}">`:avatar({name:first||real,avatar:photo||p.avatar_url,color:p.color||0},'l');
  const draw=()=>{ d.innerHTML=`<div class="w"><div class="tb"><button data-k="x">${ic('x')}</button><button class="ok" data-k="s">${ic('check')}</button></div>
<div class="ava">${avHtml()}</div>
<div class="cd"><input id="ceF" placeholder="Имя" maxlength="64" value="${esc(first)}"><input id="ceL" placeholder="Фамилия" maxlength="64" value="${esc(last)}"></div><div style="height:14px"></div>
<div class="cd"><textarea id="ceN" rows="2" maxlength="300" placeholder="Заметка">${esc(note)}</textarea></div><div class="hint">Заметку видите только Вы.</div>
<div class="cd"><div class="act" data-k="ph">${ic('image')}Установить фото для ${esc(first||real)}</div>${(photo||newUrl)?`<div class="act" data-k="rp">${ic('back')}Вернуть настоящее фото</div>`:''}</div>
<div class="hint">Вы можете заменить фотографию ${esc(real)} другой по своему выбору. Она будет видна только Вам.</div>
${isContact(uid)?`<div class="cd"><div class="act del" data-k="dl">Удалить контакт</div></div>`:''}</div>`;
    const keep=()=>{ first=d.querySelector('#ceF').value; last=d.querySelector('#ceL').value; note=d.querySelector('#ceN').value; };
    d.querySelector('[data-k=x]').onclick=close;
    d.querySelector('[data-k=s]').onclick=async()=>{ keep(); const b=d.querySelector('[data-k=s]'); b.style.opacity=.6; b.style.pointerEvents='none';
      try{ let url=photo; if(newFile) url=await upload(newFile,'jpg');
        const {error}=await sb.rpc('lm_set_contact_extra',{p_user:uid,p_note:note.trim(),p_photo:url||''}); if(error) throw error;
        const name=[first,last].map(x=>x.trim()).filter(Boolean).join(' '); await saveAlias(uid,name===real?'':name); close(); }
      catch(e){ toast(e.message||'Ошибка'); b.style.opacity=1; b.style.pointerEvents=''; } };
    d.querySelector('[data-k=ph]').onclick=()=>{ keep(); const i=document.createElement('input'); i.type='file'; i.accept='image/*'; i.style.cssText='position:fixed;left:-9999px';
      document.body.appendChild(i); i.onchange=async()=>{ const f=i.files&&i.files[0]; i.remove(); if(!f) return; newFile=await compressImage(f); newUrl=URL.createObjectURL(newFile); draw(); }; i.click(); };
    const rp=d.querySelector('[data-k=rp]'); rp&&(rp.onclick=()=>{ keep(); photo=null; newFile=null; newUrl=null; draw(); });
    const dl=d.querySelector('[data-k=dl]'); dl&&(dl.onclick=()=>confirmBox('Удалить контакт?','Удалить',async()=>{ await removeContact(uid); close(); })); };
  const close=()=>{ d.classList.add('out'); setTimeout(()=>d.remove(),300); };
  draw(); document.body.appendChild(d); };
})();
