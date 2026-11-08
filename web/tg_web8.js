/* ===== TG8: открыли Lumo из уведомления о групповом звонке — сразу показываем «Входящий групповой звонок» ===== */
(function(){
try{ navigator.serviceWorker&&navigator.serviceWorker.addEventListener('message',e=>{ const id=e.data&&e.data.lumoOpen; if(!id) return;
  setTimeout(async()=>{ const c=S.chatMap&&S.chatMap.get(id); if(!c||c.type!=='group'||(window.GCall&&GCall.active)||!window.tgLkApi) return;
    const r=await window.tgLkApi(id,'status'); if(!r||!r.count) return;
    const inv=document.getElementById('gcinv'); if(inv) return;
    window.tgShowInvite&&window.tgShowInvite({chat_id:id,title:c.title,avatar:c.avatar_url,color:c.color,from:'',names:r.names||[]}); },1200); }); }catch(e){}
})();
