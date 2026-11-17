/* Обои чата — те же, что в мобильной версии (номера совпадают):
   0 — без фона, 1–9 цвета, 10–17 узоры, 20–27 картины, 30–35 живые, 1000+n — с сервера */
(function(){
const BG='#0e0f22';
const hex=(n,a=1)=>`rgba(${n>>16&255},${n>>8&255},${n&255},${a})`;
const purple=0x7c5cff, teal=0x13b0a5, pink=0xff5b8a, blue=0x22a6ff;
function rng(seed){ let s=BigInt.asUintN(64,BigInt(seed)*6364136223846793005n+1442695040888963407n);
  return ()=>{ s=BigInt.asUintN(64,s*6364136223846793005n+1442695040888963407n); return Number((s>>33n)&0xFFFFFFn)/0xFFFFFF; }; }
function star4(g,x,y,s,col){ g.beginPath(); g.moveTo(x,y-s); g.quadraticCurveTo(x,y,x+s,y); g.quadraticCurveTo(x,y,x,y+s); g.quadraticCurveTo(x,y,x-s,y); g.quadraticCurveTo(x,y,x,y-s); g.fillStyle=col; g.fill(); }
function scatter(g,w,h,n,seed,col,maxR,baseA){ const r=rng(seed); for(let i=0;i<n;i++){ const x=r()*w,y=r()*h,s=(0.4+r())*maxR; star4(g,x,y,s,hex(col,baseA*(0.4+0.6*r()))); } }
function blob(g,x,y,rad,col,a){ const gr=g.createRadialGradient(x,y,0,x,y,rad); gr.addColorStop(0,hex(col,a)); gr.addColorStop(1,hex(col,0)); g.fillStyle=gr; g.beginPath(); g.arc(x,y,rad,0,7); g.fill(); }
function lin(g,h,a,b){ const gr=g.createLinearGradient(0,0,0,h); gr.addColorStop(0,hex(a)); gr.addColorStop(1,hex(b)); return gr; }
const PREM=[[0x1b2a49,0x3b1f4a],[0x0f3d3e,0x1b6b4a],[0x4a1f2e,0x7a3b1f],[0x1f2a4a,0x2e6ba8]];

function drawStatic(g,w,h,i){
  g.fillStyle=BG; g.fillRect(0,0,w,h); g.lineWidth=1.4;
  if(i>=6&&i<=9){ const p=PREM[i-6]; g.fillStyle=lin(g,h,p[0],p[1]); g.fillRect(0,0,w,h); return; }
  switch(i){
  case 1:{ const gr=g.createLinearGradient(0,0,w,h); gr.addColorStop(0,hex(0x7c5cff,.13)); gr.addColorStop(1,hex(0x22c1ff,.10)); g.fillStyle=gr; g.fillRect(0,0,w,h); break; }
  case 2: blob(g,w*.18,h*.22,w*.7,0xff5b8a,.16); blob(g,w*.82,h*.72,w*.7,0x7c5cff,.16); break;
  case 3: g.fillStyle=hex(0x8080aa,.22); for(let y=0;y<h;y+=18) for(let x=0;x<w;x+=18){ g.beginPath(); g.arc(x+1.2,y+1.2,1.2,0,7); g.fill(); } break;
  case 4:{ const gr=g.createLinearGradient(0,0,w,h); gr.addColorStop(0,hex(0x13b0a5,.16)); gr.addColorStop(1,hex(0x2ee6a6,.06)); g.fillStyle=gr; g.fillRect(0,0,w,h); break; }
  case 5: g.strokeStyle=hex(0x8080aa,.07); g.lineWidth=2; g.beginPath(); for(let x=-h;x<w;x+=14){ g.moveTo(x,h); g.lineTo(x+h,0); } g.stroke(); break;
  case 10:{ const st=26; g.fillStyle=hex(purple,.22); let row=0; for(let y=0;y<h+st;y+=st*.8,row++) for(let x=row%2?st/2:0;x<w+st;x+=st){ g.beginPath(); g.arc(x,y,2.8,0,7); g.fill(); } break; }
  case 11:{ const r=26,dx=Math.sqrt(3)*r,dy=1.5*r; g.strokeStyle=hex(teal,.2); let row=0; for(let y=0;y<h+r;y+=dy,row++) for(let x=row%2?dx/2:0;x<w+r;x+=dx){ g.beginPath(); for(let k=0;k<6;k++){ const a=(60*k-30)*Math.PI/180; const px=x+r*Math.cos(a),py=y+r*Math.sin(a); k?g.lineTo(px,py):g.moveTo(px,py);} g.closePath(); g.stroke(); } break; }
  case 12:{ let k=0; for(let y=20;y<h+20;y+=30,k++){ g.strokeStyle=hex(k%2?purple:pink,.2); g.beginPath(); g.moveTo(0,y); for(let x=0;x<=w;x+=6) g.lineTo(x,y+Math.sin(x/40+k)*8); g.stroke(); } break; }
  case 13: g.strokeStyle=hex(blue,.18); g.lineWidth=1.2; g.beginPath(); for(let x=-h;x<w+h;x+=42){ g.moveTo(x,0); g.lineTo(x+h,h); g.moveTo(x+h,0); g.lineTo(x,h); } g.stroke(); break;
  case 14: scatter(g,w,h,70,14,purple,7,.42); scatter(g,w,h,40,15,pink,4,.35); break;
  case 15: g.strokeStyle=hex(teal,.18); for(const [cx,cy] of [[0,0],[w,h]]) for(let r=30;r<Math.max(w,h)*1.3;r+=30){ g.beginPath(); g.arc(cx,cy,r,0,7); g.stroke(); } break;
  case 16:{ let k=0; for(let y=18;y<h+20;y+=26,k++){ g.strokeStyle=hex(k%2?teal:purple,.2); g.beginPath(); g.moveTo(0,y); let up=true; for(let x=0;x<=w+14;){ x+=14; g.lineTo(x,y+(up?-7:7)); up=!up; } g.stroke(); } break; }
  case 17:{ const st=38; g.strokeStyle=hex(pink,.26); g.lineWidth=1.6; g.beginPath(); let row=0; for(let y=st/2;y<h+st;y+=st/2,row++) for(let x=row%2?st:st/2;x<w+st;x+=st){ g.moveTo(x-5,y); g.lineTo(x+5,y); g.moveTo(x,y-5); g.lineTo(x,y+5); } g.stroke(); break; }
  case 20: g.fillStyle=lin(g,h,0x071a2e,0x1a0b3a); g.fillRect(0,0,w,h); blob(g,w*.2,h*.22,w*.8,0x2ee6a6,.34); blob(g,w*.85,h*.35,w*.75,0x22c1ff,.30); blob(g,w*.4,h*.7,w*.9,0xb069ff,.30); scatter(g,w,h,60,20,0xffffff,3,.6); break;
  case 21:{ g.fillStyle=lin(g,h,0x0d0221,0x2a0a4a); g.fillRect(0,0,w,h); const hy=h*.62,sr=w*.22; const gr=g.createLinearGradient(0,hy-sr*2,0,hy); gr.addColorStop(0,hex(0xffd24a)); gr.addColorStop(1,hex(0xff3d8a)); g.fillStyle=gr; g.beginPath(); g.arc(w/2,hy-w*.04,sr,0,7); g.fill();
    g.fillStyle=hex(0x0d0221); g.fillRect(0,hy,w,h-hy); g.lineWidth=1.2; g.strokeStyle=hex(0xff2bd6,.45); g.beginPath(); for(let k=-12;k<=12;k++){ g.moveTo(w/2,hy); g.lineTo(w/2+k*w*.18,h); } g.stroke();
    g.strokeStyle=hex(0x22e6ff,.4); g.beginPath(); for(let t=0;t<1;t+=.09){ const y=hy+(h-hy)*t*t; g.moveTo(0,y); g.lineTo(w,y); } g.stroke(); g.strokeStyle=hex(0xff2bd6); g.lineWidth=1.6; g.beginPath(); g.moveTo(0,hy); g.lineTo(w,hy); g.stroke(); break; }
  case 22:{ g.fillStyle=lin(g,h,0x04050e,0x150c32); g.fillRect(0,0,w,h); blob(g,w*.3,h*.3,w*.9,0x7c3dff,.30); blob(g,w*.8,h*.6,w*.8,0xff4da6,.22); blob(g,w*.2,h*.85,w*.7,0x2e7bff,.24);
    const r=rng(22); for(let i2=0;i2<160;i2++){ const rad=.6+r()*1.2,x=r()*w,y=r()*h; g.fillStyle=hex(0xffffff,.3+.6*r()); g.beginPath(); g.arc(x,y,rad,0,7); g.fill(); } scatter(g,w,h,14,23,0xffffff,7,.85); break; }
  case 23:{ g.fillStyle=lin(g,h,0x14110a,0x2b2210); g.fillRect(0,0,w,h); const r=24; g.lineWidth=1.1; let row=0; for(let y=0;y<h+r;y+=r*.9,row++) for(let x=row%2?r:0;x<w+r*2;x+=r*2) for(let k=1;k<=3;k++){ g.strokeStyle=hex(0xe8c26a,.34-k*.07); g.beginPath(); g.arc(x,y,r*k/3,0,Math.PI); g.stroke(); } break; }
  case 24:{ g.fillStyle=lin(g,h,0x042b40,0x0b6a85); g.fillRect(0,0,w,h); g.lineWidth=1.2; for(let k=0;k<6;k++){ const y0=h*(.25+.13*k); g.beginPath(); g.moveTo(0,y0); for(let x=0;x<=w;x+=6) g.lineTo(x,y0+Math.sin(x/50+k*1.3)*10); g.strokeStyle=hex(0xbdf7ff,.22); g.stroke(); g.lineTo(w,h); g.lineTo(0,h); g.closePath(); g.fillStyle=hex(0x9bf0ff,.07); g.fill(); }
    const r=rng(24); g.lineWidth=1; g.strokeStyle=hex(0xffffff,.18); for(let i2=0;i2<22;i2++){ const rad=2+r()*5,x=r()*w,y=r()*h; g.beginPath(); g.arc(x,y,rad,0,7); g.stroke(); } break; }
  case 25:{ g.fillStyle=lin(g,h,0x2a0f24,0x5e2146); g.fillRect(0,0,w,h); blob(g,w*.8,h*.15,w*.8,0xff8fb8,.22); const r=rng(25); for(let i2=0;i2<46;i2++){ const x=r()*w,y=r()*h,s=5+r()*6,a=r()*180; g.save(); g.translate(x,y); g.rotate(a*Math.PI/180); g.fillStyle=hex(0xffb3d1,.25+.4*r()); g.beginPath(); g.ellipse(0,0,s,s*.55,0,0,7); g.fill(); g.restore(); } break; }
  case 26:{ g.fillStyle=lin(g,h,0x0e2b25,0x15483a); g.fillRect(0,0,w,h); g.strokeStyle=hex(0x7dffd0,.2); g.lineWidth=1.1; [[w*.25,h*.3],[w*.8,h*.75]].forEach(([cx,cy],ci)=>{ for(let k=1;k<=16;k++){ g.beginPath(); const base=16*k; for(let t=0;t<=6.3;t+=.1){ const rr=base*(1+.1*Math.sin(3*t+k*.4+ci)+.05*Math.sin(5*t-k*.3)); const px=cx+rr*Math.cos(t),py=cy+rr*Math.sin(t); t?g.lineTo(px,py):g.moveTo(px,py);} g.closePath(); g.stroke(); } }); break; }
  case 27:{ g.fillStyle=hex(0x12101f); g.fillRect(0,0,w,h); const gr=g.createLinearGradient(0,0,w,h); [[0,0x7af0ff],[.33,0xff9be8],[.66,0xb59bff],[1,0x9bffd6]].forEach(([o,c])=>gr.addColorStop(o,hex(c,.5))); g.fillStyle=gr; g.fillRect(0,0,w,h);
    g.strokeStyle=hex(0xffffff,.09); g.lineWidth=5; g.beginPath(); for(let x=-h;x<w+h;x+=18){ g.moveTo(x,0); g.lineTo(x+h,h); } g.stroke(); blob(g,w*.7,h*.2,w*.7,0xffffff,.22); break; }
  }
}

// ---- живые обои: переливающийся градиент и плывущий узор из значков ----
const ICON={ // простые векторные значки (24×24)
 star:'M12 2l2.9 6.6 7.1.6-5.4 4.7 1.6 7.1L12 17.3 5.8 21l1.6-7.1L2 9.2l7.1-.6z',
 moon:'M15 2a9 9 0 1 0 7 13.5A8 8 0 0 1 15 2z',
 spark:'M12 2c.6 5 2.4 7.4 8 8-5.6.6-7.4 3-8 8-.6-5-2.4-7.4-8-8 5.6-.6 7.4-3 8-8z',
 globe:'M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zm0 2c1.5 1.8 2.4 4.6 2.5 7h-5c.1-2.4 1-5.2 2.5-7zm-4.5 9h9c-.2 2.4-1.1 5-2.5 7h-4c-1.4-2-2.3-4.6-2.5-7z',
 plane:'M21 16v-2l-8-5V3.5a1.5 1.5 0 0 0-3 0V9l-8 5v2l8-2.5V19l-2 1.5V22l3.5-1 3.5 1v-1.5L13 19v-5.5z',
 heart:'M12 21s-8-5.2-8-11a4.5 4.5 0 0 1 8-2.8A4.5 4.5 0 0 1 20 10c0 5.8-8 11-8 11z',
 gift:'M3 9h18v4H3zm2 5h14v7H5zm6-5v12h2V9zM12 9c-2-4-6-4-6-1.5S9 9 12 9zm0 0c2-4 6-4 6-1.5S15 9 12 9z',
 mail:'M3 5h18v14H3zm1.5 1.5L12 12l7.5-5.5',
 note:'M9 3v11.5A3.5 3.5 0 1 0 11 18V8h6V3z',
 phones:'M12 3a9 9 0 0 0-9 9v6a3 3 0 0 0 3 3h2v-8H5v-1a7 7 0 0 1 14 0v1h-3v8h2a3 3 0 0 0 3-3v-6a9 9 0 0 0-9-9z',
 mic:'M12 2a3 3 0 0 0-3 3v6a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3zm-7 9h2a5 5 0 0 0 10 0h2a7 7 0 0 1-6 6.9V21h-2v-3.1A7 7 0 0 1 5 11z',
 leaf:'M20 3C8 3 3 9 4 20c11 1 17-4 16-17zM6 18c3-5 6-8 11-11',
 tree:'M12 2l6 8h-3l4 6h-6v5h-2v-5H5l4-6H6z',
 sun:'M12 7a5 5 0 1 0 0 10 5 5 0 0 0 0-10zM11 1h2v3h-2zm0 19h2v3h-2zM1 11h3v2H1zm19 0h3v2h-3z',
 cloud:'M7 18h11a4 4 0 0 0 .5-8A6 6 0 0 0 7 9.5 4.3 4.3 0 0 0 7 18z',
 drop:'M12 2s7 7.5 7 12.5a7 7 0 0 1-14 0C5 9.5 12 2 12 2z',
 cup:'M4 8h13v5a6 6 0 0 1-6 6h-1a6 6 0 0 1-6-6zm13 1h2a3 3 0 0 1 0 6h-2.3',
 fork:'M7 2v8a2 2 0 0 0 1.5 1.9V22h2V11.9A2 2 0 0 0 12 10V2h-1v7h-1V2H9v7H8V2zm9 0c-2 0-3 3-3 7h2v13h2V2z',
 cake:'M5 11h14v10H5zm2-4h2v4H7zm4 0h2v4h-2zm4 0h2v4h-2zM8 4l1-2 1 2zm4 0l1-2 1 2zm4 0l1-2 1 2z',
 pad:'M7 7h10a5 5 0 0 1 4.8 6.4l-1.2 4A2.5 2.5 0 0 1 16.3 18L14 15h-4l-2.3 3a2.5 2.5 0 0 1-4.3-.6l-1.2-4A5 5 0 0 1 7 7z',
 dice:'M5 3h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2z',
 trophy:'M7 3h10v3h3v3a4 4 0 0 1-4 4 5 5 0 0 1-3 2.6V18h3v3H8v-3h3v-2.4A5 5 0 0 1 8 13a4 4 0 0 1-4-4V6h3z',
 bolt:'M13 2L4 14h7l-1 8 9-12h-7z',
 flag:'M5 2h2v20H5zm3 1h11l-2 4 2 4H8z',
};
const LIVE={
 30:{c:[0xC9D6FF,0xE2C6FF,0xB5E3FF,0xF3D1F4],d:[0x0E1A3D,0x2A1450,0x0B3350,0x3A1240],i:['star','moon','spark','globe','plane','moon']},
 31:{c:[0xFFD1DC,0xFFE3C9,0xF9C6E8,0xFFF0D6],d:[0x4A1430,0x55251A,0x3D1240,0x4F2A12],i:['heart','gift','spark','mail','star','heart']},
 32:{c:[0xD6CCFF,0xC7E6FF,0xE9D2FF,0xCFF5F0],d:[0x231650,0x0F2D55,0x3A1658,0x0D3D3A],i:['note','phones','note','mic','spark','phones']},
 33:{c:[0xCFF5D5,0xE8F7C4,0xC2EEE6,0xF4F1C8],d:[0x0E3A22,0x2C3A0E,0x0B3A36,0x3A350E],i:['leaf','tree','sun','cloud','drop','leaf']},
 34:{c:[0xFFE2C2,0xFFD3C7,0xFFF0C2,0xF9DCC9],d:[0x4A2A0E,0x4A1A12,0x4A3A0E,0x3D2214],i:['cup','fork','cake','cup','gift','fork']},
 35:{c:[0xC9E8FF,0xD9D2FF,0xC6F6E4,0xFFE0F0],d:[0x0E2A4A,0x26184A,0x0E3A2E,0x4A1A35],i:['pad','dice','trophy','star','flag','bolt']},
};
const paths={}; function P(n){ return paths[n]||(paths[n]=new Path2D(ICON[n])); }
function drawLive(g,w,h,idx,t,dark){
  const s=LIVE[idx]||LIVE[30], cols=(dark?s.d:s.c);
  g.fillStyle=hex(cols[0]); g.fillRect(0,0,w,h);
  for(let i=1;i<4;i++){ const a=t*(.07+i*.025)+i*1.7, cx=w*(.5+.42*Math.cos(a)), cy=h*(.5+.38*Math.sin(a*1.3+i)), r=Math.max(w,h)*.75; blob(g,cx,cy,r,cols[i],1); }
  const step=58,rowH=step*.86,travel=t*6,base=Math.floor(travel/rowH),drift=travel-base*rowH; const n=s.i.length;
  g.globalAlpha=dark?.16:.2; g.fillStyle=dark?'#fff':'#3A2E6E';
  let i=0; for(let y=-rowH+drift;y<h+step;y+=rowH,i++){ const row=i-base, odd=((row%2)+2)%2===1; let col=0;
    for(let x=(odd?step/2:0)-step;x<w+step;x+=step,col++){ const k=(((row*7+col*3)%n)+n)%n; const ph=row*13+col*5;
      g.save(); g.translate(x+Math.sin(t*.8+ph)*3,y+Math.cos(t*.7+ph)*3); g.rotate(((((row*31+col*17)%50)+50)%50-25+Math.sin(t*.6+ph)*6)*Math.PI/180); g.scale(.95,.95); g.translate(-12,-12); g.fill(P(s.i[k])); g.restore(); } }
  g.globalAlpha=1;
}

/** Нарисовать обои в canvas; для живых — запускается анимация. Возвращает функцию остановки. */
window.LumoWall=function(canvas,idx,opt){
  opt=opt||{}; const dark=opt.dark!==false; const g=canvas.getContext('2d'); let raf=0, img=null, stopped=false;
  function size(){ const r=canvas.getBoundingClientRect(), d=Math.min(2,devicePixelRatio||1); canvas.width=Math.max(1,r.width*d); canvas.height=Math.max(1,r.height*d); g.setTransform(d,0,0,d,0,0); return [r.width,r.height]; }
  function paint(){ if(stopped) return; const [w,h]=size();
    if(idx>=1000&&opt.url){ g.fillStyle=BG; g.fillRect(0,0,w,h); if(img&&img.complete){ const k=Math.max(w/img.width,h/img.height); g.drawImage(img,(w-img.width*k)/2,(h-img.height*k)/2,img.width*k,img.height*k); } return; }
    if(idx>=30&&idx<=35) return; drawStatic(g,w,h,idx); }
  if(idx>=1000&&opt.url){ img=new Image(); img.crossOrigin='anonymous'; img.onload=paint; img.src=opt.url; }
  if(idx>=30&&idx<=35){ const t0=performance.now(); const loop=now=>{ if(stopped) return; const [w,h]=[canvas.clientWidth,canvas.clientHeight]; if(canvas.width!==Math.round(w*Math.min(2,devicePixelRatio||1))) size(); drawLive(g,w,h,idx,(now-t0)/1000+idx*40,dark); raf=requestAnimationFrame(loop); }; size(); raf=requestAnimationFrame(loop); }
  else paint();
  const ro=new ResizeObserver(()=>{ if(!(idx>=30&&idx<=35)) paint(); }); ro.observe(canvas);
  return ()=>{ stopped=true; cancelAnimationFrame(raf); ro.disconnect(); };
};
window.LumoWallPremium=i=>i>=1000?false:((i>=6&&i<=9)||(i>=20&&i<=27)||(i>=33&&i<=35));
})();
