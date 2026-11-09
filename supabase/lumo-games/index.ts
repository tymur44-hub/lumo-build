// Lumo: игры вдвоём в чате — крестики-нолики, шашки, морской бой; ставки люменами
import { createClient } from "npm:@supabase/supabase-js@2";

const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });
const CORS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (d: unknown, status = 200) => new Response(JSON.stringify(d), { status, headers: { ...CORS, "Content-Type": "application/json; charset=utf-8" } });
class Err extends Error {}
const fail = (m: string): never => { throw new Err(m); };

export const TITLES: Record<string, string> = { ttt: "Крестики-нолики", checkers: "Шашки", sea: "Морской бой" };

// ---------- крестики-нолики ----------
const LINES = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]];
export function tttWinner(b: string): string | null {
  for (const [a, c, d] of LINES) if (b[a] !== "." && b[a] === b[c] && b[a] === b[d]) return b[a];
  return b.includes(".") ? null : "draw";
}

// ---------- шашки (русские) ----------
// доска — 64 символа: "." пусто, w/W — белые (p1, ходят вверх), b/B — чёрные (p2)
export function checkersStart(): string {
  let s = "";
  for (let r = 0; r < 8; r++) for (let c = 0; c < 8; c++) {
    const dark = (r + c) % 2 === 1;
    s += !dark ? "." : r < 3 ? "b" : r > 4 ? "w" : ".";
  }
  return s;
}
type Sq = [number, number];
const DIRS: Sq[] = [[-1, -1], [-1, 1], [1, -1], [1, 1]];
const at = (b: string[], r: number, c: number) => (r < 0 || r > 7 || c < 0 || c > 7 ? null : b[r * 8 + c]);
const own = (p: string, side: string) => p !== "." && p.toLowerCase() === side;
const foe = (p: string | null, side: string) => !!p && p !== "." && p.toLowerCase() !== side;

/** все допустимые ходы стороны: список путей (клетки посадки, начиная с исходной) и итоговая доска */
export function checkersMoves(board: string, side: "w" | "b"): { path: Sq[]; board: string; cap: number }[] {
  const b = board.split("");
  const caps: { path: Sq[]; board: string; cap: number }[] = [];
  const fwd = side === "w" ? -1 : 1;
  const lastRow = side === "w" ? 0 : 7;
  function canJump(bb: string[], r: number, c: number, king: boolean, taken: Set<number>): boolean {
    for (const [dr, dc] of DIRS) {
      if (king) {
        let rr = r + dr, cc = c + dc;
        while (at(bb, rr, cc) === ".") { rr += dr; cc += dc; }
        if (foe(at(bb, rr, cc), side) && !taken.has(rr * 8 + cc) && at(bb, rr + dr, cc + dc) === ".") return true;
      } else if (foe(at(bb, r + dr, c + dc), side) && !taken.has((r + dr) * 8 + c + dc) && at(bb, r + 2 * dr, c + 2 * dc) === ".") return true;
    }
    return false;
  }
  function jumps(bb: string[], r: number, c: number, king: boolean, path: Sq[], taken: Set<number>) {
    let any = false;
    for (const [dr, dc] of DIRS) {
      if (king) {
        let rr = r + dr, cc = c + dc;
        while (at(bb, rr, cc) === ".") { rr += dr; cc += dc; }
        const p = at(bb, rr, cc);
        if (!foe(p, side) || taken.has(rr * 8 + cc)) continue;
        let lr = rr + dr, lc = cc + dc;
        const lands: { nb: string[]; lr: number; lc: number; nt: Set<number> }[] = [];
        while (at(bb, lr, lc) === ".") {
          const nb = bb.slice(); nb[r * 8 + c] = "."; nb[lr * 8 + lc] = side.toUpperCase();
          const nt = new Set(taken); nt.add(rr * 8 + cc);
          lands.push({ nb, lr, lc, nt });
          lr += dr; lc += dc;
        }
        if (!lands.length) continue;
        any = true;
        // если с какой-то клетки можно бить дальше — дамка обязана встать туда
        const cont = lands.filter((L) => canJump(L.nb, L.lr, L.lc, true, L.nt));
        for (const L of cont.length ? cont : lands) jumps(L.nb, L.lr, L.lc, true, [...path, [L.lr, L.lc]], L.nt);
      } else {
        const p = at(bb, r + dr, c + dc);
        if (!foe(p, side) || taken.has((r + dr) * 8 + c + dc)) continue;
        if (at(bb, r + 2 * dr, c + 2 * dc) !== ".") continue;
        any = true;
        const lr = r + 2 * dr, lc = c + 2 * dc;
        const promote = lr === lastRow;
        const nb = bb.slice(); nb[r * 8 + c] = "."; nb[lr * 8 + lc] = promote ? side.toUpperCase() : side;
        const nt = new Set(taken); nt.add((r + dr) * 8 + c + dc);
        jumps(nb, lr, lc, promote, [...path, [lr, lc]], nt);
      }
    }
    if (!any && path.length > 1) {
      const fin = bb.slice();
      for (const i of taken) fin[i] = ".";
      caps.push({ path, board: fin.join(""), cap: taken.size });
    }
  }
  for (let r = 0; r < 8; r++) for (let c = 0; c < 8; c++) {
    const p = b[r * 8 + c];
    if (!own(p, side)) continue;
    jumps(b, r, c, p === p.toUpperCase(), [[r, c]], new Set());
  }
  if (caps.length) return caps;
  const quiet: { path: Sq[]; board: string; cap: number }[] = [];
  for (let r = 0; r < 8; r++) for (let c = 0; c < 8; c++) {
    const p = b[r * 8 + c];
    if (!own(p, side)) continue;
    const king = p === p.toUpperCase();
    for (const [dr, dc] of DIRS) {
      if (!king && dr !== fwd) continue;
      let rr = r + dr, cc = c + dc;
      while (at(b, rr, cc) === ".") {
        const nb = b.slice(); nb[r * 8 + c] = "."; nb[rr * 8 + cc] = king || rr === lastRow ? side.toUpperCase() : side;
        quiet.push({ path: [[r, c], [rr, cc]], board: nb.join(""), cap: 0 });
        if (!king) break;
        rr += dr; cc += dc;
      }
    }
  }
  return quiet;
}

