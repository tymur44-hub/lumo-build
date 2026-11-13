// Lumo: шахматы по полным правилам — ходы, шах и мат, рокировка, взятие на проходе,
// превращение пешки, пат, ничья по 50 ходам, троекратное повторение и недостаток материала.
// Доска — 64 символа, индекс r*8+c: r=0 — восьмая горизонталь (сторона чёрных), c=0 — вертикаль «a».
// Белые — заглавные PNBRQK, чёрные — строчные, «.» — пусто.

export type Color = "w" | "b";
export type ChessState = {
  board: string;
  castle: string;      // оставшиеся права на рокировку: подмножество "KQkq"
  ep: number;          // клетка для взятия на проходе или -1
  half: number;        // полуходы без взятий и ходов пешками (правило 50 ходов)
  full: number;        // номер хода
  last: number[] | null;
  hist: Record<string, number>; // сколько раз встречалась позиция
  san: string[];       // записи ходов
  draw: string | null; // кто предложил ничью
};
export type Move = { from: number; to: number; promo?: string; flag?: "ep" | "castle" | "double" };

const START = "rnbqkbnrpppppppp" + ".".repeat(32) + "PPPPPPPPRNBQKBNR";

export function chessStart(): ChessState {
  const s: ChessState = { board: START, castle: "KQkq", ep: -1, half: 0, full: 1, last: null, hist: {}, san: [], draw: null };
  s.hist[posKey(s, "w")] = 1;
  return s;
}

const rc = (i: number) => [i >> 3, i & 7];
const idx = (r: number, c: number) => (r < 0 || r > 7 || c < 0 || c > 7 ? -1 : r * 8 + c);
const colorOf = (p: string): Color | null => (p === "." ? null : p === p.toUpperCase() ? "w" : "b");
const KN = [[-2, -1], [-2, 1], [-1, -2], [-1, 2], [1, -2], [1, 2], [2, -1], [2, 1]];
const KG = [[-1, -1], [-1, 0], [-1, 1], [0, -1], [0, 1], [1, -1], [1, 0], [1, 1]];
const DIAG = [[-1, -1], [-1, 1], [1, -1], [1, 1]];
const ORTH = [[-1, 0], [1, 0], [0, -1], [0, 1]];

/** атакует ли сторона `by` клетку `sq` */
export function attacked(b: string, sq: number, by: Color): boolean {
  const [r, c] = rc(sq);
  const P = by === "w" ? "P" : "p", N = by === "w" ? "N" : "n", B = by === "w" ? "B" : "b", R = by === "w" ? "R" : "r", Q = by === "w" ? "Q" : "q", K = by === "w" ? "K" : "k";
  // пешка бьёт по диагонали вперёд: белая пешка снизу (r+1) атакует клетку выше
  const pr = by === "w" ? r + 1 : r - 1;
  for (const dc of [-1, 1]) { const j = idx(pr, c + dc); if (j >= 0 && b[j] === P) return true; }
  for (const [dr, dc] of KN) { const j = idx(r + dr, c + dc); if (j >= 0 && b[j] === N) return true; }
  for (const [dr, dc] of KG) { const j = idx(r + dr, c + dc); if (j >= 0 && b[j] === K) return true; }
  for (const [dr, dc] of DIAG) {
    let rr = r + dr, cc = c + dc, j = idx(rr, cc);
    while (j >= 0) { const p = b[j]; if (p !== ".") { if (p === B || p === Q) return true; break; } rr += dr; cc += dc; j = idx(rr, cc); }
  }
  for (const [dr, dc] of ORTH) {
    let rr = r + dr, cc = c + dc, j = idx(rr, cc);
    while (j >= 0) { const p = b[j]; if (p !== ".") { if (p === R || p === Q) return true; break; } rr += dr; cc += dc; j = idx(rr, cc); }
  }
  return false;
}

const kingSq = (b: string, side: Color) => b.indexOf(side === "w" ? "K" : "k");
export const inCheck = (b: string, side: Color) => { const k = kingSq(b, side); return k >= 0 && attacked(b, k, side === "w" ? "b" : "w"); };

