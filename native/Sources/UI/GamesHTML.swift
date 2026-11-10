// Сгенерировано web/build_games.py — страница игр вдвоём
let gamesHTML = #"""
<!doctype html>
<html lang="ru"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no,viewport-fit=cover">
<title>Игра</title>
<style>
:root{--bg:#0c0d1a;--panel:#15162c;--panel2:#1d1f3b;--line:rgba(255,255,255,.08);--text:#eef0ff;--muted:#8d90b8;--a1:#7c5cff;--a2:#22c1ff;--danger:#ff5b7a;--ok:#2bd67b;--gold:#f5b942;--cell:#23264a;--cell2:#2c2f58}
.light{--bg:#f6f5ff;--panel:#ffffff;--panel2:#efeefe;--line:rgba(20,20,60,.09);--text:#191a33;--muted:#6d6f93;--cell:#e9e7fb;--cell2:#d9d5f6}
*{box-sizing:border-box;-webkit-tap-highlight-color:transparent}
html,body{margin:0;height:100%;background:var(--bg);color:var(--text);font-family:-apple-system,BlinkMacSystemFont,"SF Pro Text",Roboto,"Segoe UI",Manrope,system-ui,sans-serif;overscroll-behavior:none;-webkit-user-select:none;user-select:none}
#app{min-height:100%;display:flex;flex-direction:column;padding:calc(env(safe-area-inset-top) + 10px) 16px calc(env(safe-area-inset-bottom) + 16px);max-width:560px;margin:0 auto}
.top{display:flex;align-items:center;gap:10px}
.top h1{flex:1;margin:0;font-size:18px;font-weight:800;text-align:center}
.ib{width:40px;height:40px;border-radius:50%;border:0;background:var(--panel);color:var(--text);display:grid;place-items:center;cursor:pointer;flex:none}
.ib svg{width:20px;height:20px}
.chip{display:inline-flex;align-items:center;gap:6px;padding:6px 11px;border-radius:999px;background:var(--panel);font-size:13px;font-weight:700;color:var(--gold)}
.chip svg{width:15px;height:15px}
.players{display:flex;align-items:center;gap:10px;margin-top:16px}
.pl{flex:1;min-width:0;display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:16px;background:var(--panel);border:2px solid transparent;transition:border-color .25s,box-shadow .25s}
.pl.r{flex-direction:row-reverse;text-align:right}
.pl.on{border-color:var(--a1);box-shadow:0 0 0 4px color-mix(in srgb,var(--a1) 18%,transparent)}
.pl .av{width:36px;height:36px;border-radius:50%;display:grid;place-items:center;font-weight:800;color:#fff;flex:none;background:linear-gradient(135deg,var(--a1),var(--a2))}
.pl .av.o{background:linear-gradient(135deg,#ff8a5b,#ff5b8a)}
.pl b{display:block;font-size:14px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.pl span{display:block;font-size:12px;color:var(--muted)}
.pl .mk{width:22px;height:22px;flex:none}
.vs{font-size:12px;font-weight:800;color:var(--muted)}
.status{margin:14px 0 4px;text-align:center;font-size:15px;font-weight:700;min-height:22px}
.status.me{color:var(--a1)}
.board-wrap{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;padding:8px 0}
/* крестики-нолики */
.ttt{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));grid-template-rows:repeat(3,minmax(0,1fr));gap:8px;width:min(86vw,340px);height:min(86vw,340px)}
.ttt button{border:0;border-radius:18px;background:var(--panel);display:block;position:relative;cursor:pointer;padding:0;min-width:0;min-height:0;width:100%;height:100%;overflow:hidden;transition:transform .12s,background .2s}
.ttt button:active{transform:scale(.95)}
.ttt button.win{background:color-mix(in srgb,var(--a1) 26%,var(--panel))}
.ttt svg{position:absolute;left:18%;top:18%;width:64%;height:64%;overflow:visible}
.ttt .x line,.mk.x line{stroke:var(--a2);stroke-width:12;stroke-linecap:round}
.ttt .o circle,.mk.o circle{stroke:#ff6f8e;stroke-width:12;fill:none}
.mk.x line,.mk.o circle{stroke-width:14}
.draw line,.draw circle{stroke-dasharray:140;stroke-dashoffset:140;animation:dr .35s ease forwards}
.draw line+line{animation-delay:.15s}
@keyframes dr{to{stroke-dashoffset:0}}
/* шашки */
.ck{display:grid;grid-template-columns:repeat(8,1fr);width:min(94vw,440px);aspect-ratio:1;border-radius:14px;overflow:hidden;box-shadow:0 10px 30px rgba(0,0,0,.25)}
.ck div{position:relative;display:grid;place-items:center}
.ck .l{background:#e9dcc3}.ck .d{background:#8a5a3b}
.light .ck .l{background:#f1e6d0}.light .ck .d{background:#9b6a48}
.ck .d.hl{background:#a7743f}.ck .d.last{box-shadow:inset 0 0 0 3px rgba(255,214,102,.55)}
.ck .dot{position:absolute;width:30%;height:30%;border-radius:50%;background:rgba(124,92,255,.85);box-shadow:0 0 0 4px rgba(124,92,255,.25)}
.pc{width:78%;height:78%;border-radius:50%;display:grid;place-items:center;transition:transform .15s;box-shadow:0 3px 0 rgba(0,0,0,.35),inset 0 -3px 6px rgba(0,0,0,.18),inset 0 3px 5px rgba(255,255,255,.35)}
.pc.w{background:radial-gradient(circle at 35% 30%,#ffffff,#e4e1d6)}
.pc.b{background:radial-gradient(circle at 35% 30%,#4b4b57,#17171d)}
.pc.sel{transform:scale(1.1);box-shadow:0 0 0 3px var(--a1),0 6px 12px rgba(0,0,0,.35)}
.pc.can{animation:pul 1.6s ease-in-out infinite}
@keyframes pul{50%{box-shadow:0 0 0 3px rgba(124,92,255,.55),0 3px 0 rgba(0,0,0,.35)}}
.pc svg{width:58%;height:58%}
.pc.w svg{color:#b8892e}.pc.b svg{color:#f5c451}
/* морской бой */
.seaT{font-size:13px;font-weight:700;color:var(--muted);margin:6px 0;align-self:flex-start;width:min(92vw,400px);margin-left:auto;margin-right:auto}
.sea{display:grid;grid-template-columns:repeat(10,1fr);gap:3px;width:min(92vw,400px);aspect-ratio:1}
.sea.sm{width:min(60vw,250px);gap:2px}
.sea div{border-radius:5px;background:var(--cell);position:relative;display:grid;place-items:center}
.sea.big div.t{cursor:pointer}.sea.big div.t:hover{background:var(--cell2)}
.sea div.sh{background:color-mix(in srgb,var(--a1) 55%,var(--cell))}
.sea div.hit{background:#ff6f5b}.sea div.sunk{background:#b8344d}
.sea div.miss::after{content:"";width:22%;height:22%;border-radius:50%;background:var(--muted);opacity:.7}
.sea div.hit::after,.sea div.sunk::after{content:"";width:46%;height:46%;background:linear-gradient(45deg,transparent 42%,#fff 42%,#fff 58%,transparent 58%),linear-gradient(-45deg,transparent 42%,#fff 42%,#fff 58%,transparent 58%)}
/* --- живые эффекты --- */
.ttt{position:relative}
.ttt .wl{position:absolute;left:0;top:0;width:100%;height:100%;pointer-events:none;overflow:visible;z-index:2}
.wl line{stroke:#fff;stroke-width:10;stroke-linecap:round;filter:drop-shadow(0 0 8px rgba(255,255,255,.7));stroke-dasharray:1000;stroke-dashoffset:1000}
.wl.go line{animation:wl .45s cubic-bezier(.3,.7,.3,1) .15s forwards}.wl.done line{stroke-dashoffset:0}
@keyframes wl{to{stroke-dashoffset:0}}
.ttt button:active{transform:scale(.94)}
.pc.ghost{position:absolute;left:11%;top:11%;pointer-events:none}
#fx{position:fixed;inset:0;pointer-events:none;z-index:7;overflow:hidden}
#fx .sh{position:absolute;width:16px;height:16px;margin:-8px 0 0 -8px;border-radius:50%;background:radial-gradient(circle at 35% 30%,#fff,#9aa3b5 45%,#3a4252);box-shadow:0 4px 10px rgba(0,0,0,.45)}
#fx .rp{position:absolute;border:2px solid rgba(160,210,255,.9);border-radius:50%}
#fx .pt{position:absolute;width:7px;height:7px;margin:-3.5px 0 0 -3.5px;border-radius:50%}
#fx .fl{position:absolute;border-radius:50%;background:radial-gradient(circle,#fff 0,#ffd27a 30%,rgba(255,110,40,.6) 55%,rgba(255,80,20,0) 72%)}
.sea div.new::after{animation:pop .4s ease .34s both}
.sea div.new.hit,.sea div.new.sunk{animation:hitbg .45s ease .34s both}
@keyframes hitbg{0%{background:var(--cell)}}
.shake{animation:shk .45s cubic-bezier(.36,.07,.19,.97)}
@keyframes shk{10%,90%{transform:translateX(-1px)}20%,80%{transform:translateX(3px)}30%,50%,70%{transform:translateX(-5px)}40%,60%{transform:translateX(5px)}}
@keyframes pop{0%{transform:scale(.4);opacity:0}60%{transform:scale(1.15)}100%{transform:none}}
/* кнопки */
.acts{display:flex;gap:10px;margin-top:14px}
.btn{flex:1;height:52px;border:0;border-radius:16px;font:inherit;font-size:16px;font-weight:800;cursor:pointer;display:flex;align-items:center;justify-content:center;gap:8px;color:#fff;background:linear-gradient(135deg,var(--a1),var(--a2));transition:transform .12s,opacity .2s}
.btn:active{transform:scale(.97)}.btn[disabled]{opacity:.5}
.btn.ghost{background:var(--panel);color:var(--text)}.btn.red{background:var(--panel);color:var(--danger)}
.btn svg{width:20px;height:20px}
.res{margin-top:14px;padding:16px;border-radius:18px;text-align:center;background:var(--panel);animation:pop .45s ease}
.res b{display:block;font-size:22px}.res span{display:block;margin-top:4px;color:var(--muted);font-size:14px}
.res.win{background:linear-gradient(135deg,color-mix(in srgb,var(--a1) 30%,var(--panel)),color-mix(in srgb,var(--a2) 22%,var(--panel)))}
.err{position:fixed;left:50%;bottom:calc(env(safe-area-inset-bottom) + 24px);transform:translateX(-50%) translateY(20px);background:#1b1c30;color:#fff;padding:11px 16px;border-radius:14px;font-size:14px;opacity:0;transition:.25s;max-width:90vw;text-align:center;pointer-events:none;z-index:9}
.err.on{opacity:1;transform:translateX(-50%)}
.load{flex:1;display:grid;place-items:center;color:var(--muted)}
.sp{width:28px;height:28px;border:3px solid var(--line);border-top-color:var(--a1);border-radius:50%;animation:sp .8s linear infinite}
@keyframes sp{to{transform:rotate(360deg)}}
.ask{position:fixed;inset:0;background:rgba(0,0,0,.45);display:flex;align-items:flex-end;justify-content:center;padding:16px;opacity:0;transition:opacity .25s;z-index:8}
.ask.on{opacity:1}.askb{width:100%;max-width:420px;background:var(--panel);border-radius:22px;padding:18px;transform:translateY(30px);transition:transform .3s cubic-bezier(.2,.9,.3,1);margin-bottom:env(safe-area-inset-bottom)}
.ask.on .askb{transform:none}.askb b{display:block;font-size:18px}.askb span{display:block;color:var(--muted);margin-top:4px;font-size:14px}
.hint{text-align:center;color:var(--muted);font-size:13px;margin-top:8px}
</style></head>
<body><div id="app"><div class="load"><div class="sp"></div></div></div><div class="err" id="err"></div>
<script>
/*CFG*/
(function(){
var C=window.LUMO_GAME||{}; if(C.theme==='light') document.documentElement.classList.add('light');
var G=null, busy=false, sel=null, partial=[], lastVer=-1, timer=null, prevShots=0;
var $=function(q){return document.querySelector(q)};
var TITLES={ttt:'Крестики-нолики',checkers:'Шашки',sea:'Морской бой'};
var I={x:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><path d="M6 6l12 12M18 6 6 18"/></svg>',
 gem:'<svg viewBox="0 0 24 24" fill="currentColor"><path d="M6.5 3h11l4 6-9.5 12L2.5 9z" opacity=".9"/><path d="M2.5 9h19M9 3l3 6 3-6M12 9v12" stroke="#fff" stroke-opacity=".35" stroke-width="1" fill="none"/></svg>',
 crown:'<svg viewBox="0 0 24 24" fill="currentColor"><path d="M3 7l4.5 4L12 4l4.5 7L21 7l-2 12H5z"/></svg>',
 flag:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 21V4M5 4h11l-2 4 2 4H5"/></svg>',
 shuffle:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 3h5v5M4 20 21 3M21 16v5h-5M15 15l6 6M4 4l5 5"/></svg>',
 check:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.5l4.5 4.5L19 7"/></svg>',
 play:'<svg viewBox="0 0 24 24" fill="currentColor"><path d="M7 4.5v15l13-7.5z"/></svg>'};
function esc(s){return String(s==null?'':s).replace(/[&<>"]/g,function(c){return{'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]})}
function toast(t){var e=$('#err');e.textContent=t;e.classList.add('on');clearTimeout(e._t);e._t=setTimeout(function(){e.classList.remove('on')},2600)}
function ask(t,sub,yes,fn){ var o=document.createElement('div'); o.className='ask'; o.innerHTML='<div class="askb"><b>'+esc(t)+'</b><span>'+esc(sub)+'</span><div class="acts"><button class="btn ghost" data-n>Отмена</button><button class="btn" style="background:var(--danger)" data-y>'+esc(yes)+'</button></div></div>';
  document.body.appendChild(o); requestAnimationFrame(function(){o.classList.add('on')});
  var done=function(){ o.classList.remove('on'); setTimeout(function(){o.remove()},250); };
  o.onclick=function(e){ if(e.target===o||e.target.hasAttribute('data-n')) done(); if(e.target.hasAttribute('data-y')){ done(); fn(); } }; }
function close(){ try{ if(window.webkit&&webkit.messageHandlers&&webkit.messageHandlers.lumo) return webkit.messageHandlers.lumo.postMessage('close'); }catch(e){}
  try{ if(window.LumoBridge) return LumoBridge.leave(); }catch(e){} try{ parent.postMessage({lumoGame:'close'},'*'); }catch(e){} }
function lum(n){var m=n%10,mm=n%100;return n+' '+(m===1&&mm!==11?'люмен':m>=2&&m<=4&&(mm<10||mm>=20)?'люмена':'люменов')}
function api(body){ return fetch(C.api,{method:'POST',headers:{'Content-Type':'application/json',apikey:C.apikey||'',Authorization:'Bearer '+C.token},body:JSON.stringify(body)})
  .then(function(r){ return r.json().then(function(j){ if(r.status===401) throw new Error('Сессия устарела — закройте и откройте игру заново'); if(j.error) throw new Error(j.error); return j; }); }); }
function act(body){ if(busy) return; busy=true; body.game_id=C.gameId; return api(body).then(function(g){ busy=false; set(g); }).catch(function(e){ busy=false; toast(e.message); poll(); }); }
function set(g){ G=g; lastVer=g.ver; render(); }
function poll(){ if(document.hidden||busy) return; api({action:'get',game_id:C.gameId}).then(function(g){ if(g.ver!==lastVer||!G) set(g); }).catch(function(e){ if(!G) $('#app').innerHTML='<div class="load">'+esc(e.message)+'</div>'; }); }
function startPoll(){ clearInterval(timer); timer=setInterval(poll,1500); }
document.addEventListener('visibilitychange',function(){ if(!document.hidden) poll(); });
window.lumoToken=function(t){ C.token=t; };

function me(){return G.me} function iAmP1(){return G.me===G.p1} function player(){return G.me===G.p1||G.me===G.p2}
function oppName(){return iAmP1()?G.p2n:G.p1n}
function statusText(){
  var g=G;
  if(g.status==='invite') return g.me===g.p1?'Ждём соперника…':'Вас приглашают сыграть';
  if(g.status==='declined') return 'Приглашение отклонено';
  if(g.status==='canceled') return 'Игра отменена';
  if(g.status==='setup') return (g.state.ready||{})[g.me]?'Ждём, пока соперник расставит корабли':player()?'Расставьте корабли':'Игроки расставляют корабли';
  if(g.status==='done') return '';
  if(!player()) return 'Ходит '+(g.turn===g.p1?g.p1n:g.p2n);
  return g.turn===g.me?'Ваш ход':'Ход соперника';
}
function mark(kind,isP1){ if(kind==='ttt') return isP1?'<svg class="mk x" viewBox="0 0 100 100"><line x1="20" y1="20" x2="80" y2="80"/><line x1="80" y1="20" x2="20" y2="80"/></svg>':'<svg class="mk o" viewBox="0 0 100 100"><circle cx="50" cy="50" r="32"/></svg>';
  if(kind==='checkers') return '<span class="pc '+(isP1?'w':'b')+'" style="width:22px;height:22px;flex:none"></span>'; return ''; }
function head(){
  var g=G, t1=g.status==='active'&&g.turn===g.p1, t2=g.status==='active'&&g.turn===g.p2;
  var p=function(id,nm,on,cls,isP1){ return '<div class="pl '+cls+(on?' on':'')+'"><div class="av'+(isP1?'':' o')+'">'+esc((nm||'?').charAt(0).toUpperCase())+'</div><div style="min-width:0;flex:1"><b>'+esc(nm||'Ожидание…')+'</b><span>'+(id===g.me?'Вы':g.status==='done'&&g.winner===id?'Победитель':isP1?'Создал игру':'Соперник')+'</span></div>'+mark(g.kind,isP1)+'</div>'; };
  return '<div class="top"><button class="ib" id="gX" title="Закрыть">'+I.x+'</button><h1>'+TITLES[g.kind]+'</h1>'+(g.stake?'<span class="chip" title="Ставка каждого игрока">'+I.gem+g.stake+'</span>':'<span style="width:40px"></span>')+'</div>'+
   '<div class="players">'+p(g.p1,g.p1n,t1,'',true)+'<span class="vs">VS</span>'+p(g.p2,g.p2n,t2,'r',false)+'</div>'+
   '<div class="status'+(g.status==='active'&&g.turn===g.me?' me':'')+'">'+esc(statusText())+'</div>';
}
function result(){
  var g=G; if(g.status!=='done') return '';
  var bank=g.stake*2, win=g.winner===g.me, why={resign:' — соперник сдался',timeout:' — соперник не ходил больше суток',no_moves:'',fleet:'',line:''}[g.result]||'';
  if(!g.winner) return '<div class="res"><b>Ничья</b><span>'+(g.stake?'Ставки вернулись игрокам':'Хорошая партия')+'</span></div>';
  if(!player()) return '<div class="res"><b>Победил(а) '+esc(g.winner===g.p1?g.p1n:g.p2n)+'</b>'+(g.stake?'<span>Выигрыш: '+lum(bank)+'</span>':'')+'</div>';
  if(win) return '<div class="res win"><b>Вы победили'+(g.result==='resign'?'':'!')+'</b><span>'+(g.stake?'Выигрыш: +'+lum(bank):'Отличная игра')+esc(g.result==='resign'||g.result==='timeout'?why:'')+'</span></div>';
  return '<div class="res"><b>Победил(а) '+esc(oppName())+'</b><span>'+(g.stake?'Ставка ушла сопернику':'В следующий раз получится')+'</span></div>';
}
function actions(){
  var g=G, h='';
  if(g.status==='invite'){
    if(g.me===g.p1) h='<button class="btn red" data-a="cancel">Отменить'+(g.stake?' и вернуть ставку':'')+'</button>';
    else h='<button class="btn ghost" data-a="decline">Отклонить</button><button class="btn" data-a="join">'+I.play+(g.stake?'Принять · '+g.stake:'Принять')+'</button>';
  } else if(g.status==='setup'&&player()&&!(g.state.ready||{})[g.me]){
    h='<button class="btn ghost" data-a="shuffle">'+I.shuffle+'Перемешать</button><button class="btn" data-a="ready">'+I.check+'Готов</button>';
  } else if((g.status==='active'||g.status==='setup')&&player()){
    var stale=g.status==='active'&&g.turn!==g.me&&Date.now()-new Date(g.updated_at).getTime()>864e5;
    h=(stale?'<button class="btn" data-a="claim">Забрать победу</button>':'')+'<button class="btn red" data-a="resign">'+I.flag+'Сдаться</button>';
  } else if(g.status!=='active') h='<button class="btn ghost" id="gDone">Закрыть</button>';
  return h?'<div class="acts">'+h+'</div>':'';
}
function render(){
  var g=G, body='';
  if(g.kind==='ttt') body=renderTTT(); else if(g.kind==='checkers') body=renderCk(); else body=renderSea();
  var stakeHint=g.status==='invite'&&g.stake?'<div class="hint">Каждый игрок ставит '+lum(g.stake)+'. Победитель забирает '+lum(g.stake*2)+', при ничьей ставки возвращаются.</div>':'';
  $('#app').innerHTML=head()+'<div class="board-wrap">'+body+'</div>'+result()+stakeHint+actions();
  $('#gX').onclick=close; var d=$('#gDone'); if(d) d.onclick=close;
  [].forEach.call(document.querySelectorAll('[data-a]'),function(b){ b.onclick=function(){ var a=b.dataset.a;
    if(a==='resign') return ask('Сдаться?',G.stake?'Ставка уйдёт сопернику.':'Победа достанется сопернику.','Сдаться',function(){ act({action:'resign'}); });
    act({action:a}); }; });
  bind();
  try{ fx(); }catch(e){}
}
/* ---- живые эффекты: движение шашек, линия победы, выстрелы ---- */
var fxCkBoard=null, fxCkKey=null, fxSeaKey=null, fxTttWin=null;
function fxLayer(){ var l=document.getElementById('fx'); if(!l){ l=document.createElement('div'); l.id='fx'; document.body.appendChild(l); } return l; }
function rnd(a,b){ return a+Math.random()*(b-a); }
function fx(){ if(G.kind==='checkers') fxCk(); else if(G.kind==='sea') fxSea(); else fxTtt(); }
function fxTtt(){
  var b=G.state.board, L=[[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]], w=null;
  L.forEach(function(l){ if(b[l[0]]!=='.'&&b[l[0]]===b[l[1]]&&b[l[0]]===b[l[2]]) w=l; });
  var box=document.querySelector('.ttt'); if(!w||!box) return;
  var cells=box.querySelectorAll('button'), br=box.getBoundingClientRect();
  var c=function(i){ var e=cells[i]; return [e.offsetLeft+e.offsetWidth/2, e.offsetTop+e.offsetHeight/2]; }; br={width:box.clientWidth,height:box.clientHeight};
  var a=c(w[0]), z=c(w[2]), dx=z[0]-a[0], dy=z[1]-a[1], len=Math.hypot(dx,dy)||1, ex=dx/len*28, ey=dy/len*28;
  var key=w.join(','), fresh=fxTttWin!==key; fxTttWin=key;
  box.insertAdjacentHTML('beforeend','<svg class="wl '+(fresh?'go':'done')+'" viewBox="0 0 '+br.width+' '+br.height+'"><line x1="'+(a[0]-ex)+'" y1="'+(a[1]-ey)+'" x2="'+(z[0]+ex)+'" y2="'+(z[1]+ey)+'"/></svg>');
}
function ckCell(p){ return document.querySelector('.ck [data-r="'+p[0]+'"][data-c="'+p[1]+'"]'); }
function fxCk(){
  var b=G.state.board, last=G.state.last||[], key=JSON.stringify(last);
  if(fxCkKey===null){ fxCkKey=key; fxCkBoard=b; return; }   // первый показ — без анимации
  if(key===fxCkKey){ fxCkBoard=b; return; }
  var prev=fxCkBoard; fxCkKey=key; fxCkBoard=b;
  if(last.length<2) return;
  var dest=ckCell(last[last.length-1]), pc=dest&&dest.querySelector('.pc'); if(!pc) return;
  var dr=dest.getBoundingClientRect(), seg=last.length-1, frames=[];
  var pos=function(p){ var r=ckCell(p).getBoundingClientRect(); return [r.left-dr.left, r.top-dr.top]; };
  for(var i=0;i<seg;i++){
    var A=pos(last[i]), B=pos(last[i+1]), jump=Math.abs(last[i+1][0]-last[i][0])>1;
    frames.push({offset:i/seg, transform:'translate('+A[0]+'px,'+A[1]+'px) scale(1)', boxShadow:'0 3px 0 rgba(0,0,0,.35)'});
    frames.push({offset:(i+.5)/seg, transform:'translate('+((A[0]+B[0])/2)+'px,'+((A[1]+B[1])/2-(jump?14:6))+'px) scale('+(jump?1.22:1.1)+')', boxShadow:'0 14px 14px rgba(0,0,0,.35)'});
  }
  frames.push({offset:1, transform:'translate(0,0) scale(1)', boxShadow:'0 3px 0 rgba(0,0,0,.35)'});
  var D=Math.min(1600, 300*seg+80);
  pc.style.zIndex=3; pc.style.position='relative';
  var an=pc.animate(frames,{duration:D,easing:'cubic-bezier(.35,.1,.25,1)'}); an.onfinish=function(){ pc.style.zIndex=''; };
  // приземление: лёгкая отдача
  setTimeout(function(){ pc.animate([{transform:'scale(1.08,.92)'},{transform:'scale(1)'}],{duration:180,easing:'ease-out'}); },D);
  // сбитые шашки: исчезают в момент, когда через них перепрыгнули
  if(prev){ var from=last[0][0]*8+last[0][1];
    for(var i2=0;i2<seg;i2++){ var a2=last[i2], z2=last[i2+1], dr2=Math.sign(z2[0]-a2[0]), dc2=Math.sign(z2[1]-a2[1]);
      for(var r=a2[0]+dr2,c=a2[1]+dc2;r!==z2[0];r+=dr2,c+=dc2){ var idx=r*8+c; if(idx===from||prev[idx]==='.'||b[idx]!=='.') continue;
        (function(cell,ch,delay){ if(!cell) return; var g=document.createElement('span'); g.className='pc ghost '+ch.toLowerCase(); if(ch===ch.toUpperCase()) g.innerHTML=I.crown; cell.appendChild(g);
          var rot=rnd(-40,40); g.animate([{opacity:1,transform:'scale(1)'},{opacity:1,transform:'scale(1.12) translateY(-4px)',offset:.25},{opacity:0,transform:'scale(.2) translateY(-30px) rotate('+rot+'deg)'}],{duration:520,delay:delay,easing:'cubic-bezier(.4,0,.6,1)',fill:'both'}).onfinish=function(){ g.remove(); };
        })(ckCell([r,c]), prev[idx], (i2+.5)/seg*D);
      } } }
}
function seaCellEl(big,x,y){ return document.querySelector('.sea.'+(big?'big':'sm')+' [data-x="'+x+'"][data-y="'+y+'"]'); }
function fxSea(){
  var l=G.state.last, key=l?l.by+':'+l.x+':'+l.y+':'+((G.state.shots||{})[l.by]||[]).length:'';
  if(fxSeaKey===null){ fxSeaKey=key; return; } if(!l||key===fxSeaKey) return; fxSeaKey=key;
  var mine=l.by===G.me, cell=seaCellEl(mine,l.x,l.y); if(!cell) return;
  var r=cell.getBoundingClientRect(), cx=r.left+r.width/2, cy=r.top+r.height/2, L=fxLayer();
  // снаряд летит по дуге
  var sh=document.createElement('div'); sh.className='sh'; L.appendChild(sh);
  var sx=mine?innerWidth/2:cx+rnd(-40,40), sy=mine?innerHeight+20:-30;
  var T=360, k=[]; for(var i=0;i<=10;i++){ var t=i/10, x=sx+(cx-sx)*t, y=sy+(cy-sy)*t-Math.sin(t*Math.PI)*(mine?120:40); k.push({transform:'translate('+x+'px,'+y+'px) scale('+(mine?1.8-1.2*t:0.8+0.2*t)+')',offset:t}); }
  sh.animate(k,{duration:T,easing:'cubic-bezier(.45,.05,.55,.95)',fill:'both'}).onfinish=function(){ sh.remove(); boom(); };
  function boom(){
    if(l.h){
      var big=!!l.sunk, n=big?22:14;
      var f=document.createElement('div'); f.className='fl'; var fs=big?110:70; f.style.left=(cx-fs/2)+'px'; f.style.top=(cy-fs/2)+'px'; f.style.width=f.style.height=fs+'px'; L.appendChild(f);
      f.animate([{opacity:1,transform:'scale(.2)'},{opacity:.95,transform:'scale(1)',offset:.35},{opacity:0,transform:'scale(1.35)'}],{duration:big?650:480,easing:'ease-out'}).onfinish=function(){ f.remove(); };
      for(var i=0;i<n;i++){ var p=document.createElement('div'); p.className='pt'; var ang=rnd(0,Math.PI*2), sp=rnd(30,big?110:70), col=['#fff3b0','#ffb347','#ff6f3c','#5b5b66'][i%4]; p.style.background=col; p.style.left=cx+'px'; p.style.top=cy+'px'; L.appendChild(p);
        var dx=Math.cos(ang)*sp, dy=Math.sin(ang)*sp; p.animate([{transform:'translate(0,0) scale(1)',opacity:1},{transform:'translate('+dx*.6+'px,'+(dy*.6-10)+'px) scale(.9)',opacity:1,offset:.5},{transform:'translate('+dx+'px,'+(dy+40)+'px) scale(.3)',opacity:0}],{duration:rnd(500,big?1000:750),easing:'cubic-bezier(.2,.7,.4,1)'}).onfinish=function(){ this.effect.target.remove(); }; }
      var grid=cell.parentNode; grid.classList.remove('shake'); void grid.offsetWidth; grid.classList.add('shake');
      try{ navigator.vibrate&&navigator.vibrate(big?[30,40,30]:25); }catch(e){}
    } else {
      for(var j=0;j<3;j++){ var rp=document.createElement('div'); rp.className='rp'; rp.style.left=(cx-r.width/2)+'px'; rp.style.top=(cy-r.width/2)+'px'; rp.style.width=rp.style.height=r.width+'px'; L.appendChild(rp);
        rp.animate([{opacity:.9,transform:'scale(.3)'},{opacity:0,transform:'scale(2.4)'}],{duration:700,delay:j*120,easing:'ease-out',fill:'both'}).onfinish=function(){ this.effect.target.remove(); }; }
      for(var q=0;q<8;q++){ var d=document.createElement('div'); d.className='pt'; d.style.background='rgba(170,215,255,.95)'; d.style.left=cx+'px'; d.style.top=cy+'px'; L.appendChild(d);
        var a3=rnd(Math.PI*1.1,Math.PI*1.9), s3=rnd(14,34); d.animate([{transform:'translate(0,0)',opacity:1},{transform:'translate('+Math.cos(a3)*s3+'px,'+(Math.sin(a3)*s3-14)+'px)',opacity:1,offset:.45},{transform:'translate('+Math.cos(a3)*s3*1.4+'px,'+(Math.sin(a3)*s3+18)+'px) scale(.4)',opacity:0}],{duration:600,easing:'ease-out'}).onfinish=function(){ this.effect.target.remove(); }; }
    }
  }
}
/* ---- крестики-нолики ---- */
var tttLast='';
function renderTTT(){
  var b=G.state.board, w=null, L=[[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]];
  L.forEach(function(l){ if(b[l[0]]!=='.'&&b[l[0]]===b[l[1]]&&b[l[0]]===b[l[2]]) w=l; });
  var h='<div class="ttt">';
  for(var i=0;i<9;i++){ var c=b[i], fresh=c!=='.'&&tttLast&&tttLast[i]==='.';
    h+='<button data-i="'+i+'" class="'+(w&&w.indexOf(i)>=0?'win':'')+'">'+(c==='x'?'<svg class="x'+(fresh?' draw':'')+'" viewBox="0 0 100 100"><line x1="18" y1="18" x2="82" y2="82"/><line x1="82" y1="18" x2="18" y2="82"/></svg>':c==='o'?'<svg class="o'+(fresh?' draw':'')+'" viewBox="0 0 100 100"><circle cx="50" cy="50" r="33"/></svg>':'')+'</button>'; }
  tttLast=b; return h+'</div>';
}
/* ---- шашки ---- */
function flip(){ return G.me===G.p2; }
function renderCk(){
  var b=G.state.board, myTurn=G.status==='active'&&G.turn===G.me, moves=myTurn?(G.moves||[]):[], last=G.state.last||[];
  var cand=moves.filter(function(m){ for(var k=0;k<partial.length;k++){ if(!m[k]||m[k][0]!==partial[k][0]||m[k][1]!==partial[k][1]) return false; } return true; });
  var dots={}, can={};
  if(partial.length) cand.forEach(function(m){ var n=m[partial.length]; if(n) dots[n[0]*8+n[1]]=1; });
  moves.forEach(function(m){ can[m[0][0]*8+m[0][1]]=1; });
  var lastSet={}; last.forEach(function(s){ lastSet[s[0]*8+s[1]]=1; });
  var h='<div class="ck">';
  for(var rr=0;rr<8;rr++) for(var cc=0;cc<8;cc++){
    var r=flip()?7-rr:rr, c=flip()?7-cc:cc, i=r*8+c, dark=(r+c)%2===1, p=b[i];
    var selHere=partial.length&&partial[0][0]===r&&partial[0][1]===c;
    var cur=partial.length&&partial[partial.length-1][0]===r&&partial[partial.length-1][1]===c;
    h+='<div class="'+(dark?'d':'l')+(cur&&partial.length>1?' hl':'')+(lastSet[i]?' last':'')+'" data-r="'+r+'" data-c="'+c+'">';
    if(p!=='.') h+='<span class="pc '+p.toLowerCase()+(selHere?' sel':'')+(!partial.length&&can[i]?' can':'')+'">'+(p===p.toUpperCase()?I.crown:'')+'</span>';
    if(dots[i]) h+='<span class="dot"></span>';
    h+='</div>';
  }
  h+='</div>';
  if(myTurn&&moves.length&&moves.some(function(m){return m.length>2||Math.abs(m[1][0]-m[0][0])>1&&b[m[0][0]*8+m[0][1]]===b[m[0][0]*8+m[0][1]].toLowerCase()})) h+='<div class="hint">Взятие обязательно</div>';
  return h;
}
function ckTap(r,c){
  var moves=G.moves||[]; if(G.status!=='active'||G.turn!==G.me) return;
  var starts=moves.filter(function(m){return m[0][0]===r&&m[0][1]===c});
  if(starts.length&&(!partial.length||partial.length===1)){ partial=[[r,c]]; return render(); }
  if(!partial.length) return;
  var next=partial.concat([[r,c]]);
  var cand=moves.filter(function(m){ if(m.length<next.length) return false; for(var k=0;k<next.length;k++) if(m[k][0]!==next[k][0]||m[k][1]!==next[k][1]) return false; return true; });
  if(!cand.length){ partial=[]; return render(); }
  var exact=cand.filter(function(m){return m.length===next.length});
  if(exact.length&&cand.length===exact.length){ partial=[]; return act({action:'move',path:next}); }
  partial=next; render();
}
/* ---- морской бой ---- */
function seaGrid(cls,cells,clickable){ var h='<div class="sea '+cls+'">'; for(var y=0;y<10;y++) for(var x=0;x<10;x++){ var k=cells[x*10+y]||''; h+='<div class="'+k+(clickable&&!k?' t':'')+'" data-x="'+x+'" data-y="'+y+'"></div>'; } return h+'</div>'; }
function renderSea(){
  var g=G, mineShips=g.myShips||[], shots=g.state.shots||{}, opp=g.me===g.p1?g.p2:g.p1;
  var own={}, enemy={};
  mineShips.forEach(function(s){ s.forEach(function(c){ own[c[0]*10+c[1]]='sh'; }); });
  (shots[opp]||[]).forEach(function(s){ var k=s.x*10+s.y; own[k]=s.s?'sunk':s.h?'hit':(own[k]?own[k]:'miss'); });
  var mineShots=shots[g.me]||[], last=g.state.last;
  mineShots.forEach(function(s){ enemy[s.x*10+s.y]=s.s?'sunk':s.h?'hit':'miss'; });
  if(g.oppShips) g.oppShips.forEach(function(s){ s.forEach(function(c){ var k=c[0]*10+c[1]; if(!enemy[k]) enemy[k]='sh'; }); });
  if(last&&last.by===g.me&&enemy[last.x*10+last.y]) enemy[last.x*10+last.y]+=' new';
  if(last&&last.by!==g.me&&own[last.x*10+last.y]) own[last.x*10+last.y]+=' new';
  if(!player()) return '<div class="hint">Морской бой идёт между '+esc(g.p1n)+' и '+esc(g.p2n||'…')+'</div>';
  if(g.status==='setup'||g.status==='invite') return '<div class="seaT">Ваш флот'+(g.status==='setup'&&!mineShips.length?' — нажмите «Перемешать»':'')+'</div>'+seaGrid('',own,false);
  var info='';
  if(last){ var whoMe=last.by===g.me; info='<div class="hint">'+(whoMe?(last.sunk?'Корабль потоплен! Стреляйте ещё':last.h?'Попадание! Стреляйте ещё':'Мимо'):(last.sunk?'Соперник потопил ваш корабль':last.h?'Соперник попал':'Соперник промахнулся'))+'</div>'; }
  return '<div class="seaT">Поле соперника</div>'+seaGrid('big',enemy,g.status==='active'&&g.turn===g.me)+info+'<div class="seaT" style="margin-top:12px">Ваш флот</div>'+seaGrid('sm',own,false);
}
function bind(){
  if(G.kind==='ttt') [].forEach.call(document.querySelectorAll('.ttt button'),function(b){ b.onclick=function(){ if(G.status!=='active') return; if(G.turn!==G.me) return toast(player()?'Сейчас ход соперника':'Вы не участвуете в игре'); if(G.state.board[+b.dataset.i]!=='.') return; act({action:'move',i:+b.dataset.i}); }; });
  if(G.kind==='checkers') [].forEach.call(document.querySelectorAll('.ck div'),function(d){ d.onclick=function(){ ckTap(+d.dataset.r,+d.dataset.c); }; });
  if(G.kind==='sea') [].forEach.call(document.querySelectorAll('.sea.big div.t'),function(d){ d.onclick=function(){ if(G.turn!==G.me) return toast('Сейчас ход соперника'); act({action:'move',x:+d.dataset.x,y:+d.dataset.y}); }; });
}
if(!C.gameId){ $('#app').innerHTML='<div class="load">Игра не найдена</div>'; return; }
poll(); startPoll();
window.lumoGameTest=function(g){ clearInterval(timer); set(g); };
})();
</script>
</body></html>

"""#
