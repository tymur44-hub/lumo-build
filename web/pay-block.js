/* ===== Оплата картой (ЮMoney) прямо из Lumo ===== */
const PAY_RET='https://lumomess.ru/?lumo_paid=1', PAY_RATE=1.7;
const rubF=v=>(Math.abs(v-Math.round(v))<.001?Math.round(v).toLocaleString('ru-RU'):Number(v).toLocaleString('ru-RU',{minimumFractionDigits:2,maximumFractionDigits:2}))+' ₽';
const lpWord=n=>plural(Number(n)||0,'люмен','люмена','люменов');
const PAY_WATCH=new Set();
(function(){ if(document.getElementById('lpcss')) return; const st=document.createElement('style'); st.id='lpcss'; st.textContent=`
.lpov{position:fixed;inset:0;z-index:9000;background:rgba(5,6,18,.55);backdrop-filter:blur(6px);-webkit-backdrop-filter:blur(6px);display:flex;align-items:center;justify-content:center;opacity:0;transition:opacity .2s}
.lpov.on{opacity:1}
.lpsh{width:420px;max-width:calc(100% - 24px);background:var(--bg);color:var(--text);border:1px solid var(--line);border-radius:26px;padding:14px 18px 20px;box-shadow:0 30px 90px rgba(0,0,0,.45);transform:translateY(14px) scale(.97);transition:transform .28s cubic-bezier(.2,.9,.3,1.2)}
.lpov.on .lpsh{transform:none}
.lph{display:flex;align-items:center;gap:10px;position:relative;min-height:38px}
.lpx{width:36px;height:36px;border-radius:50%;background:var(--panel2);display:flex;align-items:center;justify-content:center;flex:none;cursor:pointer;border:0;color:var(--text)}
.lpx svg{width:16px;height:16px;stroke:currentColor;stroke-width:2.4;stroke-linecap:round;fill:none}
.lpt{position:absolute;left:0;right:0;text-align:center;pointer-events:none}.lpt b{display:block;font-size:17px}.lpt span{font-size:12px;color:var(--muted)}
.lpart{height:130px;display:flex;align-items:center;justify-content:center;position:relative}
.lpglow{position:absolute;width:170px;height:170px;border-radius:50%;background:radial-gradient(circle,rgba(255,179,71,.4),transparent 62%);animation:lpgl 3s ease-in-out infinite}
@keyframes lpgl{0%,100%{transform:scale(.92)}50%{transform:scale(1.06)}}
.lpart .g{width:76px;height:76px;filter:drop-shadow(0 6px 20px rgba(255,140,60,.5));animation:lpsw 2.6s ease-in-out infinite}
@keyframes lpsw{0%,100%{transform:rotate(-7deg)}50%{transform:rotate(7deg) scale(1.05)}}
.lpsh h2{margin:4px 0 2px;text-align:center;font-size:23px;font-weight:800}
.lpsum{text-align:center;color:var(--muted);font-size:15px;margin-bottom:16px}
.lpbtn{display:flex;align-items:center;justify-content:center;gap:8px;width:100%;height:52px;border:0;border-radius:16px;background:linear-gradient(135deg,var(--a1),var(--a2));color:#fff;font-weight:800;font-size:16.5px;cursor:pointer;transition:transform .12s,filter .15s}
.lpbtn:hover{filter:brightness(1.08)}.lpbtn:active{transform:scale(.97)}.lpbtn.alt{background:var(--panel2);color:var(--text);font-weight:600;height:46px;margin-top:8px}
.lpnote{display:flex;gap:8px;color:var(--muted);font-size:12.5px;line-height:1.45;margin-top:14px}.lpnote svg{width:17px;height:17px;flex:none;fill:#2bd67b}
.lpspin{width:46px;height:46px;border-radius:50%;border:4px solid var(--panel2);border-top-color:var(--a1);animation:lpsp 1s linear infinite;margin:30px auto 18px}
@keyframes lpsp{to{transform:rotate(360deg)}}
.lpok{width:84px;height:84px;border-radius:50%;margin:24px auto 12px;background:linear-gradient(135deg,#2bd67b,#18a957);display:flex;align-items:center;justify-content:center;animation:lppop .5s cubic-bezier(.2,.9,.3,1.4)}
.lpok svg{width:44px;height:44px;stroke:#fff;stroke-width:3;fill:none;stroke-linecap:round;stroke-linejoin:round}
@keyframes lppop{from{transform:scale(.3);opacity:0}to{transform:none;opacity:1}}
`; document.head.appendChild(st); })();
const lpGem=(c='g')=>`<svg class="${c}" viewBox="0 0 24 24"><defs><linearGradient id="lpgg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#ffe08a"/><stop offset=".5" stop-color="#ff9a3d"/><stop offset="1" stop-color="#ff5e8a"/></linearGradient></defs><polygon points="12,0.48 21.98,6.24 21.98,17.76 12,23.52 2.02,17.76 2.02,6.24" fill="url(#lpgg)" stroke="rgba(255,255,255,.45)" stroke-width="1.08" stroke-linejoin="round"/><polygon points="12,5.04 13.27,10.73 18.96,12 13.27,13.27 12,18.96 10.73,13.27 5.04,12 10.73,10.73" fill="#fff"/></svg>`;
const lpStar=()=>`<svg class="g" viewBox="0 0 24 24"><defs><linearGradient id="lpsg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#c59bff"/><stop offset="1" stop-color="#6a7bff"/></linearGradient></defs><path fill="url(#lpsg)" d="M12 2.5l2.9 6 6.6.9-4.8 4.6 1.2 6.5L12 17.4 6.1 20.5l1.2-6.5L2.5 9.4l6.6-.9z"/></svg>`;
const lpShield='<svg viewBox="0 0 24 24"><path d="M12 2l8 3v6c0 5-3.4 9.4-8 11-4.6-1.6-8-6-8-11V5zm-1.2 13.2l5.7-5.7-1.4-1.4-4.3 4.3-2-2-1.4 1.4z"/></svg>';
async function payFn(body){
  const {data:{session}}=await sb.auth.getSession();
  const r=await fetch(SUPABASE_URL+'/functions/v1/lumo-yoomoney',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+(session?.access_token||''),apikey:SUPABASE_KEY},body:JSON.stringify(body)});
  const j=await r.json().catch(()=>({})); if(!r.ok||!j.url) throw new Error(j.error||'Не удалось создать платёж'); return j;
}
async function payCreate(kind,qty,to){
  try{ const b={action:'create',kind,qty,return_url:PAY_RET}; if(to) b.to=to; const j=await payFn(b); payOpen(j.url,j.order_id,{kind,qty,amount:j.amount,to}); }
  catch(e){ toast(e.message||'Не удалось создать платёж'); }
}
function payWhat(i){ if(!i) return 'Оплата в Lumo'; return i.kind==='prem'?('Lumo Premium на '+i.qty+' мес.'+(i.to?' в подарок':'')):(i.qty+' '+lpWord(i.qty)); }
/** Окно оплаты: в браузере ЮMoney нельзя встроить в страницу, поэтому платёжная форма открывается отдельным окошком поверх Lumo и закрывается сама после оплаты */
function payOpen(url,order,info){
  document.querySelectorAll('.lpov').forEach(x=>x.remove());
  const o=document.createElement('div'); o.className='lpov';
  o.innerHTML=`<div class="lpsh"><div class="lph"><button class="lpx" data-lpx title="Закрыть"><svg viewBox="0 0 24 24"><path d="M6 6l12 12M18 6L6 18"/></svg></button><div class="lpt"><b>Оплата</b><span>Банковская карта · ЮMoney</span></div></div><div class="lpb"></div></div>`;
  document.body.appendChild(o); requestAnimationFrame(()=>o.classList.add('on'));
  const body=o.querySelector('.lpb'); let win=null, timer=null, closed=false;
  const close=()=>{ if(closed) return; closed=true; clearInterval(timer); window.removeEventListener('message',onMsg); try{ win&&!win.closed&&win.close(); }catch{} o.classList.remove('on'); setTimeout(()=>o.remove(),220); };
  const art=()=>`<div class="lpart"><div class="lpglow" ${info&&info.kind==='prem'?'style="background:radial-gradient(circle,rgba(164,139,255,.45),transparent 62%)"':''}></div>${info&&info.kind==='prem'?lpStar():lpGem()}</div>`;
  const ready=()=>{ body.innerHTML=`${art()}<h2>${esc(payWhat(info))}</h2><div class="lpsum">${info&&info.amount?'К оплате: '+rubF(info.amount):'Оплата банковской картой'}</div>
    <button class="lpbtn" data-go>Оплатить картой</button>
    <div class="lpnote">${lpShield}<div>Оплата работает: откроется защищённая форма ЮMoney. После оплаты она закроется сама, а ${info&&info.kind==='prem'?'Premium включится':'люмены зачислятся'} автоматически, обычно за минуту.</div></div>`; };
  const waiting=()=>{ body.innerHTML=`<div class="lpspin"></div><h2>Ожидаем оплату</h2><div class="lpsum">Завершите оплату в окне ЮMoney.<br>Как только деньги поступят, здесь появится подтверждение.</div>
    <button class="lpbtn alt" data-go>Открыть форму оплаты снова</button>`; };
  const done=()=>{ body.innerHTML=`<div class="lpok"><svg viewBox="0 0 24 24"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg></div><h2>Оплата прошла</h2><div class="lpsum">${info&&info.kind==='prem'?(info.to?'Premium подарен':'Lumo Premium активирован'):'Начислено '+(info?info.qty:'')+' '+lpWord(info?info.qty:0)}</div><button class="lpbtn" data-lpx>Готово</button>`; };
  const go=()=>{ const w=480,h=760; const l=Math.max(0,(screen.width-w)/2), t=Math.max(0,(screen.height-h)/2);
    win=window.open(url,'lumopay',`popup=yes,width=${w},height=${h},left=${l},top=${t}`);
    if(!win){ try{ localStorage.setItem('lm_pay_pending',JSON.stringify({order,info,t:Date.now()})); }catch{} location.href=url; return; }
    waiting(); };
  const onMsg=e=>{ if(e&&e.data&&e.data.lumo_paid){ try{ win&&win.close(); }catch{} if(!closed) waiting(); } };
  window.addEventListener('message',onMsg);
  o.addEventListener('click',e=>{ if(e.target===o||e.target.closest('[data-lpx]')) return close(); if(e.target.closest('[data-go]')) go(); });
  ready();
  if(order) timer=setInterval(async()=>{ const st=await payStatus(order); if(st==='paid'){ clearInterval(timer); try{ win&&win.close(); }catch{} if(!closed){ done(); setTimeout(close,3500); } payAfter(info); } else if(st==='unknown') clearInterval(timer); },3000);
}
async function payStatus(order){ try{ const {data}=await sb.rpc('lm_pay_status',{p_order:order}); return data&&data.status; }catch{ return null; } }
async function payAfter(info){
  if(info&&info.kind==='prem'&&!info.to){ try{ await refreshMe(); }catch{} toast('Оплата прошла. Lumo Premium активирован'); try{ renderSettings(); }catch{} }
  else toast(info&&info.kind==='prem'?'Оплата прошла. Premium подарен':'Оплата прошла. Начислено '+(info?info.qty:'')+' '+lpWord(info?info.qty:0));
  try{ window.dispatchEvent(new Event('lumo-paid')); }catch{}
}
/** вернулись в Lumo после оплаты в этой же вкладке */
(function(){ if(!/[?&]lumo_paid\b/.test(location.search)) return;
  try{ if(window.opener&&window.opener!==window){ window.opener.postMessage({lumo_paid:1},'*'); window.close(); } }catch{}
  try{ history.replaceState(null,'',location.pathname); }catch{}
  let p=null; try{ p=JSON.parse(localStorage.getItem('lm_pay_pending')||'null'); localStorage.removeItem('lm_pay_pending'); }catch{}
  setTimeout(()=>toast('Платёж принят. Зачисляем…'),1500);
  if(p&&p.order){ let n=0; const t=setInterval(async()=>{ if(++n>200) return clearInterval(t); const st=await payStatus(p.order); if(st==='paid'||st==='unknown'){ clearInterval(t); if(st==='paid') payAfter(p.info); } },3000); }
})();
window.lumoPay={create:payCreate,open:payOpen,rub:rubF};
async function botCb(mid,data,btn){ if(btn) btn.disabled=true; try{ const {data:{session}}=await sb.auth.getSession(); const r=await fetch(SUPABASE_URL+'/functions/v1/lumo-bots/cb',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+(session?.access_token||''),apikey:SUPABASE_KEY},body:JSON.stringify(/^pay_/.test(data)?{message_id:mid,data,inline:true}:{message_id:mid,data})}); const j=await r.json().catch(()=>({}));
  if(j&&j.pay_url){ const q=/^pay_p(\d+)/.exec(data), l=/^pay_l(\d+)/.exec(data); payOpen(j.pay_url,j.order_id||null,q?{kind:'prem',qty:+q[1],amount:j.amount}:l?{kind:'lum',qty:+l[1],amount:j.amount}:null); }
  else if(j&&j.toast) toast(j.toast); else if(!r.ok) toast('Не удалось выполнить действие'); }catch{ toast('Нет соединения'); } if(btn) btn.disabled=false; }