function pseudo(s: ChessState, side: Color): Move[] {
  const b = s.board, out: Move[] = [];
  const foe: Color = side === "w" ? "b" : "w";
  for (let i = 0; i < 64; i++) {
    const p = b[i];
    if (colorOf(p) !== side) continue;
    const [r, c] = rc(i), t = p.toLowerCase();
    if (t === "p") {
      const dir = side === "w" ? -1 : 1, startR = side === "w" ? 6 : 1, lastR = side === "w" ? 0 : 7;
      const one = idx(r + dir, c);
      const push = (to: number, flag?: Move["flag"]) => {
        if ((to >> 3) === lastR) for (const pr of ["q", "r", "b", "n"]) out.push({ from: i, to, promo: pr });
        else out.push({ from: i, to, flag });
      };
      if (one >= 0 && b[one] === ".") {
        push(one);
        const two = idx(r + 2 * dir, c);
        if (r === startR && b[two] === ".") out.push({ from: i, to: two, flag: "double" });
      }
      for (const dc of [-1, 1]) {
        const j = idx(r + dir, c + dc);
        if (j < 0) continue;
        if (colorOf(b[j]) === foe) push(j);
        else if (j === s.ep) out.push({ from: i, to: j, flag: "ep" });
      }
    } else if (t === "n" || t === "k") {
      for (const [dr, dc] of t === "n" ? KN : KG) {
        const j = idx(r + dr, c + dc);
        if (j >= 0 && colorOf(b[j]) !== side) out.push({ from: i, to: j });
      }
      if (t === "k") {
        // рокировка: король и ладья не ходили, между ними пусто, король не под шахом и не проходит битое поле
        const home = side === "w" ? 60 : 4;
        if (i === home && !attacked(b, home, foe)) {
          const ks = side === "w" ? "K" : "k", qs = side === "w" ? "Q" : "q", rook = side === "w" ? "R" : "r";
          if (s.castle.includes(ks) && b[home + 1] === "." && b[home + 2] === "." && b[home + 3] === rook &&
              !attacked(b, home + 1, foe) && !attacked(b, home + 2, foe)) out.push({ from: i, to: home + 2, flag: "castle" });
          if (s.castle.includes(qs) && b[home - 1] === "." && b[home - 2] === "." && b[home - 3] === "." && b[home - 4] === rook &&
              !attacked(b, home - 1, foe) && !attacked(b, home - 2, foe)) out.push({ from: i, to: home - 2, flag: "castle" });
        }
      }
    } else {
      const dirs = t === "b" ? DIAG : t === "r" ? ORTH : [...DIAG, ...ORTH];
      for (const [dr, dc] of dirs) {
        let rr = r + dr, cc = c + dc, j = idx(rr, cc);
        while (j >= 0) {
          const q = colorOf(b[j]);
          if (q === side) break;
          out.push({ from: i, to: j });
          if (q) break;
          rr += dr; cc += dc; j = idx(rr, cc);
        }
      }
    }
  }
  return out;
}

/** сделать ход (без проверки допустимости) — новое состояние */
export function apply(s: ChessState, m: Move, side: Color): ChessState {
  const b = s.board.split("");
  const p = b[m.from], t = p.toLowerCase();
  const captured = b[m.to] !== "." || m.flag === "ep";
  b[m.to] = m.promo ? (side === "w" ? m.promo.toUpperCase() : m.promo.toLowerCase()) : p;
  b[m.from] = ".";
  if (m.flag === "ep") b[m.to + (side === "w" ? 8 : -8)] = ".";
  if (m.flag === "castle") {
    if (m.to > m.from) { b[m.from + 1] = b[m.from + 3]; b[m.from + 3] = "."; }
    else { b[m.from - 1] = b[m.from - 4]; b[m.from - 4] = "."; }
  }
  let castle = s.castle;
  const drop = (ch: string) => { castle = castle.replace(ch, ""); };
  if (p === "K") { drop("K"); drop("Q"); }
  if (p === "k") { drop("k"); drop("q"); }
  for (const sq of [m.from, m.to]) {
    if (sq === 63) drop("K"); if (sq === 56) drop("Q"); if (sq === 7) drop("k"); if (sq === 0) drop("q");
  }
  return {
    ...s,
    board: b.join(""),
    castle,
    ep: m.flag === "double" ? (m.from + m.to) / 2 : -1,
    half: t === "p" || captured ? 0 : s.half + 1,
    full: side === "b" ? s.full + 1 : s.full,
    last: [m.from, m.to],
  };
}

export function legal(s: ChessState, side: Color): Move[] {
  return pseudo(s, side).filter((m) => !inCheck(apply(s, m, side).board, side));
}

/** ключ позиции для троекратного повторения (доска, очередь, рокировки, взятие на проходе) */
export function posKey(s: ChessState, toMove: Color) {
  return s.board + toMove + s.castle + (s.ep >= 0 ? s.ep : "-");
}

