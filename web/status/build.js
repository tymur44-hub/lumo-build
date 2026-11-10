// Рендерит ленты кадров (8x6, 48 кадров, 24 к/с, цикл 2 с) из SVG для приложений и контрольный лист.
const {chromium}=require('playwright'); const fs=require('fs'); const path=require('path');
const dir=__dirname, out=process.argv[2]||path.join(dir,'frames'); const F=48, S=112;
(async()=>{ const b=await chromium.launch(); const p=await b.newPage({viewport:{width:S,height:S},deviceScaleFactor:1});
 p.on('pageerror',e=>console.log('ERR',e.message));
 const keys=fs.readdirSync(dir).filter(f=>f.endsWith('.svg')).map(f=>f.replace('.svg',''));
 for(const k of keys){ const svg=fs.readFileSync(path.join(dir,k+'.svg'),'utf8');
  await p.setContent('<body style="margin:0;background:transparent"><div id="h" style="width:'+S+'px;height:'+S+'px">'+svg.replace('<svg ','<svg width="'+S+'" height="'+S+'" ')+'</div>');
  fs.mkdirSync(path.join(out,k),{recursive:true});
  for(let i=0;i<F;i++){ await p.evaluate(t=>document.getAnimations().forEach(a=>{a.pause();a.currentTime=t;}),i*2000/F);
   await p.screenshot({path:path.join(out,k,String(i).padStart(2,'0')+'.png'),omitBackground:true}); }
  console.log(k, await p.evaluate(()=>document.getAnimations().length)); }
 await b.close(); })();
