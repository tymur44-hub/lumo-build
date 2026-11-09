/* ===== Видеозвонок: видео собеседника целиком, если его форма не совпадает с экраном (телефон ↔ ПК) ===== */
(function(){
  const st=document.createElement('style');
  st.textContent='#call #rv.lfit,#call #rimg.lfit,#call #rcv.lfit{object-fit:contain!important}';
  document.head.appendChild(st);
  function fit(el,w,h){ if(!el||!w||!h) return; const c=el.parentElement; if(!c) return;
    const vr=w/h, cr=c.clientWidth/Math.max(1,c.clientHeight);
    el.classList.toggle('lfit', Math.max(vr,cr)/Math.min(vr,cr)>1.25); }
  setInterval(()=>{ const c=document.getElementById('call'); if(!c) return;
    const rv=c.querySelector('#rv'), im=c.querySelector('#rimg'), cv=c.querySelector('#rcv');
    if(rv) fit(rv,rv.videoWidth,rv.videoHeight);
    if(im) fit(im,im.naturalWidth,im.naturalHeight);
    if(cv) fit(cv,cv.width,cv.height);
  },700);
})();