/** нехватка материала для мата: K–K, K+лёгкая–K, K+B–K+B (слоны одного цвета) */
export function insufficient(b: string): boolean {
  const pcs: { p: string; i: number }[] = [];
  for (let i = 0; i < 64; i++) if (b[i] !== "." && b[i].toLowerCase() !== "k") pcs.push({ p: b[i], i });
  if (pcs.length === 0) return true;
  if (pcs.length === 1 && "nNbB".includes(pcs[0].p)) return true;
  if (pcs.every((x) => "bB".includes(x.p))) {
    const col = (i: number) => ((i >> 3) + (i & 7)) % 2;
    return pcs.every((x) => col(x.i) === col(pcs[0].i));
  }
  return false;
}

const FILES = "abcdefgh";
export const sqName = (i: number) => FILES[i & 7] + (8 - (i >> 3));

/** запись хода в шахматной нотации (Кf3, exd5, O-O, e8=Q+, Фxf7#) — по-русски */
export function san(s: ChessState, m: Move, side: Color): string {
  const p = s.board[m.from], t = p.toLowerCase();
  if (m.flag === "castle") return withCheck(m.to > m.from ? "0-0" : "0-0-0");
  const RU: Record<string, string> = { n: "К", b: "С", r: "Л", q: "Ф", k: "Кр" };
  const cap = s.board[m.to] !== "." || m.flag === "ep";
  let str = "";
  if (t === "p") {
    str = (cap ? FILES[m.from & 7] + ":" : "") + sqName(m.to) + (m.promo ? "=" + RU[m.promo] : "");
  } else {
    // уточнение, если такая же фигура может пойти на ту же клетку
    const others = legal(s, side).filter((o) => o.to === m.to && o.from !== m.from && s.board[o.from] === p);
    let dis = "";
    if (others.length) {
      const sameFile = others.some((o) => (o.from & 7) === (m.from & 7));
      const sameRank = others.some((o) => (o.from >> 3) === (m.from >> 3));
      dis = !sameFile ? FILES[m.from & 7] : !sameRank ? String(8 - (m.from >> 3)) : sqName(m.from);
    }
    str = RU[t] + dis + (cap ? ":" : "") + sqName(m.to);
  }
  return withCheck(str);
  function withCheck(x: string) {
    const ns = apply(s, m, side), foe: Color = side === "w" ? "b" : "w";
    if (!inCheck(ns.board, foe)) return x;
    return x + (legal(ns, foe).length ? "+" : "#");
  }
}

/** итог после хода: кто должен ходить и закончилась ли партия */
export function verdict(s: ChessState, toMove: Color): { over: boolean; winner: Color | null; result: string } {
  const moves = legal(s, toMove);
  if (!moves.length) {
    if (inCheck(s.board, toMove)) return { over: true, winner: toMove === "w" ? "b" : "w", result: "mate" };
    return { over: true, winner: null, result: "stalemate" };
  }
  if (insufficient(s.board)) return { over: true, winner: null, result: "material" };
  if (s.half >= 100) return { over: true, winner: null, result: "fifty" };
  if ((s.hist[posKey(s, toMove)] || 0) >= 3) return { over: true, winner: null, result: "repetition" };
  return { over: false, winner: null, result: "" };
}

/** ход игрока: проверка, запись, повторения. Возвращает новое состояние или null, если ход недопустим */
export function play(s: ChessState, side: Color, from: number, to: number, promo?: string): ChessState | null {
  const m = legal(s, side).find((x) => x.from === from && x.to === to && (x.promo ? x.promo === (promo || "q") : true));
  if (!m) return null;
  const note = san(s, m, side);
  const ns = apply(s, m, side);
  const foe: Color = side === "w" ? "b" : "w";
  const hist = { ...(s.hist || {}) };
  const k = posKey(ns, foe);
  hist[k] = (hist[k] || 0) + 1;
  return { ...ns, hist, san: [...(s.san || []), note], draw: null };
}

/** все ходы для клиента: [откуда, куда] (превращение — один вариант, фигура выбирается при ходе) */
export function clientMoves(s: ChessState, side: Color): number[][] {
  const seen = new Set<string>(), out: number[][] = [];
  for (const m of legal(s, side)) { const k = m.from + ":" + m.to; if (!seen.has(k)) { seen.add(k); out.push([m.from, m.to]); } }
  return out;
}

/** счётчик позиций для проверки генератора ходов */
export function perft(s: ChessState, side: Color, depth: number): number {
  if (depth === 0) return 1;
  const foe: Color = side === "w" ? "b" : "w";
  let n = 0;
  for (const m of legal(s, side)) n += depth === 1 ? 1 : perft(apply(s, m, side), foe, depth - 1);
  return n;
}
