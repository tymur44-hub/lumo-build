/* ===== TG4: загрузка с прогрессом (для публикации истории) ===== */
(function(){
window.tgUpP=async(blob,ext,cb)=>{
  const ses=await sb.auth.getSession(); const tk=ses&&ses.data&&ses.data.session&&ses.data.session.access_token;
  const path=`${S.me.id}/${uid8()}.${ext}`;
  try{
    await new Promise((res,rej)=>{ const x=new XMLHttpRequest(); x.open('POST',`${SUPABASE_URL}/storage/v1/object/${BUCKET}/${path}`);
      x.setRequestHeader('apikey',SUPABASE_KEY); if(tk) x.setRequestHeader('Authorization','Bearer '+tk); x.setRequestHeader('x-upsert','false'); x.setRequestHeader('cache-control','3600');
      if(blob.type) x.setRequestHeader('Content-Type',blob.type);
      x.upload.onprogress=e=>{ if(e.lengthComputable&&cb) cb(Math.min(.99,e.loaded/e.total)); };
      x.onload=()=>x.status>=200&&x.status<300?res():rej(new Error('Ошибка загрузки ('+x.status+')'));
      x.onerror=()=>rej(new Error('Нет связи')); x.send(blob); });
    return `${SUPABASE_ORIGIN}/storage/v1/object/public/${BUCKET}/${path}`;
  }catch(e){ return await upload(blob,ext); } };
})();
