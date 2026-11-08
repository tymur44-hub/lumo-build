/* ===== Блокировка аккаунта: окно с кирпичной стеной и апелляция; боты: остановить/перезапустить ===== */
P.stopsq='<rect x="6" y="6" width="12" height="12" rx="2.5" fill="currentColor"/>';
(function(){ const st=document.createElement('style'); st.textContent=`
#bannedScr{position:fixed;inset:0;z-index:99990;background:var(--bg);color:var(--text);overflow-y:auto;overflow-x:hidden;display:block;padding:0;text-align:center;animation:bnIn .45s ease both}
#bannedScr::before{content:"";position:absolute;left:0;right:0;top:0;height:420px;background:radial-gradient(ellipse at 50% 0,rgba(255,91,91,.26),transparent 70%);pointer-events:none}
@keyframes bnIn{from{opacity:0;transform:scale(1.03)}to{opacity:1;transform:none}}
#bannedScr .bnw{position:relative;max-width:440px;margin:0 auto;padding:56px 20px 30px}
#bannedScr .wall{position:relative;width:250px;height:190px;margin:0 auto}
#bannedScr .bricks{position:absolute;left:0;top:0;width:250px;height:150px;overflow:hidden;-webkit-mask:linear-gradient(transparent,#000 38%);mask:linear-gradient(transparent,#000 38%)}
#bannedScr .bk{position:absolute;height:21px;border-radius:4px;box-shadow:0 1.5px 2px rgba(0,0,0,.28),inset 0 2px 0 rgba(255,255,255,.18);opacity:0;animation:bkDrop .55s cubic-bezier(.3,1.5,.6,1) both}
@keyframes bkDrop{from{opacity:0;transform:translateY(-110px)}to{opacity:1;transform:none}}
#bannedScr .lk{position:absolute;left:50%;bottom:0;width:84px;height:84px;margin-left:-42px;border-radius:50%;background:var(--bg);padding:4px;opacity:0;animation:lkPop .6s cubic-bezier(.3,1.6,.5,1) .85s both}
#bannedScr .lk i{display:grid;place-items:center;width:100%;height:100%;border-radius:50%;background:linear-gradient(135deg,#ff6a5b,#e0284f);color:#fff;box-shadow:0 10px 26px rgba(224,40,79,.5)}
#bannedScr .lk svg{width:34px;height:34px}
@keyframes lkPop{from{opacity:0;transform:scale(.2)}to{opacity:1;transform:none}}
#bannedScr h2{margin:20px 0 0;font-size:26px;font-weight:800;letter-spacing:-.2px}
#bannedScr .sub{margin:10px 8px 0;color:var(--muted);font-size:15px;line-height:1.45}
#bannedScr .why{margin-top:22px;text-align:left;background:var(--panel);border:1px solid rgba(255,106,91,.35);border-radius:18px;padding:16px}
#bannedScr .why small{display:flex;align-items:center;gap:6px;color:#ff6a5b;font-size:12px;font-weight:700;letter-spacing:.3px}
#bannedScr .why small svg{width:15px;height:15px}
#bannedScr .why b{display:block;margin-top:6px;font-size:16px;font-weight:600;white-space:pre-wrap;word-break:break-word}
#bannedScr .apst{margin-top:12px;display:flex;gap:12px;text-align:left;background:var(--panel);border-radius:18px;padding:14px}
#bannedScr .apst svg{width:24px;height:24px;flex:none;color:#f0a23a}
#bannedScr .apst.rej svg{color:var(--danger)}
#bannedScr .apst b{display:block;font-size:15px}#bannedScr .apst span{display:block;margin-top:3px;color:var(--muted);font-size:13.5px;line-height:1.4;white-space:pre-wrap}
#bannedScr .bnbtn,#apSheet .bnbtn{margin-top:22px;width:100%;height:54px;border:0;border-radius:16px;background:linear-gradient(135deg,var(--a1),var(--a2));color:#fff;font-weight:700;font-size:17px;font-family:inherit;display:flex;align-items:center;justify-content:center;gap:8px;cursor:pointer;transition:transform .15s,opacity .2s}
#bannedScr .bnbtn:active,#apSheet .bnbtn:active{transform:scale(.97)}#bannedScr .bnbtn[disabled],#apSheet .bnbtn[disabled]{opacity:.5;cursor:default}
#bannedScr .bnbtn svg,#apSheet .bnbtn svg{width:20px;height:20px}
#bannedScr .bnout{margin-top:8px;background:none;border:0;color:var(--muted);font-weight:600;font-size:15px;font-family:inherit;padding:12px 16px;cursor:pointer;border-radius:10px}
#bannedScr .bnout:hover{background:var(--hover)}
#apSheet{position:fixed;inset:0;z-index:99991;background:var(--bg);display:flex;flex-direction:column;transform:translateY(100%);transition:transform .38s cubic-bezier(.2,.9,.3,1)}
#apSheet.on{transform:none}
#apSheet .aph{display:flex;align-items:center;padding:12px 14px}
#apSheet .aph button{width:40px;height:40px;border-radius:50%;border:0;background:var(--panel);color:var(--text);display:grid;place-items:center;cursor:pointer}
#apSheet .aph button svg{width:20px;height:20px}
#apSheet .aph b{flex:1;text-align:center;font-size:17px}
#apSheet .apb{flex:1;overflow:auto;padding:8px 20px 20px;max-width:560px;width:100%;margin:0 auto;box-sizing:border-box}
#apSheet .aphd{display:flex;gap:12px;align-items:center}
#apSheet .aphd i{width:48px;height:48px;flex:none;border-radius:14px;background:linear-gradient(135deg,var(--a1),var(--a2));color:#fff;display:grid;place-items:center}
#apSheet .aphd i svg{width:24px;height:24px}
#apSheet .aphd b{display:block;font-size:18px}#apSheet .aphd span{color:var(--muted);font-size:13.5px}
#apSheet textarea{margin-top:14px;width:100%;min-height:220px;box-sizing:border-box;border:0;outline:0;resize:vertical;background:var(--panel);color:var(--text);border-radius:18px;padding:16px;font-size:16px;line-height:1.45;font-family:inherit}
#apSheet .apm{display:flex;gap:10px;margin-top:8px;color:var(--muted);font-size:12.5px}#apSheet .apm span:first-child{flex:1}
#apSheet .aperr{color:var(--danger);font-size:14px;margin-top:8px}
#apSheet .apf{padding:12px 20px 18px;max-width:560px;width:100%;margin:0 auto;box-sizing:border-box}
#apSheet .apf .bnbtn{margin:0}
#apSheet .apok{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center;padding:30px;animation:bnIn .4s ease both}
#apSheet .apok i{width:88px;height:88px;border-radius:50%;background:linear-gradient(135deg,var(--a1),var(--a2));color:#fff;display:grid;place-items:center}
#apSheet .apok i svg{width:46px;height:46px}
#apSheet .apok b{margin-top:18px;font-size:22px}#apSheet .apok span{margin-top:8px;color:var(--muted);font-size:15px;max-width:360px}
#apSheet .bnbtn,#bannedScr .bnbtn{font-family:inherit}
.adapl{background:var(--panel);border-radius:16px;padding:14px;margin-bottom:10px}
.adapl .h{display:flex;align-items:center;gap:10px}.adapl .h .mid{flex:1;min-width:0}.adapl .h b{display:block}.adapl .h span{color:var(--muted);font-size:13px}
.adapl .rs{margin-top:10px;font-size:13px;color:var(--muted)}.adapl .rs em{font-style:normal;color:#ff6a5b}
.adapl .tx{margin-top:8px;white-space:pre-wrap;word-break:break-word;line-height:1.45}
.adapl .rb{display:flex;gap:8px;flex-wrap:wrap;margin-top:12px}
.adapl .rb button{display:flex;align-items:center;gap:6px;border:0;border-radius:10px;padding:8px 12px;background:var(--panel2,var(--hover));color:var(--text);font-weight:600;font-size:13.5px;font-family:inherit;cursor:pointer}
.adapl .rb button svg{width:16px;height:16px}.adapl .rb .ok{background:rgba(62,224,160,.16);color:#22b07d}.adapl .rb .no{background:rgba(255,91,122,.14);color:var(--danger)}
.adapl .st{font-size:13px;color:var(--muted)}
`; document.head.appendChild(st); })();