// ---------- морской бой ----------
const FLEET = [4, 3, 3, 2, 2, 2, 1, 1, 1, 1];
type Ship = number[][]; // клетки [x,y]
export function seaRandom(): Ship[] {
  for (let attempt = 0; attempt < 200; attempt++) {
    const occ = new Set<number>(); const ships: Ship[] = []; let ok = true;
    for (const len of FLEET) {
      let placed = false;
      for (let t = 0; t < 300 && !placed; t++) {
        const hor = Math.random() < 0.5;
        const x = Math.floor(Math.random() * (hor ? 11 - len : 10)), y = Math.floor(Math.random() * (hor ? 10 : 11 - len));
        const cells: number[][] = [];
        for (let i = 0; i < len; i++) cells.push(hor ? [x + i, y] : [x, y + i]);
        if (cells.some(([cx, cy]) => { for (let dx = -1; dx <= 1; dx++) for (let dy = -1; dy <= 1; dy++) if (occ.has((cx + dx) * 10 + cy + dy) && cx + dx >= 0 && cy + dy >= 0 && cx + dx < 10 && cy + dy < 10) return true; return false; })) continue;
        cells.forEach(([cx, cy]) => occ.add(cx * 10 + cy)); ships.push(cells); placed = true;
      }
      if (!placed) { ok = false; break; }
    }
    if (ok) return ships;
  }
  fail("Не удалось расставить корабли");
  return [];
}