function bindPremium(){ const me=S.me;
  document.querySelectorAll('[data-pp]').forEach(el=>el.onclick=()=>{ pmPlan=+el.dataset.pp; renderSettings(); });
  const buy=$('#pmBuy'); if(buy) buy.onclick=()=>{ const pl=PM_PLANS[pmPlan]||PM_PLANS[0]; buy.disabled=true; payCreate('prem',pl.m).finally(()=>{ buy.disabled=false; }); };
  const pb=$('#pmBot'); if(pb) pb.onclick=e=>{ e.preventDefault(); openByUsername('lumo_premium'); };
  document.querySelectorAll('[data-pf]').forEach(el=>el.onclick=()=>{ if(!me.premium) return; const k=el.dataset.pf; if(k==='emo') emojiStatusDlg(); else if(k==='px') profExtraDlg(); else if(k==='lock') setSPage('privacy'); else if(k==='look') setSPage('look'); else if(k==='bot') openByUsername('botfather'); });
  if(me.premium) sb.rpc('lm_my_premium').then(({data})=>{ const el=$('#pmSt'); if(!el||!data) return; el.textContent=data.owner?'Вы владелец Lumo — Premium включён навсегда':(data.until?('Premium активен до '+new Date(data.until).toLocaleDateString('ru-RU')):'Premium активен'); }); }