let BAN=null, banTimer=null;
function banState(j){ if(!j||!j.banned) return null; const a=j.appeal||{}; return {reason:j.reason||'',st:a.status||null,reply:a.reply||'',at:a.created_at||null}; }
async function banCheck(){ try{ const {data,error}=await sb.rpc('lm_my_ban'); if(error||!data) return;
  const b=banState(data);
  if(!b){ if(BAN){ BAN=null; location.reload(); } return; }
  const changed=JSON.stringify(b)!==JSON.stringify(BAN); BAN=b; if(changed||!document.getElementById('bannedScr')) drawBanned(); }catch(e){} }
function banWatch(){ clearInterval(banTimer); banCheck(); banTimer=setInterval(banCheck,30000); }
function brickWall(){ let h=''; const tones=['#c8553d','#b4472f','#d76a4c','#a63f2b','#bf5a3f']; const rows=6, per=5, gap=4, bw=(250-gap*(per-1))/per, bh=21;
  for(let r=0;r<rows;r++){ const odd=r%2===1, n=odd?per+1:per, sh=odd?-bw/2:0;
    for(let i=0;i<n;i++){ const ord=(rows-1-r)*(per+1)+i, c=tones[(r*3+i*7)%tones.length];
      h+=`<span class="bk" style="left:${(sh+i*(bw+gap)).toFixed(1)}px;top:${r*(bh+gap)}px;width:${bw.toFixed(1)}px;background:linear-gradient(${c},${c}cc);animation-delay:${(ord*0.028).toFixed(3)}s"></span>`; } }
  return h; }