// ---------- общая часть ----------
async function profileName(id: string | null) {
  if (!id) return "";
  const { data } = await db.from("lm_profiles").select("name").eq("id", id).maybeSingle();
  return data?.name || "Игрок";
}
async function isMember(chat: string, uid: string) {
  const { data } = await db.from("lm_members").select("user_id").eq("chat_id", chat).eq("user_id", uid).maybeSingle();
  return !!data;
}
async function debit(uid: string, amount: number, chat: string) {
  if (amount <= 0) return;
  const { error } = await db.rpc("lm_game_debit", { p_user: uid, p_amount: amount, p_chat: chat });
  if (error) fail(error.message.includes("люменов") ? "Не хватает люменов для ставки" : error.message);
}
async function credit(uid: string, amount: number, chat: string, kind: string) {
  if (amount <= 0) return;
  await db.rpc("lm_game_credit", { p_user: uid, p_amount: amount, p_chat: chat, p_kind: kind });
}
// deno-lint-ignore no-explicit-any
type Game = Record<string, any>;
async function load(id: string): Promise<Game> {
  const { data } = await db.from("lm_games").select("*").eq("id", id).maybeSingle();
  if (!data) fail("Игра не найдена");
  return data as Game;
}
async function save(g: Game, patch: Game): Promise<Game> {
  const { data } = await db.from("lm_games").update({ ...patch, ver: g.ver + 1, updated_at: new Date().toISOString() })
    .eq("id", g.id).eq("ver", g.ver).select("*").maybeSingle();
  if (!data) fail("Состояние игры изменилось, попробуйте ещё раз");
  return data as Game;
}
async function syncMsg(g: Game) {
  if (!g.msg_id) return;
  const [p1n, p2n, wn] = await Promise.all([profileName(g.p1), profileName(g.p2), profileName(g.winner)]);
  const st = g.status;
  let body = TITLES[g.kind] + (g.stake ? ` · ставка ${g.stake}` : "");
  if (st === "done") body += g.winner ? ` · победил(а) ${wn}` : " · ничья";
  const { data: m } = await db.from("lm_messages").select("meta").eq("id", g.msg_id).maybeSingle();
  await db.from("lm_messages").update({ body, meta: { ...(m?.meta || {}), game: g.id, g: g.kind, stake: g.stake, st, p1: g.p1, p2: g.p2, p1n, p2n, winner: g.winner, wn, result: g.result } }).eq("id", g.msg_id);
}
async function finish(g: Game, patch: Game, winner: string | null, result: string) {
  const ng = await save(g, { ...patch, status: "done", winner, result, turn: null });
  if (g.stake > 0) {
    if (winner) await credit(winner, g.stake * 2, g.chat_id, "game_win");
    else { await credit(g.p1, g.stake, g.chat_id, "game_refund"); if (g.p2) await credit(g.p2, g.stake, g.chat_id, "game_refund"); }
  }
  return ng;
}
const other = (g: Game, uid: string) => (uid === g.p1 ? g.p2 : g.p1);

async function view(g: Game, me: string) {
  const out: Game = { ...g };
  const [p1n, p2n] = await Promise.all([profileName(g.p1), profileName(g.p2)]);
  out.p1n = p1n; out.p2n = p2n; out.me = me;
  if (g.kind === "sea") {
    const { data: sec } = await db.from("lm_game_secret").select("user_id,data").eq("game_id", g.id);
    const mine = (sec || []).find((s: Game) => s.user_id === me);
    out.myShips = mine?.data?.ships || null;
    // корабли соперника показываем только после конца игры
    if (g.status === "done") { const opp = (sec || []).find((s: Game) => s.user_id !== me); out.oppShips = opp?.data?.ships || null; }
  }
  if (g.kind === "checkers" && g.status === "active") {
    const side = g.turn === g.p1 ? "w" : "b";
    out.moves = checkersMoves(g.state.board, side).map((m) => m.path);
  }
  return out;
}

