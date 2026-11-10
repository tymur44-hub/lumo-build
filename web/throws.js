/* Lumo — анимации бросков: кубик, монетка, баскетбол, футбол, дартс.
   Один и тот же код в веб-версии и в приложениях (WebView). Всё детерминировано:
   результат (v) определяет траекторию, кадр t считается чистой функцией — финальный кадр всегда один и тот же. */
(function (root) {
  'use strict';
  const W = 300, H = 300;
  const TAU = Math.PI * 2;
  const clamp = (x, a, b) => Math.max(a, Math.min(b, x));
  const lerp = (a, b, t) => a + (b - a) * t;
  const easeOut = t => 1 - Math.pow(1 - t, 3);
  const easeInOut = t => t < .5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
  // детерминированный «случай» от сида
  const rnd = s => { let x = Math.sin(s * 127.1 + 311.7) * 43758.5453; return x - Math.floor(x); };

  // ---------- 3D: кватернионы ----------
  const qMul = (a, b) => [
    a[0] * b[0] - a[1] * b[1] - a[2] * b[2] - a[3] * b[3],
    a[0] * b[1] + a[1] * b[0] + a[2] * b[3] - a[3] * b[2],
    a[0] * b[2] - a[1] * b[3] + a[2] * b[0] + a[3] * b[1],
    a[0] * b[3] + a[1] * b[2] - a[2] * b[1] + a[3] * b[0]];
  const qAxis = (x, y, z, ang) => { const l = Math.hypot(x, y, z) || 1, s = Math.sin(ang / 2); return [Math.cos(ang / 2), x / l * s, y / l * s, z / l * s]; };
  const qRot = (q, v) => {
    const [w, x, y, z] = q, [vx, vy, vz] = v;
    const ix = w * vx + y * vz - z * vy, iy = w * vy + z * vx - x * vz, iz = w * vz + x * vy - y * vx, iw = -x * vx - y * vy - z * vz;
    return [ix * w + iw * -x + iy * -z - iz * -y, iy * w + iw * -y + iz * -x - ix * -z, iz * w + iw * -z + ix * -y - iy * -x];
  };
  const qFromTo = (a, b) => { // кратчайший поворот вектора a в b
    const d = a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
    if (d < -0.9999) { const ax = Math.abs(a[0]) < .9 ? [1, 0, 0] : [0, 1, 0]; const c = [a[1] * ax[2] - a[2] * ax[1], a[2] * ax[0] - a[0] * ax[2], a[0] * ax[1] - a[1] * ax[0]]; return qAxis(c[0], c[1], c[2], Math.PI); }
    const c = [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
    const q = [1 + d, c[0], c[1], c[2]]; const l = Math.hypot(...q); return q.map(x => x / l);
  };

  // ---------- общие рисовалки ----------
  function shadow(ctx, x, y, rx, ry, a) {
    const g = ctx.createRadialGradient(x, y, 0, x, y, rx);
    g.addColorStop(0, `rgba(0,0,0,${a})`); g.addColorStop(1, 'rgba(0,0,0,0)');
    ctx.save(); ctx.translate(x, y); ctx.scale(1, ry / rx); ctx.translate(-x, -y);
    ctx.fillStyle = g; ctx.beginPath(); ctx.arc(x, y, rx, 0, TAU); ctx.fill(); ctx.restore();
  }
  function rrect(ctx, x, y, w, h, r) { ctx.beginPath(); ctx.moveTo(x + r, y); ctx.arcTo(x + w, y, x + w, y + h, r); ctx.arcTo(x + w, y + h, x, y + h, r); ctx.arcTo(x, y + h, x, y, r); ctx.arcTo(x, y, x + w, y, r); ctx.closePath(); }

  // ======================================================================
  // КУБИК: настоящий 3D-кубик, падает, отскакивает, кувыркается и ложится нужной гранью
  // ======================================================================
  const DICE_FACES = [ // нормаль, «вверх» на грани, число
    { n: [0, 0, 1], u: [1, 0, 0], v: 1 }, { n: [0, 0, -1], u: [-1, 0, 0], v: 6 },
    { n: [1, 0, 0], u: [0, 0, -1], v: 3 }, { n: [-1, 0, 0], u: [0, 0, 1], v: 4 },
    { n: [0, 1, 0], u: [1, 0, 0], v: 2 }, { n: [0, -1, 0], u: [1, 0, 0], v: 5 }];
  const PIPS = { 1: [[0, 0]], 2: [[-1, -1], [1, 1]], 3: [[-1, -1], [0, 0], [1, 1]], 4: [[-1, -1], [1, -1], [-1, 1], [1, 1]],
    5: [[-1, -1], [1, -1], [0, 0], [-1, 1], [1, 1]], 6: [[-1, -1], [1, -1], [-1, 0], [1, 0], [-1, 1], [1, 1]] };
  const DICE_T = 2.3;
  // высота и сдвиг: падение с отскоками (настоящая баллистика с потерей энергии)
  function bounceY(t, h0, g, e, n) {
    // свободное падение с h0, затем n отскоков с коэффициентом e; возвращает высоту и номер удара
    let tt = t, v = Math.sqrt(2 * g * h0), t0 = v / g; // время первого падения
    if (tt < t0) return { y: h0 - .5 * g * tt * tt, hit: 0, since: -1 };
    tt -= t0; let k = 1;
    while (k <= n) { v *= e; const dur = 2 * v / g; if (tt < dur) return { y: v * tt - .5 * g * tt * tt, hit: k, since: tt }; tt -= dur; k++; }
    return { y: 0, hit: n + 1, since: tt };
  }
  function diceQ(v, t) {
    const f = DICE_FACES.find(x => x.v === v);
    // финальная ориентация: нужная грань смотрит на зрителя, плюс лёгкий наклон, чтобы был виден объём
    let q = qFromTo(f.n, [0, 0, 1]);
    const tilt = qMul(qAxis(0, 1, 0, -.42), qAxis(1, 0, 0, .5));
    q = qMul(tilt, q);
    // кувырок: оставшийся угол экспоненциально гаснет, на каждом ударе ось немного меняется
    const k = 2.4, D = DICE_T - .25;
    const tt = Math.min(t, D);
    const rem = (Math.exp(-k * tt) - Math.exp(-k * D)) / (1 - Math.exp(-k * D));
    const ang = rem * TAU * (2.2 + rnd(v) * .6);
    const ax = [.6 + rnd(v + 1) * .5, 1, .3 + rnd(v + 2) * .4];
    const spin = qAxis(ax[0], ax[1], ax[2], ang);
    // покачивание при окончательной остановке
    const wob = t > D - .35 ? Math.sin((t - (D - .35)) * 26) * Math.exp(-(t - (D - .35)) * 9) * .05 : 0;
    return qMul(qAxis(1, 0, 1, wob), qMul(q, spin));
  }
  function drawDice(ctx, v, t) {
    const S = 52, F = 520; // полуребро и «фокус» перспективы
    const b = bounceY(Math.max(0, t - .05), 150, 1500, .38, 3);
    const xs = lerp(-60, 0, easeOut(clamp(t / 1.3, 0, 1)));
    const cx = 150 + xs, cyFloor = 150, cy = cyFloor - b.y;
    // тень: чем выше кубик, тем она меньше и прозрачнее
    const hk = clamp(b.y / 150, 0, 1);
    shadow(ctx, cx + 6, cyFloor + 52, 70 * (1 - hk * .45), 20 * (1 - hk * .45), .38 * (1 - hk * .6));
    // «сплющивание» при ударе
    let sq = 1;
    if (b.hit >= 1 && b.since >= 0 && b.since < .06) sq = 1 - .12 * Math.sin(b.since / .06 * Math.PI) / b.hit;
    const q = diceQ(v, t);
    const L = (() => { const l = [-.35, .42, .84], n = Math.hypot(...l); return l.map(x => x / n); })();
    const proj = p => { const s = F / (F - p[2]); return [cx + p[0] * s, cy + 46 - p[1] * s * sq + (1 - sq) * 46]; };
    const faces = DICE_FACES.map(f => {
      const n = qRot(q, f.n); const u = qRot(q, f.u); const w = [n[1] * u[2] - n[2] * u[1], n[2] * u[0] - n[0] * u[2], n[0] * u[1] - n[1] * u[0]];
      const c = n.map(x => x * S);
      return { f, n, u, w, c, z: c[2] };
    }).filter(o => o.n[2] > 0.02).sort((a, b) => a.z - b.z);
    for (const o of faces) {
      const P = (a, bb) => proj([o.c[0] + o.u[0] * a * S + o.w[0] * bb * S, o.c[1] + o.u[1] * a * S + o.w[1] * bb * S, o.c[2] + o.u[2] * a * S + o.w[2] * bb * S]);
      const c0 = P(0, 0), ua = P(1, 0), wa = P(0, 1);
      const lit = clamp(.7 + .38 * (o.n[0] * L[0] + o.n[1] * L[1] + o.n[2] * L[2]), .55, 1.06);
      // основа грани без скругления — закрывает щели между гранями на рёбрах
      const k0 = P(-1, -1), k1 = P(1, -1), k2 = P(1, 1), k3 = P(-1, 1);
      ctx.fillStyle = `rgb(${200 * lit | 0},${192 * lit | 0},${180 * lit | 0})`;
      ctx.beginPath(); ctx.moveTo(k0[0], k0[1]); ctx.lineTo(k1[0], k1[1]); ctx.lineTo(k2[0], k2[1]); ctx.lineTo(k3[0], k3[1]); ctx.closePath(); ctx.fill();
      ctx.save();
      ctx.setTransform(ctx.__dpr * (ua[0] - c0[0]), ctx.__dpr * (ua[1] - c0[1]), ctx.__dpr * (wa[0] - c0[0]), ctx.__dpr * (wa[1] - c0[1]), ctx.__dpr * c0[0], ctx.__dpr * c0[1]);
      // грань со скруглением
      const g = ctx.createLinearGradient(-1, -1, 1, 1);
      g.addColorStop(0, `rgb(${255 * lit | 0},${252 * lit | 0},${246 * lit | 0})`);
      g.addColorStop(1, `rgb(${232 * lit | 0},${224 * lit | 0},${214 * lit | 0})`);
      ctx.fillStyle = g; rrect(ctx, -.97, -.97, 1.94, 1.94, .3); ctx.fill();
      ctx.lineWidth = .02; ctx.strokeStyle = `rgba(0,0,0,${.18})`; ctx.stroke();
      // точки: с тенью-углублением
      const pts = PIPS[o.f.v], r = o.f.v === 1 ? .26 : .19, d = .52;
      for (const p of pts) {
        ctx.fillStyle = o.f.v === 1 ? '#d8263b' : '#1c1a24';
        ctx.beginPath(); ctx.arc(p[0] * d, p[1] * d, r, 0, TAU); ctx.fill();
        ctx.fillStyle = 'rgba(255,255,255,.22)'; ctx.beginPath(); ctx.arc(p[0] * d + r * .25, p[1] * d + r * .25, r * .55, 0, TAU); ctx.fill();
      }
      // блик
      if (lit > .9) { const hg = ctx.createRadialGradient(-.5, -.6, 0, -.5, -.6, 1.4); hg.addColorStop(0, `rgba(255,255,255,${(lit - .9) * 2.2})`); hg.addColorStop(1, 'rgba(255,255,255,0)'); ctx.fillStyle = hg; rrect(ctx, -1, -1, 2, 2, .34); ctx.fill(); }
      ctx.restore();
    }
  }

  // ======================================================================
  // МОНЕТКА: подброс, кувырки, падение, «юла» на столе (как настоящая монета)
  // ======================================================================
  const COIN_T = 2.8;
  function drawCoin(ctx, v, t) {
    const R = 62, TH = 9, F = 600;
    // полёт вверх-вниз, затем пара отскоков
    const up = 1.05, hMax = 118;
    let y, flipAng, hitK = 0;
    const rest = v === 1 ? 0 : Math.PI;
    const totalFlips = 7 * TAU;
    if (t < up) { const k = t / up; y = hMax * (1 - Math.pow(2 * k - 1, 2)); }
    else { const b = bounceY(t - up, 0.0001, 1600, .3, 2); y = b.y; hitK = b.hit; y = Math.max(0, y); }
    // вращение: быстро в полёте, затем гаснет
    const tf = clamp(t / (up + .25), 0, 1);
    flipAng = rest + totalFlips * (1 - easeOut(tf)) + (t > up ? 0 : 0);
    // после приземления — «юла»: наклон оси вращается и затухает (диск Эйлера)
    const land = up + .25;
    let tiltX = -.9, prec = 0;
    if (t > land) { const s = t - land; const a = .28 * Math.exp(-s * 2.2); prec = s * (9 + s * 10); tiltX += a * Math.cos(prec); flipAng = rest + a * Math.sin(prec) * .9; }
    // итоговая ориентация: монета лежит на столе, видна сверху-спереди
    const q = qMul(qAxis(1, 0, 0, tiltX), qAxis(1, 0, 0, flipAng));
    const cx = 150, floor = 214, cy = floor - y;
    const hk = clamp(y / hMax, 0, 1);
    shadow(ctx, cx + 4, floor + 34, 78 * (1 - hk * .4), 22 * (1 - hk * .4), .35 * (1 - hk * .6));
    const proj = p => { const s = F / (F - p[2]); return [cx + p[0] * s, cy + 18 - p[1] * s]; };
    const n = qRot(q, [0, 0, 1]), u = qRot(q, [1, 0, 0]), w = qRot(q, [0, 1, 0]);
    const front = n[2] >= 0; // какая сторона смотрит на нас
    const faceC = s => n.map(x => x * TH / 2 * s);
    // ребро монеты (рифлёное)
    const N = 48;
    const rim = s => { const c = faceC(s), arr = []; for (let i = 0; i < N; i++) { const a = i / N * TAU; arr.push(proj([c[0] + (u[0] * Math.cos(a) + w[0] * Math.sin(a)) * R, c[1] + (u[1] * Math.cos(a) + w[1] * Math.sin(a)) * R, c[2] + (u[2] * Math.cos(a) + w[2] * Math.sin(a)) * R])); } return arr; };
    const A = rim(front ? 1 : -1), B = rim(front ? -1 : 1);
    ctx.fillStyle = '#9c7413';
    for (let i = 0; i < N; i++) { const j = (i + 1) % N; ctx.beginPath(); ctx.moveTo(A[i][0], A[i][1]); ctx.lineTo(A[j][0], A[j][1]); ctx.lineTo(B[j][0], B[j][1]); ctx.lineTo(B[i][0], B[i][1]); ctx.closePath(); ctx.fillStyle = i % 2 ? '#a77d17' : '#8c6610'; ctx.fill(); }
    // видимая сторона
    const c = proj(faceC(front ? 1 : -1));
    const ua = (() => { const p = faceC(front ? 1 : -1); return proj([p[0] + u[0] * R, p[1] + u[1] * R, p[2] + u[2] * R]); })();
    const wa = (() => { const p = faceC(front ? 1 : -1); return proj([p[0] + w[0] * R, p[1] + w[1] * R, p[2] + w[2] * R]); })();
    ctx.save();
    ctx.setTransform(ctx.__dpr * (ua[0] - c[0]), ctx.__dpr * (ua[1] - c[1]), ctx.__dpr * (wa[0] - c[0]) * (front ? -1 : 1), ctx.__dpr * (wa[1] - c[1]) * (front ? -1 : 1), ctx.__dpr * c[0], ctx.__dpr * c[1]);
    const lit = clamp(.92 + .25 * (n[2] * (front ? 1 : -1)) - .1 * Math.abs(n[1]), .78, 1.12);
    coinFace(ctx, front, lit); // «передняя» сторона — орёл, задняя — решка
    ctx.restore();
    void hitK;
  }
  function coinFace(ctx, heads, lit) {
    const g = ctx.createRadialGradient(-.35, -.4, .1, 0, 0, 1.15);
    const k = x => Math.round(clamp(x * lit, 0, 255));
    g.addColorStop(0, `rgb(${k(255)},${k(236)},${k(160)})`); g.addColorStop(.55, `rgb(${k(232)},${k(184)},${k(62)})`); g.addColorStop(1, `rgb(${k(176)},${k(128)},${k(22)})`);
    ctx.fillStyle = g; ctx.beginPath(); ctx.arc(0, 0, 1, 0, TAU); ctx.fill();
    ctx.lineWidth = .05; ctx.strokeStyle = 'rgba(120,80,0,.55)'; ctx.beginPath(); ctx.arc(0, 0, .86, 0, TAU); ctx.stroke();
    // насечки по кругу
    ctx.strokeStyle = 'rgba(120,80,0,.35)'; ctx.lineWidth = .02;
    for (let i = 0; i < 60; i++) { const a = i / 60 * TAU; ctx.beginPath(); ctx.moveTo(Math.cos(a) * .9, Math.sin(a) * .9); ctx.lineTo(Math.cos(a) * .97, Math.sin(a) * .97); ctx.stroke(); }
    ctx.fillStyle = 'rgba(110,70,0,.85)';
    if (heads) {
      // орёл: стилизованная птица с крыльями
      ctx.beginPath();
      ctx.moveTo(0, -.52); ctx.bezierCurveTo(.1, -.5, .14, -.38, .08, -.3);
      ctx.bezierCurveTo(.3, -.36, .55, -.3, .66, -.08); ctx.bezierCurveTo(.5, -.12, .38, -.06, .3, .02);
      ctx.bezierCurveTo(.44, .02, .5, .1, .46, .18); ctx.bezierCurveTo(.34, .12, .22, .14, .14, .2);
      ctx.lineTo(.2, .48); ctx.lineTo(0, .38); ctx.lineTo(-.2, .48); ctx.lineTo(-.14, .2);
      ctx.bezierCurveTo(-.22, .14, -.34, .12, -.46, .18); ctx.bezierCurveTo(-.5, .1, -.44, .02, -.3, .02);
      ctx.bezierCurveTo(-.38, -.06, -.5, -.12, -.66, -.08); ctx.bezierCurveTo(-.55, -.3, -.3, -.36, -.08, -.3);
      ctx.bezierCurveTo(-.14, -.38, -.1, -.5, 0, -.52); ctx.closePath(); ctx.fill();
      ctx.fillStyle = `rgba(255,240,190,${.35 * lit})`; ctx.beginPath(); ctx.arc(-.03, -.42, .035, 0, TAU); ctx.fill();
    } else {
      // решка: номинал
      ctx.font = 'bold 0.78px Georgia, serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
      ctx.fillText('1', 0, -.08);
      ctx.font = 'bold 0.2px sans-serif'; ctx.fillText('ЛЮМЕН', 0, .42);
      ctx.lineWidth = .04; ctx.strokeStyle = 'rgba(110,70,0,.7)';
      ctx.beginPath(); ctx.arc(0, -.05, .62, Math.PI * .15, Math.PI * .85, true); ctx.stroke();
    }
    // блик
    const hg = ctx.createLinearGradient(-1, -1, 1, 1); hg.addColorStop(.3, 'rgba(255,255,255,0)'); hg.addColorStop(.45, `rgba(255,255,255,${.28 * lit})`); hg.addColorStop(.6, 'rgba(255,255,255,0)');
    ctx.fillStyle = hg; ctx.beginPath(); ctx.arc(0, 0, 1, 0, TAU); ctx.fill();
  }

  // ======================================================================
  // БАСКЕТБОЛ: честная физика (гравитация, отскоки от дужки и щита, вращение мяча)
  // ======================================================================
  const BB = { r: 12, g: 980, rimF: [206, 118], rimB: [246, 118], rimR: 2.6, boardX: 252, boardTop: 54, boardBot: 132, floor: 262, e: .62, eb: .72 };
  // начальные скорости подобраны заранее так, чтобы получился нужный исход (см. tools/tune_basket.js)
  const BB_SHOTS = { 1: [150, -454], 2: [172, -540], 3: [296, -540], 4: [196, -540], 5: [210, -544] };
  function simBasket(v) {
    const [vx0, vy0] = BB_SHOTS[v] || BB_SHOTS[5];
    let x = 46, y = 222, vx = vx0, vy = vy0, rot = 0, w = -9;
    const dt = 1 / 240, out = [];
    let scored = false, touched = false, netHit = -1, floorAt = -1;
    for (let i = 0; i < 240 * 3.2; i++) {
      vy += BB.g * dt; x += vx * dt; y += vy * dt; rot += w * dt;
      // дужка: две точки (передняя и задняя)
      for (const p of [BB.rimF, BB.rimB]) {
        const dx = x - p[0], dy = y - p[1], d = Math.hypot(dx, dy), md = BB.r + BB.rimR;
        if (d < md) {
          const nx = dx / d, ny = dy / d; x = p[0] + nx * md; y = p[1] + ny * md;
          const vn = vx * nx + vy * ny; if (vn < 0) { vx -= (1 + BB.e) * vn * nx; vy -= (1 + BB.e) * vn * ny; vx *= .92; w += vn * .02; touched = true; }
        }
      }
      // щит
      if (x + BB.r > BB.boardX && y > BB.boardTop && y < BB.boardBot && vx > 0) { x = BB.boardX - BB.r; vx = -vx * BB.eb; w = -w * .6; touched = true; }
      // пол
      if (y + BB.r > BB.floor) { y = BB.floor - BB.r; if (vy > 0) { vy = -vy * .5; if (floorAt < 0) floorAt = i; } vx *= .55; w = vx / BB.r; }
      // попадание: центр мяча прошёл сверху вниз между точками дужки
      if (!scored && vy > 0 && y > BB.rimF[1] && y - vy * dt <= BB.rimF[1] && x > BB.rimF[0] && x < BB.rimB[0]) { scored = true; netHit = i; }
      // в сетке мяч тормозит
      if (scored && y > BB.rimF[1] && y < BB.rimF[1] + 46) { vx *= .95; vy *= .975; x = lerp(x, (BB.rimF[0] + BB.rimB[0]) / 2, .08); }
      // стойка кольца
      if (x + BB.r > 272 && y > 40 && vx > 0) { x = 272 - BB.r; vx = -vx * .35; }
      out.push([x, y, rot]);
    }
    return { path: out, scored, touched, netHit, dt, end: floorAt < 0 ? 3 : Math.min(3, floorAt * dt + .9) };
  }
  const BBC = {};
  const basket = v => BBC[v] || (BBC[v] = simBasket(v));
  const BASKET_T = 3.0;
  function drawBasket(ctx, v, t) {
    const s = basket(v); const i = clamp(Math.floor(Math.min(t, s.end) / s.dt), 0, s.path.length - 1);
    const [x, y, rot] = s.path[i];
    ctx.translate(150, 160); ctx.scale(1.13, 1.13); ctx.translate(-160, -150);
    // пол и тень
    const fl = ctx.createLinearGradient(0, BB.floor - 6, 0, BB.floor + 30); fl.addColorStop(0, 'rgba(200,140,80,.0)'); fl.addColorStop(.3, 'rgba(196,132,74,.35)'); fl.addColorStop(1, 'rgba(160,100,50,0)');
    ctx.fillStyle = fl; ctx.fillRect(0, BB.floor - 6, W, 36);
    shadow(ctx, x, BB.floor + 2, 20 * (1 - clamp((BB.floor - y) / 260, 0, .6)), 5, .35 * (1 - clamp((BB.floor - y) / 260, 0, .7)));
    // стойка и щит
    ctx.fillStyle = '#5b6170'; ctx.fillRect(272, 40, 8, BB.floor - 40);
    ctx.fillStyle = '#4a4f5c'; ctx.fillRect(254, 86, 20, 6);
    const bg = ctx.createLinearGradient(BB.boardX, 0, BB.boardX + 10, 0); bg.addColorStop(0, '#f4f7fb'); bg.addColorStop(1, '#c9d2de');
    ctx.fillStyle = bg; rrect(ctx, BB.boardX, BB.boardTop - 10, 9, BB.boardBot - BB.boardTop + 20, 2); ctx.fill();
    ctx.fillStyle = '#e8492f'; ctx.fillRect(BB.boardX, 88, 3, 30);
    // задняя часть дужки и сетка (за мячом)
    const netSw = s.netHit >= 0 && i >= s.netHit ? Math.exp(-(i - s.netHit) * s.dt * 4) * Math.sin((i - s.netHit) * s.dt * 22) : 0;
    const ballInNet = s.scored && y > BB.rimF[1] - 4 && y < BB.rimF[1] + 52 && x > BB.rimF[0] - 6 && x < BB.rimB[0] + 6;
    drawNet(ctx, netSw, ballInNet ? (y - BB.rimF[1]) : -1);
    ctx.strokeStyle = '#c2410c'; ctx.lineWidth = 3; ctx.beginPath(); ctx.ellipse((BB.rimF[0] + BB.rimB[0]) / 2, BB.rimF[1], 20, 4, 0, Math.PI, TAU); ctx.stroke();
    // мяч
    ball(ctx, x, y, BB.r, rot);
    // передняя часть дужки поверх мяча
    ctx.strokeStyle = '#ea580c'; ctx.lineWidth = 3.4; ctx.beginPath(); ctx.ellipse((BB.rimF[0] + BB.rimB[0]) / 2, BB.rimF[1], 20, 4, 0, 0, Math.PI); ctx.stroke();
    ctx.fillStyle = '#9a3412'; ctx.fillRect(BB.rimB[0], BB.rimF[1] - 2, BB.boardX - BB.rimB[0], 3);
  }
  function drawNet(ctx, sw, ballDepth) {
    const top = BB.rimF[1], l = BB.rimF[0], r = BB.rimB[0], cx = (l + r) / 2;
    ctx.strokeStyle = 'rgba(255,255,255,.85)'; ctx.lineWidth = 1;
    const rows = 5, cols = 7;
    const pt = (c, rr) => {
      const k = rr / rows; let half = lerp(20, 11, k);
      if (ballDepth >= 0) { const dist = Math.abs(rr / rows * 44 - ballDepth); if (dist < 16) half += (16 - dist) * .55; }
      const xx = cx + (c / (cols - 1) - .5) * 2 * half + sw * 5 * k;
      return [xx, top + k * 44 + Math.abs(sw) * 3 * k];
    };
    for (let c = 0; c < cols; c++) { ctx.beginPath(); for (let rr = 0; rr <= rows; rr++) { const p = pt(c + (rr % 2) * .5 - .25, rr); rr ? ctx.lineTo(p[0], p[1]) : ctx.moveTo(p[0], p[1]); } ctx.stroke(); }
    for (let rr = 1; rr <= rows; rr++) { ctx.beginPath(); for (let c = 0; c < cols; c++) { const p = pt(c, rr); c ? ctx.lineTo(p[0], p[1]) : ctx.moveTo(p[0], p[1]); } ctx.stroke(); }
    void l; void r;
  }
  function ball(ctx, x, y, r, rot) {
    const g = ctx.createRadialGradient(x - r * .35, y - r * .4, r * .1, x, y, r);
    g.addColorStop(0, '#ffb46b'); g.addColorStop(.6, '#f2731c'); g.addColorStop(1, '#b8480b');
    ctx.fillStyle = g; ctx.beginPath(); ctx.arc(x, y, r, 0, TAU); ctx.fill();
    ctx.save(); ctx.beginPath(); ctx.arc(x, y, r, 0, TAU); ctx.clip(); ctx.translate(x, y); ctx.rotate(rot);
    ctx.strokeStyle = 'rgba(40,16,4,.85)'; ctx.lineWidth = r * .09;
    ctx.beginPath(); ctx.moveTo(-r, 0); ctx.lineTo(r, 0); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(0, -r); ctx.lineTo(0, r); ctx.stroke();
    ctx.beginPath(); ctx.arc(-r * 1.25, 0, r * .95, -.9, .9); ctx.stroke();
    ctx.beginPath(); ctx.arc(r * 1.25, 0, r * .95, Math.PI - .9, Math.PI + .9); ctx.stroke();
    ctx.restore();
  }

  // ======================================================================
  // ФУТБОЛ: вид из-за мяча, ворота в перспективе, вратарь прыгает, сетка прогибается
  // ======================================================================
  const FOOT_T = 2.7;
  // цель удара в координатах ворот (x: -1..1 — от штанги до штанги, y: 0..1 — от земли до перекладины)
  const FOOT_SHOTS = {
    1: { tx: 1.45, ty: .35, keeper: -.2, kind: 'wide' },     // мимо, рядом со штангой
    2: { tx: -.55, ty: .45, keeper: -.55, kind: 'save' },    // вратарь отбивает
    3: { tx: -.78, ty: .16, keeper: .45, kind: 'goal' },     // низом в угол
    4: { tx: .8, ty: .86, keeper: .25, kind: 'goal' },       // в «девятку»
    5: { tx: .2, ty: .62, keeper: -.7, kind: 'goal' }        // вратарь прыгнул не туда
  };
  function drawFoot(ctx, v, t) {
    const sh = FOOT_SHOTS[v] || FOOT_SHOTS[3];
    // перспектива: z=0 — у мяча, z=1 — линия ворот
    const hor = 96, gw = 150, gh = 66; // ворота на экране
    const gx = 150, gy = 168; // центр линии ворот (низ)
    const P = (x, y, z) => { const s = lerp(1, .32, Math.pow(z, .8)); const sx = 150 + (gx - 150) * z + x * s * 230; const sy = lerp(270, gy, Math.pow(z, .85)) - y * s * 200; return [sx, sy, s]; };
    // газон
    const grass = ctx.createLinearGradient(0, hor, 0, H);
    grass.addColorStop(0, '#2f8f46'); grass.addColorStop(1, '#1f6b33');
    ctx.fillStyle = grass; rrect(ctx, 6, hor, W - 12, H - hor - 6, 22); ctx.fill();
    ctx.save(); rrect(ctx, 6, hor, W - 12, H - hor - 6, 22); ctx.clip();
    for (let i = 0; i < 6; i++) { ctx.fillStyle = i % 2 ? 'rgba(255,255,255,.05)' : 'rgba(0,0,0,.05)'; const y0 = lerp(hor, H, Math.pow(i / 6, 1.6)), y1 = lerp(hor, H, Math.pow((i + 1) / 6, 1.6)); ctx.fillRect(0, y0, W, y1 - y0); }
    // разметка штрафной
    ctx.strokeStyle = 'rgba(255,255,255,.55)'; ctx.lineWidth = 1.5;
    ctx.beginPath(); ctx.moveTo(20, gy + 2); ctx.lineTo(280, gy + 2); ctx.stroke();
    ctx.beginPath(); const a1 = P(-1.1, 0, .55), a2 = P(1.1, 0, .55); ctx.moveTo(gx - gw * .8, gy + 2); ctx.lineTo(a1[0], a1[1]); ctx.lineTo(a2[0], a2[1]); ctx.lineTo(gx + gw * .8, gy + 2); ctx.stroke();
    ctx.restore();
    // мяч: путь
    const tKick = .35, tFly = 1.0;
    const k = clamp((t - tKick) / tFly, 0, 1);
    let bx, by, bz, saved = false, post = false;
    const goal = sh.kind === 'goal';
    const gX = x => x * gw / 2 / 230 / .32, gY = y => y * gh / 200 / .32; // перевод координат ворот в мир
    const tx = gX(sh.tx), ty = gY(sh.ty);
    if (t < tKick) { bx = 0; by = 0; bz = 0; }
    else if (k < 1) { const kk = k * (1.25 - .25 * k); /* мяч слегка тормозит в воздухе */ bx = tx * kk + Math.sin(kk * Math.PI) * .06 * Math.sign(sh.tx || 1); by = ty * kk + Math.sin(kk * Math.PI) * .16; bz = kk; }
    else {
      // после ворот
      const s = t - tKick - tFly;
      if (goal) { bx = tx; by = Math.max(0, ty - s * s * 1.8); bz = 1 + Math.min(.12, s * .5); }
      else if (sh.kind === 'save') { saved = true; bx = tx - s * .9; by = Math.max(0, ty + s * .5 - s * s * 2.4); bz = 1 - s * .45; }
      else { post = true; bx = tx + s * .2; by = Math.max(0, ty - s * s * 1.6); bz = 1 + s * .5; }
    }
    // вратарь: стоит, реагирует, прыгает
    const kj = clamp((t - tKick - .25) / .55, 0, 1);
    const kx = lerp(0, sh.keeper, easeOut(kj)) * gw / 2;
    const kLift = Math.sin(kj * Math.PI) * 14 * Math.abs(sh.keeper);
    const kAng = sh.keeper * easeOut(kj) * 1.25;
    // ворота: задняя сетка
    const L = gx - gw / 2, R = gx + gw / 2, T = gy - gh, depth = 18;
    const bulge = goal && t > tKick + tFly ? Math.exp(-(t - tKick - tFly) * 3.2) * 10 : 0;
    const hitX = gx + sh.tx * gw / 2, hitY = gy - sh.ty * gh;
    ctx.strokeStyle = 'rgba(255,255,255,.5)'; ctx.lineWidth = .8;
    const netP = (u, w) => { const x = lerp(L + 8, R - 8, u), y = lerp(T - depth * .4, gy - 2, w); const d = Math.hypot(x - hitX, y - hitY); const b = bulge * Math.max(0, 1 - d / 50); return [x + (x - gx) * .0, y - depth * .2 - b * .4, b]; };
    for (let i = 0; i <= 14; i++) { ctx.beginPath(); for (let j = 0; j <= 8; j++) { const p = netP(i / 14, j / 8); j ? ctx.lineTo(p[0], p[1]) : ctx.moveTo(p[0], p[1]); } ctx.stroke(); }
    for (let j = 0; j <= 8; j++) { ctx.beginPath(); for (let i = 0; i <= 14; i++) { const p = netP(i / 14, j / 8); i ? ctx.lineTo(p[0], p[1]) : ctx.moveTo(p[0], p[1]); } ctx.stroke(); }
    ctx.strokeStyle = 'rgba(255,255,255,.55)'; ctx.beginPath(); ctx.moveTo(L, T); ctx.lineTo(L + 8, T - depth * .5); ctx.lineTo(R - 8, T - depth * .5); ctx.lineTo(R, T); ctx.moveTo(L + 8, T - depth * .5); ctx.lineTo(L + 8, gy - 4); ctx.moveTo(R - 8, T - depth * .5); ctx.lineTo(R - 8, gy - 4); ctx.stroke();
    // мяч за вратарём, если залетел в ворота
    const bp = P(bx, by, Math.min(bz, 1.1));
    const br = 19 * (bp[2] * .55 + .45) * (bz > 1 ? .92 : 1);
    const ballBehind = bz >= .98;
    const drawBall = () => {
      shadow(ctx, P(bx, 0, Math.min(bz, 1.1))[0], P(bx, 0, Math.min(bz, 1.1))[1] + 2, br * 1.1, br * .35, .35);
      soccer(ctx, bp[0], bp[1] - br, br, t * (t > tKick ? 16 : 0) * (1 - k * .5));
    };
    if (ballBehind) drawBall();
    keeper(ctx, gx + kx, gy - 2 - kLift, kAng, saved ? 1 : 0);
    // штанги и перекладина
    ctx.strokeStyle = '#ffffff'; ctx.lineWidth = 4.5; ctx.lineCap = 'round';
    ctx.beginPath(); ctx.moveTo(L, gy); ctx.lineTo(L, T); ctx.lineTo(R, T); ctx.lineTo(R, gy); ctx.stroke(); ctx.lineCap = 'butt';
    if (!ballBehind) drawBall();
    // вспышка «ГОЛ»
    if (goal && t > tKick + tFly) {
      const s = t - tKick - tFly; const a = clamp(s * 3, 0, 1) * clamp((2.5 - s) * 2, 0, 1);
      ctx.save(); ctx.globalAlpha = a; ctx.fillStyle = 'rgba(255,255,255,.95)'; ctx.font = '900 30px system-ui,-apple-system,Segoe UI,Roboto,sans-serif'; ctx.textAlign = 'center';
      ctx.shadowColor = 'rgba(0,0,0,.45)'; ctx.shadowBlur = 8; ctx.fillText('ГОЛ!', 150, 70 - easeOut(clamp(s * 2, 0, 1)) * 8); ctx.restore();
    }
    void post; void hor;
  }
  function keeper(ctx, x, y, ang, saving) {
    ctx.save(); ctx.translate(x, y); ctx.rotate(ang);
    // тень вратаря
    ctx.fillStyle = '#ffd23f'; // форма
    ctx.strokeStyle = '#1e1e28'; ctx.lineWidth = 4; ctx.lineCap = 'round';
    // ноги
    ctx.beginPath(); ctx.moveTo(-4, -18); ctx.lineTo(-7, 0); ctx.moveTo(4, -18); ctx.lineTo(7, 0); ctx.stroke();
    // туловище
    rrect(ctx, -8, -40, 16, 24, 5); ctx.fill();
    // руки вверх-в стороны
    ctx.strokeStyle = '#ffd23f'; ctx.lineWidth = 4.5;
    ctx.beginPath(); ctx.moveTo(-7, -36); ctx.lineTo(-18 - saving * 4, -50); ctx.moveTo(7, -36); ctx.lineTo(18 + saving * 4, -50); ctx.stroke();
    ctx.fillStyle = '#f5f5f5'; ctx.beginPath(); ctx.arc(-19 - saving * 4, -52, 3.6, 0, TAU); ctx.arc(19 + saving * 4, -52, 3.6, 0, TAU); ctx.fill();
    // голова
    ctx.fillStyle = '#e7b48f'; ctx.beginPath(); ctx.arc(0, -47, 6, 0, TAU); ctx.fill();
    ctx.fillStyle = '#3b2a20'; ctx.beginPath(); ctx.arc(0, -49, 6, Math.PI, TAU); ctx.fill();
    ctx.restore(); ctx.lineCap = 'butt';
  }
  function soccer(ctx, x, y, r, rot) {
    const g = ctx.createRadialGradient(x - r * .35, y - r * .4, r * .1, x, y, r);
    g.addColorStop(0, '#ffffff'); g.addColorStop(.7, '#e9ecf1'); g.addColorStop(1, '#a9b0bc');
    ctx.fillStyle = g; ctx.beginPath(); ctx.arc(x, y, r, 0, TAU); ctx.fill();
    ctx.save(); ctx.beginPath(); ctx.arc(x, y, r, 0, TAU); ctx.clip(); ctx.translate(x, y); ctx.rotate(rot);
    ctx.fillStyle = '#1d1f27';
    const pent = (cx, cy, s) => { ctx.beginPath(); for (let i = 0; i < 5; i++) { const a = -Math.PI / 2 + i * TAU / 5; const px = cx + Math.cos(a) * s, py = cy + Math.sin(a) * s; i ? ctx.lineTo(px, py) : ctx.moveTo(px, py); } ctx.closePath(); ctx.fill(); };
    pent(0, 0, r * .36);
    for (let i = 0; i < 5; i++) { const a = -Math.PI / 2 + i * TAU / 5 + Math.PI / 5; pent(Math.cos(a) * r * .95, Math.sin(a) * r * .95, r * .3); }
    ctx.restore();
  }

  // ======================================================================
  // ДАРТС: дротик летит к мишени, втыкается, мишень и дротик дрожат
  // ======================================================================
  const DART_T = 1.9;
  const DART_HIT = { 6: [0, 0], 5: [7, -13], 4: [-34, 44], 3: [44, 28], 2: [-63, -46], 1: [104, 78] };
  const SEG = [20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5];
  function drawDarts(ctx, v, t) {
    const cx = 150, cy = 132, R = 104;
    const tFly = .55, tHit = .2 + tFly;
    const hit = DART_HIT[v] || DART_HIT[3];
    const miss = v === 1;
    const shake = t > tHit ? Math.sin((t - tHit) * 48) * Math.exp(-(t - tHit) * 9) : 0;
    // стена
    ctx.save(); ctx.translate(shake * 1.2, 0);
    // мишень
    ctx.fillStyle = '#1b1b1f'; ctx.beginPath(); ctx.arc(cx, cy, R + 12, 0, TAU); ctx.fill();
    const ring = (r0, r1, c1, c2) => { for (let i = 0; i < 20; i++) { const a0 = (i - .5) / 20 * TAU - Math.PI / 2, a1 = (i + .5) / 20 * TAU - Math.PI / 2; ctx.fillStyle = i % 2 ? c2 : c1; ctx.beginPath(); ctx.arc(cx, cy, r1, a0, a1); ctx.arc(cx, cy, r0, a1, a0, true); ctx.closePath(); ctx.fill(); } };
    ring(R * .62, R, '#efe6cf', '#1f1f23');
    ring(R * .9, R, '#d32f2f', '#2e7d32');
    ring(R * .1, R * .58, '#efe6cf', '#1f1f23');
    ring(R * .54, R * .6, '#d32f2f', '#2e7d32');
    ctx.fillStyle = '#2e7d32'; ctx.beginPath(); ctx.arc(cx, cy, R * .1, 0, TAU); ctx.fill();
    ctx.fillStyle = '#d32f2f'; ctx.beginPath(); ctx.arc(cx, cy, R * .045, 0, TAU); ctx.fill();
    ctx.strokeStyle = 'rgba(200,200,200,.45)'; ctx.lineWidth = .8; ctx.beginPath(); ctx.arc(cx, cy, R, 0, TAU); ctx.stroke();
    ctx.fillStyle = '#f2f2f2'; ctx.font = 'bold 9px system-ui,sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    SEG.forEach((n, i) => { const a = i / 20 * TAU - Math.PI / 2; ctx.fillText(String(n), cx + Math.cos(a) * (R + 6.5), cy + Math.sin(a) * (R + 6.5)); });
    // блик
    const hg = ctx.createRadialGradient(cx - 40, cy - 50, 5, cx, cy, R + 12); hg.addColorStop(0, 'rgba(255,255,255,.12)'); hg.addColorStop(1, 'rgba(255,255,255,0)');
    ctx.fillStyle = hg; ctx.beginPath(); ctx.arc(cx, cy, R + 12, 0, TAU); ctx.fill();
    ctx.restore();
    // дротик
    const k = clamp((t - .2) / tFly, 0, 1);
    if (t < .2) return;
    const tx = cx + hit[0], ty = cy + hit[1];
    if (k < 1) {
      // летит от зрителя: большой и снизу → маленький у цели, по дуге
      const e = easeInOut(k) * .4 + k * .6;
      const x = lerp(170, tx, e), y = lerp(330, ty, e) - Math.sin(k * Math.PI) * 60;
      const sc = lerp(3.6, 1.7, Math.pow(k, .7));
      dart(ctx, x, y, sc, (1 - k) * .4 - .15, 0);
    } else {
      // воткнулся (при промахе — в стену рядом с мишенью) и дрожит
      const s = t - tHit; const wob = Math.sin(s * 40) * Math.exp(-s * 7) * .22;
      dart(ctx, tx + (miss ? 0 : shake * 1.2), ty, 1.7, -.2 + wob, 1);
    }
  }
  function dart(ctx, x, y, sc, ang, stuck) {
    ctx.save(); ctx.translate(x, y); ctx.rotate(ang); ctx.scale(sc, sc);
    // вид немного сбоку: игла впереди (вверх), оперение сзади (вниз)
    if (stuck) { ctx.fillStyle = 'rgba(0,0,0,.35)'; ctx.beginPath(); ctx.ellipse(6, 26, 4, 14, -.2, 0, TAU); ctx.fill(); }
    ctx.strokeStyle = '#c9ccd4'; ctx.lineWidth = 1.6; ctx.beginPath(); ctx.moveTo(0, 0); ctx.lineTo(0, 8); ctx.stroke();
    const bg = ctx.createLinearGradient(-3, 0, 3, 0); bg.addColorStop(0, '#6b7280'); bg.addColorStop(.5, '#e5e7eb'); bg.addColorStop(1, '#4b5563');
    ctx.fillStyle = bg; rrect(ctx, -3, 8, 6, 20, 2.5); ctx.fill();
    ctx.strokeStyle = 'rgba(0,0,0,.35)'; ctx.lineWidth = .6; for (let i = 0; i < 5; i++) { ctx.beginPath(); ctx.moveTo(-3, 11 + i * 3.6); ctx.lineTo(3, 11 + i * 3.6); ctx.stroke(); }
    ctx.fillStyle = '#374151'; ctx.fillRect(-1.2, 28, 2.4, 10);
    ctx.fillStyle = '#7c5cff'; ctx.beginPath(); ctx.moveTo(0, 34); ctx.lineTo(-10, 50); ctx.lineTo(-2, 46); ctx.closePath(); ctx.fill();
    ctx.fillStyle = '#22c1ff'; ctx.beginPath(); ctx.moveTo(0, 34); ctx.lineTo(10, 50); ctx.lineTo(2, 46); ctx.closePath(); ctx.fill();
    ctx.restore();
  }

  // ---------- общее API ----------
  const SCENES = { dice: [drawDice, DICE_T], coin: [drawCoin, COIN_T], basket: [drawBasket, BASKET_T], football: [drawFoot, FOOT_T], darts: [drawDarts, DART_T] };
  function setup(cv) {
    const dpr = Math.min(3, (root.devicePixelRatio || 1));
    const css = cv.clientWidth || cv.width || 160;
    const px = Math.round(css * dpr);
    if (cv.width !== px) { cv.width = px; cv.height = px; }
    const ctx = cv.getContext('2d');
    ctx.__dpr = px / W;
    return ctx;
  }
  function frame(cv, kind, v, t) {
    const sc = SCENES[kind] || SCENES.dice; const ctx = setup(cv);
    ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.clearRect(0, 0, cv.width, cv.height);
    ctx.setTransform(ctx.__dpr, 0, 0, ctx.__dpr, 0, 0);
    sc[0](ctx, v, Math.min(t, sc[1]));
  }
  const api = {
    duration: (k, v) => k === 'basket' && v ? basket(v).end : (SCENES[k] || SCENES.dice)[1],
    /** нарисовать финальный кадр (результат уже известен) */
    final(cv, kind, v) { frame(cv, kind, v, 99); },
    /** проиграть анимацию; onEnd вызовется по окончании; onHit — в момент удара/приземления (для вибрации) */
    play(cv, kind, v, onEnd, onHit) {
      const D = api.duration(kind, v); let st = null, stop = false;
      const hitAt = { dice: .62, coin: 1.08, basket: 1.1, football: 1.35, darts: .76 }[kind] || 1;
      let hitDone = false;
      const step = ts => {
        if (stop) return; if (st == null) st = ts;
        const t = (ts - st) / 1000;
        frame(cv, kind, v, t);
        if (!hitDone && t >= hitAt) { hitDone = true; onHit && onHit(); }
        if (t < D) root.requestAnimationFrame(step); else onEnd && onEnd();
      };
      root.requestAnimationFrame(step);
      return () => { stop = true; };
    },
    frame,
    _sim: { basket: simBasket, BB, BB_SHOTS }
  };
  root.LumoThrows = api;
  if (typeof module !== 'undefined') module.exports = api;
})(typeof window !== 'undefined' ? window : globalThis);