function drawBanned(){ const b=BAN; if(!b) return; let d=document.getElementById('bannedScr'); const fresh=!d;
  if(fresh){ d=document.createElement('div'); d.id='bannedScr'; ($('#lumo-root')||document.body).appendChild(d); }
  const pend=b.st==='pending', rej=b.st==='rejected', un=S.me&&S.me.username;
  const apst=b.st&&b.st!=='accepted'?`<div class="apst ${rej?'rej':''}">${ic(rej?'x':'hourglass')}<div><b>${rej?'Апелляция отклонена':'Апелляция отправлена'}</b><span>${rej?(b.reply?'Ответ модератора: '+esc(b.reply):'Модераторы оставили блокировку в силе.'):'Модераторы рассмотрят её и снимут блокировку, если согласятся. Это окно обновится само.'}</span></div></div>`:'';
  const body=`<div class="bnw">${fresh?`<div class="wall"><div class="bricks">${brickWall()}</div><div class="lk"><i>${ic('lock')}</i></div></div>`:d.querySelector('.wall').outerHTML}
<h2>Ваш аккаунт заблокирован</h2>
<p class="sub">Администрация Lumo ограничила доступ к аккаунту${un?' @'+esc(un):''}. Пока блокировка действует, нельзя писать сообщения и пользоваться Lumo.</p>
<div class="why"><small>${ic('info')}ПРИЧИНА</small><b>${b.reason?esc(b.reason):'Причина не указана'}</b></div>${apst}
<button class="bnbtn" id="bnAp" ${pend?'disabled':''}>${ic(pend?'clock':'send')}${pend?'Апелляция на рассмотрении':rej?'Подать апелляцию ещё раз':'Подать апелляцию'}</button>
<button class="bnout" id="bnOut">Выйти из аккаунта</button></div>`;
  d.innerHTML=body;
  d.querySelector('#bnAp').onclick=()=>{ if(!pend) openAppeal(); };
  d.querySelector('#bnOut').onclick=()=>confirmBox('Выйти из аккаунта?','Выйти',()=>{ clearInterval(banTimer); logout(); }); }
function showBanned(me){ S.me=S.me||me; BAN=BAN||{reason:me.ban_reason||'',st:null,reply:'',at:null}; drawBanned(); banWatch(); }
function openAppeal(){ document.getElementById('apSheet')?.remove();
  const s=document.createElement('div'); s.id='apSheet';
  s.innerHTML=`<div class="aph"><button id="apX" title="Закрыть">${ic('x')}</button><b>Апелляция</b><span style="width:40px"></span></div>
<div class="apb"><div class="aphd"><i>${ic('chat')}</i><div><b>Расскажите, что случилось</b><span>За что вас могли заблокировать и почему блокировку стоит снять</span></div></div>
<textarea id="apT" maxlength="2000" placeholder="Например: я отправил много одинаковых сообщений, потому что…"></textarea>
<div class="apm"><span>Пишите честно и спокойно — так апелляцию рассмотрят быстрее.</span><span id="apN">0/2000</span></div><div class="aperr" id="apE"></div></div>
<div class="apf"><button class="bnbtn" id="apS" disabled>${ic('send')}Отправить апелляцию</button></div>`;
  document.body.appendChild(s); requestAnimationFrame(()=>requestAnimationFrame(()=>s.classList.add('on')));
  const close=()=>{ s.classList.remove('on'); setTimeout(()=>s.remove(),400); };
  const T=s.querySelector('#apT'), B=s.querySelector('#apS');
  setTimeout(()=>T.focus(),380);
  s.querySelector('#apX').onclick=close;
  T.oninput=()=>{ s.querySelector('#apN').textContent=T.value.length+'/2000'; B.disabled=T.value.trim().length<10; };
  B.onclick=async()=>{ if(B.disabled) return; B.disabled=true; B.innerHTML='<span class="tgsp"></span>'; s.querySelector('#apE').textContent='';
    const {data,error}=await sb.rpc('lm_appeal_submit',{p_text:T.value.trim()});
    if(error){ s.querySelector('#apE').textContent=error.message; B.disabled=false; B.innerHTML=ic('send')+'Отправить апелляцию'; return; }
    BAN=banState(data)||BAN; drawBanned();
    s.querySelector('.apb').outerHTML=`<div class="apok"><i>${ic('check')}</i><b>Апелляция отправлена</b><span>Модераторы прочитают ваше обращение. Если блокировку снимут, Lumo откроется сам.</span></div>`;
    B.disabled=false; B.innerHTML='Готово'; B.onclick=close; }; }