async function handle(me: string, b: Game) {
  const action = String(b.action || "");
  if (action === "new") {
    const chat = String(b.chat_id || ""), kind = String(b.kind || "");
    if (!TITLES[kind]) fail("Неизвестная игра");
    const stake = Math.floor(Number(b.stake) || 0);
    if (stake < 0 || stake > 1000) fail("Ставка — от 0 до 1000 люменов");
    const { data: ch } = await db.from("lm_chats").select("type").eq("id", chat).maybeSingle();
    if (!ch || ch.type === "channel") fail("Игры доступны в личных чатах и группах");
    if (!(await isMember(chat, me))) fail("Вы не участник чата");
    const { data: ban } = await db.from("lm_profiles").select("banned").eq("id", me).maybeSingle();
    if (ban?.banned) fail("Аккаунт заблокирован");
    const { count } = await db.from("lm_games").select("id", { count: "exact", head: true }).eq("p1", me).eq("status", "invite");
    if ((count || 0) >= 5) fail("У вас уже 5 непринятых приглашений — отмените старые");
    await debit(me, stake, chat);
    const state = kind === "ttt" ? { board: "........." } : kind === "checkers" ? { board: checkersStart(), quiet: 0, last: null } : { shots: {}, ready: {} };
    const { data: g, error } = await db.from("lm_games").insert({ chat_id: chat, kind, p1: me, stake, state }).select("*").single();
    if (error) { await credit(me, stake, chat, "game_refund"); fail(error.message); }
    const { data: m, error: me2 } = await db.from("lm_messages").insert({ chat_id: chat, sender_id: me, kind: "game", body: TITLES[kind], meta: { game: g.id, g: kind, stake, st: "invite" } }).select("id").single();
    if (me2 || !m) {
      await db.from("lm_games").delete().eq("id", g.id);
      await credit(me, stake, chat, "game_refund");
      fail(me2?.message || "Не удалось отправить приглашение");
    }
    const ng = await save(g, { msg_id: m?.id ?? null });
    await syncMsg(ng);
    return await view(ng, me);
  }
  const g = await load(String(b.game_id || ""));
  if (!(await isMember(g.chat_id, me))) fail("Вы не участник чата");
  const player = me === g.p1 || me === g.p2;

  if (action === "get") return await view(g, me);

  if (action === "join") {
    if (g.status !== "invite") fail("Приглашение уже неактуально");
    if (me === g.p1) fail("Нельзя играть с собой — дождитесь соперника");
    await debit(me, g.stake, g.chat_id);
    let ng: Game;
    try {
      ng = await save(g, { p2: me, status: g.kind === "sea" ? "setup" : "active", turn: g.kind === "sea" ? null : g.p1 });
    } catch (e) { await credit(me, g.stake, g.chat_id, "game_refund"); throw e; }
    await syncMsg(ng);
    return await view(ng, me);
  }
  if (action === "decline" || action === "cancel") {
    if (g.status !== "invite") fail("Приглашение уже неактуально");
    if (action === "cancel" && me !== g.p1) fail("Отменить может только автор");
    if (action === "decline" && me === g.p1) fail("Это ваше приглашение — его можно отменить");
    const ng = await save(g, { status: action === "cancel" ? "canceled" : "declined" });
    await credit(g.p1, g.stake, g.chat_id, "game_refund");
    await syncMsg(ng);
    return await view(ng, me);
  }
  if (!player) fail("Вы не участвуете в этой игре");

  if (action === "resign") {
    if (g.status !== "active" && g.status !== "setup") fail("Игра уже закончена");
    const ng = await finish(g, {}, other(g, me), "resign");
    await syncMsg(ng);
    return await view(ng, me);
  }
  if (action === "claim") {
    if (g.status !== "active" || g.turn === me) fail("Сейчас ваш ход");
    if (Date.now() - new Date(g.updated_at).getTime() < 24 * 3600 * 1000) fail("Соперник может думать до 24 часов");
    const ng = await finish(g, {}, me, "timeout");
    await syncMsg(ng);
    return await view(ng, me);
  }

  // ---------- морской бой: расстановка ----------
  if (g.kind === "sea" && (action === "shuffle" || action === "ready")) {
    if (g.status !== "setup") fail("Расстановка уже закончена");
    if (g.state.ready?.[me]) fail("Вы уже готовы");
    if (action === "shuffle") {
      const ships = seaRandom();
      await db.from("lm_game_secret").upsert({ game_id: g.id, user_id: me, data: { ships } });
      return await view(g, me);
    }
    const { data: sec } = await db.from("lm_game_secret").select("data").eq("game_id", g.id).eq("user_id", me).maybeSingle();
    if (!sec) await db.from("lm_game_secret").upsert({ game_id: g.id, user_id: me, data: { ships: seaRandom() } });
    const ready = { ...(g.state.ready || {}), [me]: true };
    const both = ready[g.p1] && ready[g.p2];
    const ng = await save(g, { state: { ...g.state, ready }, status: both ? "active" : "setup", turn: both ? g.p1 : null });
    if (both) await syncMsg(ng);
    return await view(ng, me);
  }

  if (action !== "move") fail("Неизвестное действие");
  if (g.status !== "active") fail("Игра не идёт");
  if (g.turn !== me) fail("Сейчас ход соперника");
  const opp = other(g, me)!;

  if (g.kind === "ttt") {
    const i = Math.floor(Number(b.i));
    const board: string = g.state.board;
    if (!(i >= 0 && i < 9) || board[i] !== ".") fail("Клетка занята");
    const nb = board.slice(0, i) + (me === g.p1 ? "x" : "o") + board.slice(i + 1);
    const w = tttWinner(nb);
    let ng: Game;
    if (w) ng = await finish(g, { state: { board: nb, last: i } }, w === "draw" ? null : me, w === "draw" ? "draw" : "line");
    else ng = await save(g, { state: { board: nb, last: i }, turn: opp });
    if (w) await syncMsg(ng);
    return await view(ng, me);
  }

  if (g.kind === "checkers") {
    const side = me === g.p1 ? "w" : "b";
    const path: Sq[] = Array.isArray(b.path) ? b.path.map((p: number[]) => [Number(p[0]), Number(p[1])] as Sq) : [];
    const moves = checkersMoves(g.state.board, side);
    const mv = moves.find((m) => m.path.length === path.length && m.path.every((s, k) => s[0] === path[k][0] && s[1] === path[k][1]));
    if (!mv) fail(moves.some((m) => m.cap > 0) ? "Нужно бить — взятие обязательно" : "Так ходить нельзя");
    const quiet = mv!.cap ? 0 : (g.state.quiet || 0) + 1;
    const state = { board: mv!.board, quiet, last: mv!.path };
    const oppMoves = checkersMoves(mv!.board, side === "w" ? "b" : "w");
    let ng: Game;
    if (!oppMoves.length) ng = await finish(g, { state }, me, "no_moves");
    else if (quiet >= 60) ng = await finish(g, { state }, null, "draw");
    else ng = await save(g, { state, turn: opp });
    if (ng.status === "done") await syncMsg(ng);
    return await view(ng, me);
  }

  // морской бой: выстрел
  const x = Math.floor(Number(b.x)), y = Math.floor(Number(b.y));
  if (!(x >= 0 && x < 10 && y >= 0 && y < 10)) fail("Мимо поля");
  const shots: Game = { ...(g.state.shots || {}) };
  const mine: { x: number; y: number; h: boolean; s?: boolean }[] = [...(shots[me] || [])];
  if (mine.some((s) => s.x === x && s.y === y)) fail("Сюда вы уже стреляли");
  const { data: sec } = await db.from("lm_game_secret").select("data").eq("game_id", g.id).eq("user_id", opp).maybeSingle();
  const ships: Ship[] = sec?.data?.ships || [];
  const ship = ships.find((s) => s.some(([sx, sy]) => sx === x && sy === y));
  mine.push({ x, y, h: !!ship });
  let sunk: number[][] | null = null;
  if (ship && ship.every(([sx, sy]) => mine.some((s) => s.x === sx && s.y === sy))) {
    sunk = ship;
    for (const s of mine) if (ship.some(([sx, sy]) => sx === s.x && sy === s.y)) s.s = true;
    // клетки вокруг потопленного корабля — заведомо пустые, отмечаем
    for (const [sx, sy] of ship) for (let dx = -1; dx <= 1; dx++) for (let dy = -1; dy <= 1; dy++) {
      const ax = sx + dx, ay = sy + dy;
      if (ax < 0 || ay < 0 || ax > 9 || ay > 9) continue;
      if (!mine.some((s) => s.x === ax && s.y === ay)) mine.push({ x: ax, y: ay, h: false });
    }
  }
  shots[me] = mine;
  const total = ships.reduce((n, s) => n + s.length, 0);
  const hits = mine.filter((s) => s.h).length;
  const state = { ...g.state, shots, last: { by: me, x, y, h: !!ship, sunk: !!sunk } };
  let ng: Game;
  if (total && hits >= total) ng = await finish(g, { state }, me, "fleet");
  else ng = await save(g, { state, turn: ship ? me : opp }); // попал — стреляет ещё раз
  if (ng.status === "done") await syncMsg(ng);
  return await view(ng, me);
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  try {
    const tok = (req.headers.get("authorization") || "").replace(/^Bearer\s+/i, "");
    const { data: u } = await db.auth.getUser(tok);
    if (!u?.user) return json({ error: "Войдите заново" }, 401);
    const b = await req.json().catch(() => ({}));
    return json(await handle(u.user.id, b));
  } catch (e) {
    if (e instanceof Err) return json({ error: e.message }, 400);
    console.log("games", String(e));
    return json({ error: "Ошибка сервера" }, 500);
  }
});
