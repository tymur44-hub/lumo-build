/* ===== TG2: шапка списка чатов как в приложении — «Изм.», стопка историй + «Чаты» + эмодзи-статус, кнопки справа; лента историй раскрывается, если потянуть список вниз ===== */
(function(){
const st2=document.createElement('style'); st2.setAttribute('data-lumo-own','1'); st2.textContent=`
#tghead{display:none;align-items:center;gap:8px;padding:calc(10px + env(safe-area-inset-top)) 14px 4px}
body.tgchats #tghead{display:flex}
body.tgchats #qbox{padding-top:6px!important}
body.tgchats #newBtn{display:none!important}
#tghead .gb{height:42px;border-radius:21px;background:var(--panel2);border:1px solid var(--line);display:flex;align-items:center;justify-content:center;color:var(--text);flex:none}
#tghead .ed{padding:0 16px;font-weight:700;font-size:16px}
#tghead .mid{flex:1;min-width:0;display:flex;align-items:center;justify-content:center;gap:6px}
#tghead .mid b{font-size:19px;font-weight:800;white-space:nowrap}
#tghead .pair{padding:0 4px}#tghead .pair button{width:40px;height:42px;display:grid;place-items:center;color:var(--text)}
#tghead .pair svg,#tghead .cmp svg{width:21px;height:21px}
#tghead .cmp{width:44px;height:44px;border-radius:50%;background:var(--a1);color:#fff;display:grid;place-items:center;flex:none;border:0}
#tghead .stk{display:flex;align-items:center;cursor:pointer;transition:transform .3s cubic-bezier(.2,.9,.3,1.2),opacity .25s}
#tghead .stk>*{margin-left:-12px;border-radius:50%;padding:2px;background:var(--bg)}
#tghead .stk>*:first-child{margin-left:0}
#tghead .stk .av{width:30px!important;height:30px!important;min-width:30px;font-size:12px}
#tghead .stk .cnt{width:30px;height:30px;border-radius:50%;display:grid;place-items:center;color:#fff;font-weight:800;font-size:13px;background:linear-gradient(180deg,#6fb8ff,var(--a1));box-sizing:content-box}
body.tgstopen #tghead .stk{transform:scale(.4);opacity:0;pointer-events:none;width:0;margin:0}
#list>.stbar{max-height:0;opacity:0;overflow:hidden;padding-top:0;padding-bottom:0;transform:translateY(-12px);transition:max-height .38s cubic-bezier(.2,.9,.3,1),opacity .28s,transform .38s cubic-bezier(.2,.9,.3,1),padding .38s}
body.tgstopen #list>.stbar{max-height:120px;opacity:1;transform:none;padding-top:6px;padding-bottom:10px;overflow-x:auto}
#tghead .tgemo{margin-left:0}
`; document.head.appendChild(st2);

const qb=document.getElementById('qbox'); if(!qb) return;
const hd=document.createElement('div'); hd.id='tghead';
hd.innerHTML=`<button class="gb ed" data-h="ed">Изм.</button><div class="mid"><span class="stk" data-h="stk"></span><b>Чаты</b><span class="emo" data-h="emo"></span></div><div class="gb pair"><button data-h="add" title="Новая история">${ic('plus')}</button></div><button class="cmp" data-h="new" title="Новый чат">${ic('edit')}</button>`;
qb.parentNode.insertBefore(hd,qb);
hd.addEventListener('click',e=>{ const b=e.target.closest('[data-h]'); if(!b) return; e.stopPropagation(); const k=b.dataset.h;
  if(k==='new'||k==='ed'){ dropMenu(b,[['user','Новый личный чат',()=>{ $('#q').focus(); toast('Введите имя или @юзернейм в поиске'); }],['users','Новая группа',()=>newChatFlow('group')],['mega','Новый канал',()=>newChatFlow('channel')],['clock','Архив историй',()=>{ const r=document.createElement('div'); r.id='tgSArc'; r.style.display='none'; document.body.appendChild(r); r.click(); r.remove(); }]],'down'); }
  else if(k==='add') addStory();
  else if(k==='emo'){ if(S.me&&S.me.premium) emojiStatusDlg(); }
  else if(k==='stk'){ const o=storyOrder(); const g=o.find(x=>x.uid!==S.me.id&&x.unseen)||o[0]; if(g) openStories(g.uid); } });

const setOpen=v=>{ if(document.body.classList.contains('tgstopen')===v) return; document.body.classList.toggle('tgstopen',v); if(v&&navigator.vibrate) try{ navigator.vibrate(8); }catch(e){} };
let lastStk='', lastEmo='';
function sync(){ if(!S||!S.me) return; const on=S.tab==='chats'&&!S.q; document.body.classList.toggle('tgchats',S.tab==='chats');
  if(!on) setOpen(false);
  const o=storyOrder().slice().sort((a,b)=>(a.uid===S.me.id?-1:b.uid===S.me.id?1:0)||((b.unseen?1:0)-(a.unseen?1:0)));
  const sh=o.length?(o.length>2?`<span class="cnt">${o.length}</span>`:'')+o.slice(0,2).map(g=>avatar({name:g.name,avatar:g.avatar_url,color:g.color},'xs')).join(''):'';
  if(sh!==lastStk){ lastStk=sh; hd.querySelector('[data-h=stk]').innerHTML=sh; }
  const eh=S.me.premium?(S.me.emoji_status?emoHtml(S.me.emoji_status):`<span style="color:var(--a1);display:grid">${ic('star','f')}</span>`):'';
  if(eh!==lastEmo){ lastEmo=eh; hd.querySelector('[data-h=emo]').innerHTML=eh; } }
setInterval(sync,700);

// потянуть вниз у верхнего края — раскрыть ленту; прокрутить вниз — свернуть
let ty=null, acc=0;
const L=()=>document.getElementById('list');
document.addEventListener('wheel',e=>{ const l=L(); if(!l||!l.contains(e.target)||S.tab!=='chats') return;
  if(e.deltaY<0&&l.scrollTop<=0){ acc+=-e.deltaY; if(acc>60){ acc=0; setOpen(true); } }
  else if(e.deltaY>0){ acc=0; if(document.body.classList.contains('tgstopen')&&l.scrollTop<=4) setOpen(false); } },{passive:true});
document.addEventListener('touchstart',e=>{ const l=L(); ty=(l&&l.contains(e.target)&&l.scrollTop<=0)?e.touches[0].clientY:null; },{passive:true});
document.addEventListener('touchmove',e=>{ if(ty===null) return; const dy=e.touches[0].clientY-ty; if(dy>70){ ty=null; setOpen(true); } else if(dy<-24){ ty=null; setOpen(false); } },{passive:true});
document.addEventListener('scroll',e=>{ if(e.target&&e.target.id==='list'&&e.target.scrollTop>40) setOpen(false); },true);
})();