/* --- боты --- */
function isBotUser(uid){ if(!uid) return false; if(S.profiles.get(uid)?.is_bot) return true; return S.chats.some(c=>c.type==='private'&&c.peer_id===uid&&c.peer_bot); }
async function botStop(uid,stop,chatId){ if(!(await doBlock(uid,stop))) return; toast(stop?'Бот остановлен':'Бот перезапущен'); afterPeerChange();
  if(!stop&&chatId&&cur()&&cur().chat_id===chatId){ startBot(); } }

/* --- админка: апелляции --- */
async function admApl(V){
  AD.f.apl=AD.f.apl||'pending';
  V.innerHTML=adChips([['pending','Новые'],['rejected','Отклонённые'],['accepted','Принятые'],['all','Все']],AD.f.apl)+'<div id="admL"></div>';
  const L=V.querySelector('#admL');
  const load=async()=>{ L.innerHTML='<div class="adload"><span class="tgsp"></span></div>';
    try{ const R=await rpc('lm_admin_appeals',{p_status:AD.f.apl});
      L.innerHTML=R.length?`<div class="adcount">Апелляций: ${R.length}</div>`+R.map(a=>`<div class="adapl"><div class="h">${avatar({name:a.name,avatar:a.avatar_url,color:a.color},'s')}<div class="mid"><b>${esc(a.name||'')}</b><span>@${esc(a.username||'?')} · ${admAgo(a.created_at)}</span></div></div>
<div class="rs">Причина блокировки: <em>${esc(a.ban_reason||'не указана')}</em></div><div class="tx">${esc(a.text)}</div>
<div class="rb"><button data-u2="${a.user_id}">${ic('user')}Профиль</button>${a.status==='pending'?`<button class="ok" data-ok="${a.id}">${ic('check')}Разблокировать</button><button class="no" data-no="${a.id}">${ic('x')}Отклонить</button>`:`<span class="st">${a.status==='accepted'?'принята — разблокирован':'отклонена'}${a.reply?' · «'+esc(a.reply)+'»':''}</span>`}</div></div>`).join(''):adEmpty(AD.f.apl==='pending'?'Новых апелляций нет':'Пусто');
      L.querySelectorAll('[data-u2]').forEach(b=>b.onclick=()=>admPush({t:'user',id:b.dataset.u2}));
      L.querySelectorAll('[data-ok]').forEach(b=>b.onclick=()=>confirmBox('Принять апелляцию и разблокировать пользователя?','Разблокировать',async()=>{ try{ await rpc('lm_admin_appeal_resolve',{p_id:+b.dataset.ok,p_accept:true}); toast('Пользователь разблокирован'); load(); }catch(e){ toast(e.message); } }));
      L.querySelectorAll('[data-no]').forEach(b=>b.onclick=()=>modal('Отклонить апелляцию',`<div class="field"><label>Ответ пользователю (необязательно)</label><textarea class="inp" id="aplR" rows="3" maxlength="500" style="resize:none" placeholder="Например: нарушение подтвердилось"></textarea></div>`,
        [['Отмена','ghost'],['Отклонить','danger',async c=>{ const r=$('#aplR').value.trim(); c(); try{ await rpc('lm_admin_appeal_resolve',{p_id:+b.dataset.no,p_accept:false,p_reply:r}); toast('Апелляция отклонена'); load(); }catch(e){ toast(e.message); } }]])); }
    catch(e){ L.innerHTML=adEmpty(esc(e.message)); } };
  V.querySelectorAll('.adchips [data-f]').forEach(b=>b.onclick=()=>{ AD.f.apl=b.dataset.f; V.querySelectorAll('.adchips button').forEach(x=>x.classList.toggle('on',x===b)); load(); });
  await load(); }
