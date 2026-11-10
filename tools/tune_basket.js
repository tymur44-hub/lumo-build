// подбор начальных скоростей мяча под каждый исход
const T=require('../web/throws.js'); const {BB}=T._sim;
function sim(vx0,vy0){ let x=46,y=222,vx=vx0,vy=vy0; const dt=1/240; let scored=false,rim=false,board=false;
 for(let i=0;i<240*3;i++){ vy+=BB.g*dt; x+=vx*dt; y+=vy*dt;
  for(const p of [BB.rimF,BB.rimB]){ const dx=x-p[0],dy=y-p[1],d=Math.hypot(dx,dy),md=BB.r+BB.rimR; if(d<md){ const nx=dx/d,ny=dy/d; x=p[0]+nx*md; y=p[1]+ny*md; const vn=vx*nx+vy*ny; if(vn<0){ vx-=(1+BB.e)*vn*nx; vy-=(1+BB.e)*vn*ny; vx*=.92; rim=true; } } }
  if(x+BB.r>BB.boardX&&y>BB.boardTop&&y<BB.boardBot&&vx>0){ x=BB.boardX-BB.r; vx=-vx*BB.eb; board=true; }
  if(!scored&&vy>0&&y>BB.rimF[1]&&y-vy*dt<=BB.rimF[1]&&x>BB.rimF[0]&&x<BB.rimB[0]) scored=true;
  if(y+BB.r>BB.floor) break; }
 return {scored,rim,board,x}; }
const want={1:r=>!r.scored&&!r.rim&&!r.board&&r.x<BB.rimF[0]-10, 2:r=>!r.scored&&r.rim&&!r.board, 3:r=>!r.scored&&r.board, 4:r=>r.scored&&r.rim, 5:r=>r.scored&&!r.rim&&!r.board};
const res={};
for(const v of [5,4,2,3,1]){ let best=null;
 for(let vy=-380;vy>=-680;vy-=2) for(let vx=150;vx<=520;vx+=2){ const r=sim(vx,vy); if(!want[v](r)) continue;
   // устойчивость: соседние значения дают тот же исход
   let ok=0; for(const [a,b] of [[2,0],[-2,0],[0,2],[0,-2]]) if(want[v](sim(vx+a,vy+b))) ok++;
   const score=ok*10 - Math.abs(vy+540)/20; if(!best||score>best.s) best={vx,vy,s:score}; }
 res[v]=best; console.log(v,best); }
