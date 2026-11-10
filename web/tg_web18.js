/* ===== Подарки другого пользователя: весь список и карточка подарка ===== */
(function(){
  const RR={rare:['Редкий','#22c7e0'],epic:['Эпический','#ff8a3d'],legendary:['Легендарный','#b069ff'],mythic:['Мифический','#ffc247'],ultra:['Божественный','#ff2ec4']};
  const st=document.createElement('style');
  st.textContent='.lxgrow .lxsec,.lxgrow .lxg{cursor:pointer}.lxgrow .lxsec .all{float:right;color:var(--a1);letter-spacing:0}.ugg{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:8px}.ugg .g{background:var(--panel2);border-radius:16px;padding:6px;text-align:center;cursor:pointer;min-width:0}.ugg .g .lxif{width:100%;aspect-ratio:1;border-radius:12px}.ugg .g b{display:block;font-size:12px;margin-top:4px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}';
  document.head.appendChild(st);
  async function load(u){ const {data,error}=await sb.rpc('lm_gift_mine',{p_user:u}); if(error) throw error; return data||[]; }
  async function card(o,u){
    let from=null; if(o.from_user){ if(!S.profiles.get(o.from_user)) await profGet([o.from_user]).catch(()=>{}); from=S.profiles.get(o.from_user); }
    const r=RR[o.rarity]||['','#888']; const d=o.at?new Date(o.at):null;
    const w=document.createElement('div'); w.className='lxsh';
    w.innerHTML=`<div class="sh"><button class="x">${ic('x')}</button>${window.art(o.gift_id,'')}<h2>${esc(o.name)}</h2>
    <div class="d">№${o.serial} из ${o.supply} · <b style="color:${r[1]}">${r[0]}</b><br>Подарок в профиле ${esc(profName(u))}.</div>
    <div class="tb"><div class="tr"><div class="l">От</div><div class="r">${from?`${avatar({name:from.name,avatar:from.avatar_url,color:from.color},'xs')}<a>${esc(from.name)}</a>`:'Купил сам'}</div></div>
    <div class="tr"><div class="l">Дата</div><div class="r">${d?esc(d.toLocaleDateString('ru-RU')):'—'}</div></div>
    <div class="tr"><div class="l">Стоимость</div><div class="r">${o.price!=null?esc(o.price+' '+plural(o.price,'люмен','люмена','люменов')):'—'}</div></div></div>
    <button class="ok">OK</button></div>`;
    const cl=()=>w.remove(); w.onclick=e=>{ if(e.target===w) cl(); };
    w.querySelector('.x').onclick=cl; w.querySelector('.ok').onclick=cl; document.body.appendChild(w);
  }
  async function list(u){
    const close=modal('Подарки · '+esc(profName(u)),'<div id="ugg"><div class="em">Загрузка…</div></div>',[]);
    try{ try{ const {data:ga}=await sb.rpc('lm_gift_art'); if(ga&&typeof ga==='object') window.__gart=ga; }catch(e){}
      const L=await load(u); const el=document.getElementById('ugg'); if(!el) return;
      el.innerHTML=L.length?`<div class="ugg">${L.map((o,i)=>`<div class="g" data-i="${i}">${window.art(o.gift_id,'')}<b style="color:${(RR[o.rarity]||[0,'#888'])[1]}">${esc(o.name)} №${o.serial}</b></div>`).join('')}</div>`:'<div class="em">Подарков пока нет</div>';
      el.querySelectorAll('[data-i]').forEach(x=>x.onclick=()=>card(L[+x.dataset.i],u));
    }catch(e){ toast('Не удалось загрузить подарки'); }
  }
  document.addEventListener('click',e=>{
    const row=e.target.closest&&e.target.closest('.lxgrow'); if(!row) return;
    const a=row.previousElementSibling; const u=a&&a.dataset&&a.dataset.lxu; if(!u) return;
    e.stopImmediatePropagation(); e.preventDefault();
    const g=e.target.closest('.lxg');
    if(g){ const i=[...row.querySelectorAll('.lxg')].indexOf(g); load(u).then(L=>{ if(L[i]) card(L[i],u); }).catch(()=>{}); }
    else list(u);
  },true);
  new MutationObserver(()=>{ document.querySelectorAll('.lxgrow .lxsec:not([data-all])').forEach(h=>{ h.dataset.all=1; h.insertAdjacentHTML('beforeend','<span class="all">Все</span>'); }); }).observe(document.body,{childList:true,subtree:true});
})();
