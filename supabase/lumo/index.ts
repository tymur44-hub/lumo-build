// Lumo: раздача приложения для Тильды, TURN-серверы для звонков, уведомления в Telegram
import { createClient } from "npm:@supabase/supabase-js@2";

const SB_URL = Deno.env.get("SUPABASE_URL")!;
const SRK = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const db = createClient(SB_URL, SRK, { auth: { persistSession: false } });
const FN_URL = SB_URL + "/functions/v1/lumo";

const CORS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};
const json = (d: unknown, status = 200) =>
  new Response(JSON.stringify(d), { status, headers: { ...CORS, "Content-Type": "application/json; charset=utf-8" } });

// ---------- кэши ----------
let secCache: { t: number; v: Record<string, string> } | null = null;
async function secrets(force = false) {
  if (!force && secCache && Date.now() - secCache.t < 30000) return secCache.v;
  const { data } = await db.from("lm_secrets").select("key,value");
  const v: Record<string, string> = {};
  (data || []).forEach((r: { key: string; value: string }) => (v[r.key] = r.value));
  secCache = { t: Date.now(), v };
  return v;
}
let libCache: { t: number; s: string } | null = null;
async function supabaseLib() {
  if (libCache && Date.now() - libCache.t < 12 * 3600e3) return libCache.s;
  for (const u of [
    "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.js",
    "https://unpkg.com/@supabase/supabase-js@2/dist/umd/supabase.js",
  ]) {
    try {
      const r = await fetch(u);
      if (r.ok) {
        const s = await r.text();
        if (s.length > 10000) { libCache = { t: Date.now(), s }; return s; }
      }
    } catch (_) { /* следующее зеркало */ }
  }
  return libCache?.s || "";
}
// исправления поверх кода из базы (баги звонков, «был в сети», телефонная вёрстка и др.)
const PATCHES: [string, string][] = [];
const CODE_NAME = "app13";
let appCache: { t: number; s: string; v: string } | null = null;
async function appCode() {
  if (appCache && Date.now() - appCache.t < 20000) return appCache;
  const { data } = await db.from("lm_code").select("part,content,updated_at").eq("name", CODE_NAME).order("part");
  const rows = data || [];
  let s = rows.map((r: { content: string }) => r.content).join("");
  let miss = 0;
  for (const [o, n] of PATCHES) {
    const i = s.indexOf(o);
    if (i < 0) { miss++; continue; }
    s = s.slice(0, i) + n + s.slice(i + o.length);
  }
  const v = (rows.map((r: { updated_at: string }) => r.updated_at).sort().pop() || "0") + "+p" + PATCHES.length + (miss ? "-miss" + miss : "");
  appCache = { t: Date.now(), s, v };
  return appCache;
}

// ---------- внешние библиотеки (QR-код, сканер) через нашу функцию: CDN может быть недоступен у провайдера ----------
const LIBSRC: Record<string, string[]> = {
  "qr.js": ["https://cdn.jsdelivr.net/npm/qrcode-generator@1.4.4/qrcode.min.js", "https://unpkg.com/qrcode-generator@1.4.4/qrcode.js"],
  "jsqr.js": ["https://cdn.jsdelivr.net/npm/jsqr@1.4.0/dist/jsQR.min.js", "https://unpkg.com/jsqr@1.4.0/dist/jsQR.js"],
};
const libStore: Record<string, { t: number; s: string }> = {};
async function extLib(name: string) {
  const c = libStore[name];
  if (c && Date.now() - c.t < 24 * 3600e3) return c.s;
  for (const u of LIBSRC[name] || []) {
    try {
      const r = await fetch(u);
      if (r.ok) {
        const t = await r.text();
        if (t.length > 1000) {
          const s = `(function(define,module,exports){\n${t}\n;if(typeof qrcode!=='undefined')window.qrcode=qrcode;}).call(window);`;
          libStore[name] = { t: Date.now(), s };
          return s;
        }
      }
    } catch (_) { /* следующее зеркало */ }
  }
  return c?.s || "";
}

// ---------- вход по QR-коду: подтверждённое с телефона устройство получает одноразовый ключ входа ----------
async function handleQr(req: Request) {
  const jwt = (req.headers.get("authorization") || "").replace(/^Bearer\s+/i, "");
  const { data: u } = await db.auth.getUser(jwt);
  if (!u?.user?.email) return json({ error: "unauthorized" }, 401);
  const { data, error } = await db.auth.admin.generateLink({ type: "magiclink", email: u.user.email });
  const th = (data as { properties?: { hashed_token?: string } })?.properties?.hashed_token;
  if (error || !th) return json({ error: String(error?.message || "no token") }, 500);
  return json({ th });
}

// ---------- Web Push (уведомления установленного на главный экран приложения) ----------
const enc = new TextEncoder();
function b64u(buf: ArrayBuffer | Uint8Array) { const b = buf instanceof Uint8Array ? buf : new Uint8Array(buf); let s = ""; for (const x of b) s += String.fromCharCode(x); return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, ""); }
function ub64u(s: string) { s = s.replace(/-/g, "+").replace(/_/g, "/"); while (s.length % 4) s += "="; const bin = atob(s); const u = new Uint8Array(bin.length); for (let i = 0; i < bin.length; i++) u[i] = bin.charCodeAt(i); return u; }
function cat(...a: Uint8Array[]) { const n = a.reduce((x, y) => x + y.length, 0); const o = new Uint8Array(n); let p = 0; for (const x of a) { o.set(x, p); p += x.length; } return o; }
async function hkdf(salt: Uint8Array, ikm: Uint8Array, info: Uint8Array, len: number) { const k = await crypto.subtle.importKey("raw", ikm, "HKDF", false, ["deriveBits"]); return new Uint8Array(await crypto.subtle.deriveBits({ name: "HKDF", hash: "SHA-256", salt, info }, k, len * 8)); }
async function wpEncrypt(p256dh: string, authSecret: string, payload: Uint8Array) {
  const uaPub = ub64u(p256dh), auth = ub64u(authSecret);
  const kp = await crypto.subtle.generateKey({ name: "ECDH", namedCurve: "P-256" }, true, ["deriveBits"]);
  const asPub = new Uint8Array(await crypto.subtle.exportKey("raw", kp.publicKey));
  const uaKey = await crypto.subtle.importKey("raw", uaPub, { name: "ECDH", namedCurve: "P-256" }, false, []);
  const shared = new Uint8Array(await crypto.subtle.deriveBits({ name: "ECDH", public: uaKey }, kp.privateKey, 256));
  const ikm = await hkdf(auth, shared, cat(enc.encode("WebPush: info\0"), uaPub, asPub), 32);
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const cek = await hkdf(salt, ikm, enc.encode("Content-Encoding: aes128gcm\0"), 16);
  const nonce = await hkdf(salt, ikm, enc.encode("Content-Encoding: nonce\0"), 12);
  const key = await crypto.subtle.importKey("raw", cek, "AES-GCM", false, ["encrypt"]);
  const ct = new Uint8Array(await crypto.subtle.encrypt({ name: "AES-GCM", iv: nonce }, key, cat(payload, new Uint8Array([2]))));
  const rs = new Uint8Array([0, 0, 16, 0]);
  return cat(salt, rs, new Uint8Array([asPub.length]), asPub, ct);
}
async function vapidHeader(endpoint: string, jwk: { x: string; y: string; d: string }, pub: string, sub: string) {
  const aud = new URL(endpoint).origin;
  const h = b64u(enc.encode(JSON.stringify({ typ: "JWT", alg: "ES256" })));
  const p = b64u(enc.encode(JSON.stringify({ aud, exp: Math.floor(Date.now() / 1000) + 12 * 3600, sub })));
  const key = await crypto.subtle.importKey("jwk", { kty: "EC", crv: "P-256", x: jwk.x, y: jwk.y, d: jwk.d }, { name: "ECDSA", namedCurve: "P-256" }, false, ["sign"]);
  const sig = new Uint8Array(await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, key, enc.encode(h + "." + p)));
  return `vapid t=${h}.${p}.${b64u(sig)}, k=${pub}`;
}
async function newVapid() {
  const kp = await crypto.subtle.generateKey({ name: "ECDSA", namedCurve: "P-256" }, true, ["sign", "verify"]);
  const jwk = await crypto.subtle.exportKey("jwk", kp.privateKey);
  const pub = b64u(await crypto.subtle.exportKey("raw", kp.publicKey));
  return { jwk: { x: jwk.x, y: jwk.y, d: jwk.d }, pub };
}
let vapidCache: { jwk: { x: string; y: string; d: string }; pub: string } | null = null;
async function vapid() {
  if (vapidCache) return vapidCache;
  let s = await secrets();
  if (!s.vapid) {
    const nv = await newVapid();
    await db.from("lm_secrets").upsert({ key: "vapid", value: JSON.stringify(nv) }, { onConflict: "key", ignoreDuplicates: true });
    s = await secrets(true);
  }
  vapidCache = JSON.parse(s.vapid);
  return vapidCache!;
}
async function pushUsers(ids: string[], data: Record<string, unknown>, ttl = 86400) {
  if (!ids.length) return 0;
  const { data: subs } = await db.from("lm_push").select("endpoint,p256dh,auth").in("user_id", ids);
  if (!subs?.length) return 0;
  const v = await vapid();
  const subj = (await secrets()).vapid_sub || "https://volshebny-mir.ru";
  const payload = new TextEncoder().encode(JSON.stringify(data));
  let n = 0;
  await Promise.all(subs.map(async (x: { endpoint: string; p256dh: string; auth: string }) => {
    try {
      const body = await wpEncrypt(x.p256dh, x.auth, payload);
      const r = await fetch(x.endpoint, { method: "POST", body, headers: {
        "Content-Encoding": "aes128gcm", "Content-Type": "application/octet-stream", TTL: String(ttl), Urgency: "high",
        Authorization: await vapidHeader(x.endpoint, v.jwk, v.pub, subj) } });
      if (r.status === 404 || r.status === 410) await db.from("lm_push").delete().eq("endpoint", x.endpoint);
      else if (r.ok) n++;
      else console.log("push", r.status, (await r.text()).slice(0, 200));
    } catch (e) { console.log("push error", String(e)); }
  }));
  return n;
}
const isActive = (p?: { app_active?: boolean; last_seen?: string } | null) =>
  !!(p && p.app_active && p.last_seen && Date.now() - new Date(p.last_seen).getTime() < 100000);
function plainPrev(m: { kind: string; body: string | null; meta: Record<string, unknown> }) {
  const enc = !!m.body && String(m.body).startsWith("e2e1:");
  const b = m.body && !enc ? String(m.body).replace(/```|`|\*\*|__|~~/g, "").slice(0, 200) : "";
  if (enc && (m.kind === "text" || m.kind === "image" || m.kind === "video")) return m.kind === "text" ? "🔒 Новое сообщение" : (m.kind === "image" ? "🖼 Фото" : "🎬 Видео");
  switch (m.kind) {
    case "voice": return "🎤 Голосовое сообщение";
    case "video_note": return "⏺ Видеосообщение";
    case "image": return "🖼 Фото" + (b ? ": " + b : "");
    case "video": return "🎬 Видео" + (b ? ": " + b : "");
    case "file": return "📎 " + String(m.meta?.name || "Файл");
    case "sticker": return (m.body || "") + " Стикер";
    default: return b;
  }
}

// ---------- TURN ----------
async function iceServers() {
  const exp = Math.floor(Date.now() / 1000) + 24 * 3600;
  const username = `${exp}:lumo`;
  const key = await crypto.subtle.importKey("raw", new TextEncoder().encode("openrelayprojectsecret"),
    { name: "HMAC", hash: "SHA-1" }, false, ["sign"]);
  const sig = new Uint8Array(await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(username)));
  const credential = btoa(String.fromCharCode(...sig));
  const h = "staticauth.openrelay.metered.ca";
  const list: unknown[] = [
    { urls: ["stun:stun.l.google.com:19302", "stun:stun.cloudflare.com:3478"] },
    { urls: [`turn:${h}:80`, `turn:${h}:80?transport=tcp`, `turn:${h}:443`, `turn:${h}:443?transport=tcp`, `turns:${h}:443?transport=tcp`], username, credential },
    { urls: ["turn:openrelay.metered.ca:80", "turn:openrelay.metered.ca:443", "turn:openrelay.metered.ca:443?transport=tcp", "turns:openrelay.metered.ca:443?transport=tcp"], username: "openrelayproject", credential: "openrelayproject" },
  ];
  const s = await secrets();
  // свой TURN (Metered): постоянные логин и пароль из lm_secrets — первыми в списке
  if (s.metered_user && s.metered_pass) {
    const g = "global.relay.metered.ca";
    list.unshift(
      { urls: ["stun:stun.relay.metered.ca:80"] },
      { urls: [`turn:${g}:80`, `turn:${g}:80?transport=tcp`, `turn:${g}:443`, `turns:${g}:443?transport=tcp`], username: s.metered_user, credential: s.metered_pass },
    );
  }
  if (s.metered_app && s.metered_key) {
    try {
      const r = await fetch(`https://${s.metered_app}.metered.live/api/v1/turn/credentials?apiKey=${s.metered_key}`);
      if (r.ok) { const own = await r.json(); if (Array.isArray(own) && own.length) return [...own, ...list]; }
    } catch (_) { /* остаёмся на открытых */ }
  }
  return list;
}

// ---------- Telegram ----------
async function tg(method: string, body: unknown) {
  const s = await secrets();
  if (!s.tg_token) return null;
  try {
    const r = await fetch(`https://api.telegram.org/bot${s.tg_token}/${method}`, {
      method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(body),
    });
    return await r.json();
  } catch (_) { return null; }
}
const escH = (t: string) => String(t ?? "").replace(/[&<>]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;" }[c]!));
function preview(m: { kind: string; body: string | null; meta: Record<string, unknown> }) {
  const enc = !!m.body && String(m.body).startsWith("e2e1:");
  const b = m.body && !enc ? escH(String(m.body).slice(0, 300)) : "";
  if (enc && m.kind === "text") return "🔒 Новое сообщение";
  switch (m.kind) {
    case "voice": return "🎤 Голосовое сообщение";
    case "video_note": return "⏺ Видеосообщение";
    case "image": return "🖼 Фото" + (b ? ": " + b : "");
    case "video": return "🎬 Видео" + (b ? ": " + b : "");
    case "file": return "📎 " + escH(String(m.meta?.name || "Файл"));
    case "sticker": return (m.body || "") + " Стикер";
    case "call": return "📞 Звонок";
    default: return b;
  }
}
// кнопки открывают Lumo как мини-приложение прямо в Telegram; chatId — сразу нужный чат
async function appUrl(chatId?: string) {
  const s = await secrets();
  if (!s.site_url) return "";
  return chatId ? s.site_url + (s.site_url.includes("?") ? "&" : "?") + "c=" + encodeURIComponent(chatId) : s.site_url;
}
async function openButton(chatId?: string, text?: string) {
  const u = await appUrl(chatId);
  return u ? { inline_keyboard: [[{ text: text || "Открыть Lumo", web_app: { url: u } }]] } : undefined;
}
const ACTIVE_MS = 75000; // пользователь сейчас в приложении — в Telegram не дублируем

async function handleNotify(messageId: number) {
  const { data: m } = await db.from("lm_messages").select("*").eq("id", messageId).maybeSingle();
  if (!m || m.kind === "system" || m.deleted) return;
  const st = (m.meta || {}).status;
  if (m.kind === "call" && (st === "ended" || st === "rejected")) return;
  const { data: chat } = await db.from("lm_chats").select("*").eq("id", m.chat_id).maybeSingle();
  const { data: mem } = await db.from("lm_members").select("user_id,muted").eq("chat_id", m.chat_id);
  const targets = (mem || []).filter((x: { user_id: string; muted: boolean }) => x.user_id !== m.sender_id && !x.muted).map((x: { user_id: string }) => x.user_id);
  if (!targets.length) return;
  const { data: profs } = await db.from("lm_profiles").select("id,name,last_seen,app_active").in("id", [m.sender_id, ...targets]);
  const P = new Map((profs || []).map((p: { id: string }) => [p.id, p]));
  const realSender = (P.get(m.sender_id) as { name?: string })?.name || "Пользователь";
  const idle = targets.filter((id: string) => !isActive(P.get(id) as { app_active?: boolean; last_seen?: string }));
  // имя отправителя так, как его записал получатель у себя в контактах
  const aliasOf = new Map<string, string>();
  if (idle.length) {
    const { data: al } = await db.from("lm_contacts").select("owner_id,alias").eq("contact_id", m.sender_id).in("owner_id", idle);
    (al || []).forEach((r: { owner_id: string; alias: string | null }) => { if (r.alias && r.alias.trim()) aliasOf.set(r.owner_id, r.alias.trim()); });
  }
  const senderFor = (uid: string) => aliasOf.get(uid) || realSender;
  const titleBody = (uid: string) => {
    const sender = senderFor(uid);
    if (m.kind === "call") return { title: sender, body: (m.meta || {}).video ? "📞 Пропущенный видеозвонок" : "📞 Пропущенный звонок" };
    if (chat?.type === "private") return { title: sender, body: plainPrev(m) };
    if (chat?.type === "channel") return { title: chat.title || "Канал", body: plainPrev(m) };
    return { title: chat?.title || "Группа", body: sender + ": " + plainPrev(m) };
  };
  const pushP = (async () => {
    // личный E2E-чат: шифртекст едет в пуше, текст расшифровывается на устройстве
    if (m.kind === "text" && m.body && String(m.body).startsWith("e2e1:") && chat?.type === "private" && String(m.body).length < 2600) {
      const { data: kk } = await db.from("lm_keys").select("pub").eq("user_id", m.sender_id).maybeSingle();
      for (const id of idle) await pushUsers([id], { ...titleBody(id), tag: "c" + m.chat_id, chat: m.chat_id, e: m.body, p: kk?.pub || null, u: id });
      return;
    }
    const withAlias = idle.filter((id: string) => aliasOf.has(id)), plain = idle.filter((id: string) => !aliasOf.has(id));
    await Promise.all([
      plain.length ? pushUsers(plain, { ...titleBody(plain[0]), tag: "c" + m.chat_id, chat: m.chat_id }) : Promise.resolve(0),
      ...withAlias.map((id: string) => pushUsers([id], { ...titleBody(id), tag: "c" + m.chat_id, chat: m.chat_id })),
    ]);
  })();
  // Telegram
  const tgP = (async () => {
    const { data: links } = await db.from("lm_tg_links").select("*").in("user_id", idle).eq("enabled", true);
    if (!links?.length) return;
    const kb = await openButton(String(m.chat_id), m.kind === "call" ? "📞 Перезвонить" : "↩️ Ответить");
    await Promise.all(links.map((l: { tg_chat_id: number; user_id: string }) => {
      const sender = senderFor(l.user_id);
      let head: string;
      if (chat?.type === "private") head = `💬 <b>${escH(sender)}</b>`;
      else if (chat?.type === "channel") head = `📢 <b>${escH(chat.title || "Канал")}</b>`;
      else head = `👥 <b>${escH(chat?.title || "Группа")}</b>\n<b>${escH(sender)}:</b>`;
      if (m.kind === "call") head = `📞 <b>Пропущенный ${(m.meta || {}).video ? "видеозвонок" : "звонок"}</b> от ${escH(sender)}`;
      const text = m.kind === "call" ? head : `${head}\n${preview(m)}`;
      return tg("sendMessage", { chat_id: l.tg_chat_id, text, parse_mode: "HTML", reply_markup: kb, disable_web_page_preview: true });
    }));
  })();
  await Promise.all([pushP, tgP]);
}

async function handleCall(req: Request) {
  const jwt = (req.headers.get("authorization") || "").replace(/^Bearer\s+/i, "");
  const { data: u } = await db.auth.getUser(jwt);
  if (!u?.user) return json({ error: "unauthorized" }, 401);
  const { peer_id, video } = await req.json();
  const me = u.user.id;
  const key = me < peer_id ? `${me}:${peer_id}` : `${peer_id}:${me}`;
  const { data: chat } = await db.from("lm_chats").select("id").eq("dm_key", key).maybeSingle();
  if (!chat) return json({ error: "no chat" }, 403);
  const { data: mem } = await db.from("lm_members").select("muted").eq("chat_id", chat.id).eq("user_id", peer_id).maybeSingle();
  if (mem?.muted) return json({ ok: true, tg: false, push: 0 });
  const { data: p } = await db.from("lm_profiles").select("name").eq("id", me).maybeSingle();
  const { data: pp } = await db.from("lm_profiles").select("last_seen,app_active").eq("id", peer_id).maybeSingle();
  const { data: ct } = await db.from("lm_contacts").select("alias").eq("owner_id", peer_id).eq("contact_id", me).maybeSingle();
  const name = (ct?.alias && String(ct.alias).trim()) || p?.name || "Кто-то";
  let pushed = 0;
  if (!isActive(pp)) pushed = await pushUsers([peer_id], { title: name, body: video ? "📹 Входящий видеозвонок" : "📞 Входящий звонок", tag: "call", chat: chat.id, call: true }, 45);
  const { data: link } = await db.from("lm_tg_links").select("*").eq("user_id", peer_id).eq("enabled", true).maybeSingle();
  if (link) await tg("sendMessage", {
    chat_id: link.tg_chat_id, parse_mode: "HTML", reply_markup: await openButton(String(chat.id), "📞 Открыть звонок"),
    text: `📞 <b>${escH(name)}</b> звонит вам в Lumo${video ? " (видео)" : ""}.\nОткройте приложение, чтобы ответить.`,
  });
  return json({ ok: true, tg: !!link, push: pushed });
}

// ---------- вход и регистрация через Telegram ----------
const KEY_RE = /^[A-Za-z0-9_-]{16,64}$/;
// deno-lint-ignore no-explicit-any
async function tgLoginAsk(chatId: number, msg: any, key: string) {
  if (msg.chat?.type !== "private") return;
  if (!KEY_RE.test(key)) { await tg("sendMessage", { chat_id: chatId, text: "Ссылка для входа неверная. Откройте Lumo и нажмите «Войти через Telegram» ещё раз." }); return; }
  const { data: links } = await db.from("lm_tg_links").select("user_id").eq("tg_chat_id", chatId).limit(1);
  const has = !!links?.length;
  await tg("sendMessage", { chat_id: chatId, parse_mode: "HTML",
    text: has ? "🔐 <b>Вход в Lumo</b>\n\nНажмите кнопку, чтобы войти в свой аккаунт.\n<i>Если вы не нажимали «Войти через Telegram» на сайте Lumo — ничего не делайте.</i>"
              : "👋 <b>Регистрация в Lumo</b>\n\nНажмите кнопку — аккаунт создастся из вашего профиля Telegram, и вы сразу войдёте.\n\n<b>Уже есть аккаунт Lumo?</b> Тогда не нажимайте: войдите по юзернейму и паролю и в Настройках нажмите «Привязать» у «Уведомления в Telegram» — после этого вход через Telegram будет открывать ваш аккаунт.\n<i>Если вы не нажимали «Войти через Telegram» на сайте Lumo — ничего не делайте.</i>",
    reply_markup: { inline_keyboard: [[{ text: has ? "✅ Войти в Lumo" : "✅ Создать аккаунт и войти", callback_data: "L:" + key }]] } });
}
// найти аккаунт Lumo, привязанный к Telegram, или (create) создать новый
// deno-lint-ignore no-explicit-any
async function tgAccount(chatId: number, from: any, create: boolean): Promise<{ uid: string; isNew: boolean; uname: string } | string> {
  const name = ([from?.first_name, from?.last_name].filter(Boolean).join(" ") || from?.username || "Пользователь").slice(0, 64);
  let uid: string | null = null, isNew = false, uname = "";
  const { data: links } = await db.from("lm_tg_links").select("user_id,created_at").eq("tg_chat_id", chatId).order("created_at", { ascending: false }).limit(1);
  if (links?.length) uid = links[0].user_id;
  if (!uid && !create) return "nolink";
  if (!uid) {
    const base = String(from?.username || "").toLowerCase().replace(/[^a-z0-9_]/g, "");
    const stem = base.length >= 3 ? base.slice(0, 24) : "tg" + String(from?.id || chatId).slice(-10);
    const cands: string[] = [];
    if (base.length >= 3) cands.push(base.slice(0, 32));
    cands.push(stem);
    for (let i = 0; i < 6; i++) cands.push(stem + "_" + Math.floor(Math.random() * 90000 + 10000));
    for (const u of cands) {
      const { data, error } = await db.rpc("lm_register_tg", { p_username: u, p_name: name });
      if (!error && data) { uid = String(data); uname = u; isNew = true; break; }
      if (error) console.log("tg reg", u, error.message);
    }
    if (!uid) return "Не удалось создать аккаунт, попробуйте ещё раз";
    await db.from("lm_tg_links").upsert({ user_id: uid, tg_chat_id: chatId, tg_name: name, enabled: true });
  }
  return { uid, isNew, uname };
}
async function magic(uid: string) {
  const { data: u } = await db.auth.admin.getUserById(uid);
  const email = u?.user?.email;
  if (!email) return null;
  const { data: gl } = await db.auth.admin.generateLink({ type: "magiclink", email });
  return (gl as { properties?: { hashed_token?: string } })?.properties?.hashed_token || null;
}
// проверка подписи данных мини-приложения (https://core.telegram.org/bots/webapps#validating-data-received-via-the-mini-app)
async function hmac(key: Uint8Array, msg: string) {
  const k = await crypto.subtle.importKey("raw", key, { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  return new Uint8Array(await crypto.subtle.sign("HMAC", k, new TextEncoder().encode(msg)));
}
// deno-lint-ignore no-explicit-any
async function tgInitUser(init: string): Promise<any | null> {
  const s = await secrets();
  if (!s.tg_token || !init) return null;
  const p = new URLSearchParams(init);
  const hash = p.get("hash") || "";
  p.delete("hash");
  const dcs = [...p.entries()].sort((a, b) => (a[0] < b[0] ? -1 : a[0] > b[0] ? 1 : 0)).map(([k, v]) => k + "=" + v).join("\n");
  const secret = await hmac(new TextEncoder().encode("WebAppData"), s.tg_token);
  const calc = Array.from(await hmac(secret, dcs)).map((x) => x.toString(16).padStart(2, "0")).join("");
  if (calc !== hash) return null;
  const ad = Number(p.get("auth_date") || 0);
  if (!ad || Date.now() / 1000 - ad > 7 * 86400) return null;
  try { const u = JSON.parse(p.get("user") || "null"); return u && u.id ? u : null; } catch (_) { return null; }
}
async function handleTgApp(req: Request) {
  let b: { init?: string; uid?: string; create?: boolean; link?: boolean } = {};
  try { b = JSON.parse(await req.text() || "{}"); } catch (_) { /* пусто */ }
  const tu = await tgInitUser(String(b.init || ""));
  if (!tu) return json({ error: "bad init" }, 403);
  const chatId = Number(tu.id);
  const name = ([tu.first_name, tu.last_name].filter(Boolean).join(" ") || tu.username || "").slice(0, 64);
  if (b.link) {
    const jwt = (req.headers.get("authorization") || "").replace(/^Bearer\s+/i, "");
    const { data: u } = await db.auth.getUser(jwt);
    if (!u?.user) return json({ error: "unauthorized" }, 401);
    const { error } = await db.from("lm_tg_links").upsert({ user_id: u.user.id, tg_chat_id: chatId, tg_name: name, enabled: true });
    return json({ ok: !error });
  }
  const r = await tgAccount(chatId, tu, !!b.create);
  if (typeof r === "string") return json(r === "nolink" ? { nolink: true } : { error: r });
  if (b.uid && b.uid === r.uid) return json({ same: true });
  const th = await magic(r.uid);
  if (!th) return json({ error: "Не удалось войти" });
  let uname = r.uname;
  if (!uname) { const { data: p } = await db.from("lm_profiles").select("username").eq("id", r.uid).maybeSingle(); uname = p?.username || ""; }
  return json({ th, new: r.isNew, username: uname });
}
// deno-lint-ignore no-explicit-any
async function tgLoginDo(chatId: number, from: any, key: string): Promise<string> {
  if (!KEY_RE.test(key)) return "Ссылка неверная";
  const { data: ex } = await db.from("lm_tg_auth").select("key").eq("key", key).maybeSingle();
  if (ex) return "Вход уже подтверждён — вернитесь в Lumo";
  const r = await tgAccount(chatId, from, true);
  if (typeof r === "string") return r;
  const { uid, isNew } = r; let uname = r.uname;
  const th = await magic(uid);
  if (!th) return "Не удалось войти, попробуйте ещё раз";
  if (!uname) { const { data: p } = await db.from("lm_profiles").select("username").eq("id", uid).maybeSingle(); uname = p?.username || ""; }
  const { error: e2 } = await db.from("lm_tg_auth").insert({ key, th, user_id: uid, is_new: isNew, username: uname });
  if (e2) return "Вход уже подтверждён — вернитесь в Lumo";
  await tg("sendMessage", { chat_id: chatId, parse_mode: "HTML", reply_markup: await openButton(),
    text: (isNew ? `🎉 Аккаунт создан: <b>@${escH(uname)}</b>\nИмя и юзернейм можно поменять в настройках Lumo.\n\n` : `✅ Вход подтверждён: <b>@${escH(uname)}</b>\n\n`)
      + "Вернитесь в браузер — Lumo откроется сам.\nСюда будут приходить уведомления о сообщениях и звонках, когда Lumo закрыт. Отвечать можно прямо здесь — кнопкой «Ответить»." });
  return "ok";
}

async function handleTelegram(req: Request) {
  const s = await secrets();
  if (req.headers.get("x-telegram-bot-api-secret-token") !== s.hook_secret) return new Response("forbidden", { status: 403 });
  const upd = await req.json();
  const cq = upd.callback_query;
  if (cq?.data && String(cq.data).startsWith("L:") && cq.message?.chat?.id) {
    const r = await tgLoginDo(cq.message.chat.id, cq.from, String(cq.data).slice(2));
    await tg("answerCallbackQuery", { callback_query_id: cq.id, text: r === "ok" ? "Готово!" : r, show_alert: r !== "ok" });
    if (r === "ok") await tg("editMessageReplyMarkup", { chat_id: cq.message.chat.id, message_id: cq.message.message_id, reply_markup: { inline_keyboard: [] } });
    return new Response("ok");
  }
  if (cq?.id) { await tg("answerCallbackQuery", { callback_query_id: cq.id }); return new Response("ok"); }
  const msg = upd.message;
  if (!msg?.chat?.id) return new Response("ok");
  const chatId = msg.chat.id;
  const text: string = msg.text || "";
  const name = [msg.from?.first_name, msg.from?.last_name].filter(Boolean).join(" ") || msg.from?.username || "";
  const kb = await openButton();
  if (text.startsWith("/start")) {
    const code = text.split(/\s+/)[1];
    if (code && code.startsWith("l_")) { await tgLoginAsk(chatId, msg, code.slice(2)); return new Response("ok"); }
    if (code) {
      const { data: c } = await db.from("lm_tg_codes").select("user_id,created_at").eq("code", code).maybeSingle();
      if (c && Date.now() - new Date(c.created_at).getTime() < 24 * 3600e3) {
        await db.from("lm_tg_links").upsert({ user_id: c.user_id, tg_chat_id: chatId, tg_name: name, enabled: true });
        await db.from("lm_tg_codes").update({ code: crypto.randomUUID() }).eq("user_id", c.user_id);
        const { data: p } = await db.from("lm_profiles").select("name,username").eq("id", c.user_id).maybeSingle();
        await tg("sendMessage", { chat_id: chatId, parse_mode: "HTML", reply_markup: kb,
          text: `✅ Готово! Уведомления Lumo подключены для <b>${escH(p?.name || "")}</b> (@${escH(p?.username || "")}).\n\nСюда будут приходить новые сообщения и звонки, когда приложение закрыто.\nОтключить: /stop` });
        return new Response("ok");
      }
      await tg("sendMessage", { chat_id: chatId, text: "Ссылка устарела. Откройте Lumo → Настройки → «Уведомления в Telegram» и нажмите «Подключить» ещё раз.", reply_markup: kb });
      return new Response("ok");
    }
    await tg("sendMessage", { chat_id: chatId, reply_markup: kb,
      text: "👋 Это бот мессенджера Lumo.\nОткройте Lumo кнопкой ниже или кнопкой «Lumo» слева от поля ввода — мессенджер откроется прямо здесь, в Telegram. Если ваш Telegram уже привязан к аккаунту, вход выполнится сам." });
    return new Response("ok");
  }
  if (text.startsWith("/stop")) {
    await db.from("lm_tg_links").update({ enabled: false }).eq("tg_chat_id", chatId);
    await tg("sendMessage", { chat_id: chatId, text: "🔕 Уведомления отключены. Включить снова можно в настройках Lumo." });
    return new Response("ok");
  }
  await tg("sendMessage", { chat_id: chatId, reply_markup: kb, text: "Я присылаю уведомления. Ответить можно прямо в Telegram — откройте Lumo кнопкой ниже 👇" });
  return new Response("ok");
}

async function handleSetup() {
  const s = await secrets(true);
  if (!s.tg_token) return json({ error: "no token" }, 400);
  const me = await tg("getMe", {});
  if (!me?.ok) return json({ error: "bad token", me }, 400);
  await db.from("lm_secrets").upsert({ key: "tg_bot_username", value: me.result.username });
  const wh = await tg("setWebhook", { url: FN_URL + "/tg", secret_token: s.hook_secret, allowed_updates: ["message", "callback_query"], drop_pending_updates: true });
  if (s.site_url) await tg("setChatMenuButton", { menu_button: { type: "web_app", text: "Lumo", web_app: { url: s.site_url } } });
  await tg("setMyCommands", { commands: [{ command: "start", description: "Подключить уведомления" }, { command: "stop", description: "Отключить уведомления" }] });
  secCache = null;
  return json({ ok: true, bot: me.result.username, webhook: wh });
}

// ---------- резервный маршрут: прокси-серверу отдаём конфиг xray на случай, если его исходящее соединение с Supabase окажется заблокировано ----------
async function handleXraySetup() {
  const token = Array.from(crypto.getRandomValues(new Uint8Array(16))).map((b) => b.toString(16).padStart(2, "0")).join("");
  const exp = Date.now() + 15 * 60000;
  await db.from("lm_secrets").upsert([
    { key: "xray_token", value: token },
    { key: "xray_token_exp", value: String(exp) },
  ]);
  secCache = null;
  return json({ token, expires_in: 900 });
}
async function handleXrayCfg(req: Request) {
  const t = new URL(req.url).searchParams.get("t") || "";
  const s = await secrets(true);
  if (!t || !s.xray_token || t !== s.xray_token || Date.now() > Number(s.xray_token_exp || 0)) {
    return json({ error: "forbidden" }, 403);
  }
  // одноразовый токен — сразу гасим, повторно этот же t больше не сработает
  await db.from("lm_secrets").update({ value: "" }).eq("key", "xray_token");
  secCache = null;
  const { data: node } = await db.from("lm_nodes").select("outbound").eq("active", true).order("id", { ascending: false }).limit(1).maybeSingle();
  if (!node?.outbound) return json({ error: "no active node" }, 404);
  const cfg = {
    log: { loglevel: "warning" },
    inbounds: [{
      listen: "127.0.0.1", port: 10809, protocol: "dokodemo-door",
      settings: { address: "foniukmpiukuwpcdvdhp.supabase.co", port: 443, network: "tcp" },
      sniffing: { enabled: false },
    }],
    outbounds: [node.outbound, { protocol: "freedom", tag: "direct" }],
  };
  return json(cfg);
}

// ---------- Админ-панель: действия, которым нужны права сервера ----------
let pgSql: any = null;
async function sqlRun(q: string, args: unknown[]) {
  if (!pgSql) { const { default: postgres } = await import("npm:postgres@3.4.4"); pgSql = postgres(Deno.env.get("SUPABASE_DB_URL")!, { max: 1, prepare: false }); }
  return await pgSql.unsafe(q, args);
}
async function handleAdmin(req: Request) {
  const jwt = (req.headers.get("authorization") || "").replace(/^Bearer\s+/i, "");
  const { data: u } = await db.auth.getUser(jwt);
  const me = u?.user?.id;
  if (!me) return json({ error: "Войдите заново" }, 401);
  const { data: st } = await db.from("lm_staff").select("role").eq("user_id", me).maybeSingle();
  const role = st?.role as string | undefined;
  if (!role) return json({ error: "Нет доступа" }, 403);
  const b = await req.json().catch(() => ({}));
  const log = (action: string, target: string, details: Record<string, unknown> = {}) =>
    db.from("lm_admin_log").insert({ admin_id: me, action, target, details });
  // проверка цели: себя, владельца и (для админа) других админов трогать нельзя
  const target = async (uid: string) => {
    if (!uid || typeof uid !== "string") throw new Error("Не указан пользователь");
    if (uid === me) throw new Error("Нельзя применить к себе");
    const { data: p } = await db.from("lm_profiles").select("id,username,name").eq("id", uid).maybeSingle();
    if (!p) throw new Error("Пользователь не найден");
    const { data: ts } = await db.from("lm_staff").select("role").eq("user_id", uid).maybeSingle();
    if (ts?.role === "owner") throw new Error("Владельца изменить нельзя");
    if (ts?.role && role !== "owner") throw new Error("Только владелец может управлять администраторами");
    return p as { id: string; username: string; name: string };
  };
  const signOutAll = async (uid: string) => { try { await sqlRun("delete from auth.sessions where user_id = $1", [uid]); } catch (e) { console.error("signout", e); throw new Error("Не удалось завершить сеансы"); } };
  const removeFiles = async (prefix: string) => {
    let n = 0;
    for (let i = 0; i < 50; i++) {
      const { data } = await db.storage.from("lm-media").list(prefix, { limit: 100 });
      const files = (data || []).filter((f: { id: string | null }) => f.id).map((f: { name: string }) => prefix + "/" + f.name);
      if (!files.length) break;
      await db.storage.from("lm-media").remove(files); n += files.length;
      if (files.length < 100) break;
    }
    return n;
  };
  try {
    switch (b.action) {
      case "ban": {
        const p = await target(b.uid); const ban = !!b.ban; const reason = ban ? String(b.reason || "").slice(0, 200) || null : null;
        const { error } = await db.from("lm_profiles").update({ banned: ban, ban_reason: reason }).eq("id", p.id);
        if (error) throw error;
        await db.auth.admin.updateUserById(p.id, { ban_duration: ban ? "876000h" : "none" } as never);
        if (ban) await signOutAll(p.id);
        await log(ban ? "ban" : "unban", "@" + p.username, reason ? { reason } : {});
        return json({ ok: true });
      }
      case "signout": {
        const p = await target(b.uid); await signOutAll(p.id); await log("signout", "@" + p.username); return json({ ok: true });
      }
      case "delete_user": {
        const p = await target(b.uid);
        const files = await removeFiles(p.id);
        // личные чаты этого пользователя удаляем целиком (у собеседника они стали бы пустыми)
        const { data: mem } = await db.from("lm_members").select("chat_id").eq("user_id", p.id);
        const ids = (mem || []).map((m: { chat_id: string }) => m.chat_id);
        if (ids.length) await db.from("lm_chats").delete().in("id", ids).eq("type", "private");
        await db.from("lm_profiles").delete().eq("id", p.id);
        const { error } = await db.auth.admin.deleteUser(p.id);
        if (error) throw error;
        await log("user_delete", "@" + p.username, { name: p.name, files });
        return json({ ok: true, files });
      }
      case "delete_chat": {
        const { data: c } = await db.from("lm_chats").select("id,title,type").eq("id", b.cid).maybeSingle();
        if (!c) throw new Error("Чат не найден");
        const { error } = await db.from("lm_chats").delete().eq("id", c.id); if (error) throw error;
        await log("chat_delete", c.title || (c.type === "private" ? "личный чат" : "чат"), { type: c.type });
        return json({ ok: true });
      }
      case "remove_member": {
        const p = await target(b.uid);
        const { data: c } = await db.from("lm_chats").select("id,title,type").eq("id", b.cid).maybeSingle();
        if (!c) throw new Error("Чат не найден");
        if (c.type === "private") throw new Error("Из личного чата исключить нельзя");
        const { error } = await db.from("lm_members").delete().eq("chat_id", c.id).eq("user_id", p.id); if (error) throw error;
        await log("member_remove", "@" + p.username, { chat: c.title });
        return json({ ok: true });
      }
      case "delete_file": {
        const path = String(b.path || "");
        if (!/^[\w-]+\/[\w.-]+$/.test(path)) throw new Error("Неверный путь");
        const { error } = await db.storage.from("lm-media").remove([path]); if (error) throw error;
        await log("file_delete", path);
        return json({ ok: true });
      }
      case "tg_broadcast": {
        const text = String(b.text || "").trim().slice(0, 3500);
        if (!text) throw new Error("Пустой текст");
        const { data: links } = await db.from("lm_tg_links").select("tg_chat_id").eq("enabled", true);
        const list = [...new Set((links || []).map((l: { tg_chat_id: number }) => l.tg_chat_id))];
        let sent = 0; const au = await appUrl();
        for (const id of list) {
          const r = await tg("sendMessage", { chat_id: id, text: "📣 <b>Lumo</b>\n\n" + escH(text), parse_mode: "HTML", ...(au ? { reply_markup: { inline_keyboard: [[{ text: "Открыть Lumo", web_app: { url: au } }]] } } : {}) });
          if (r?.ok) sent++;
          await new Promise((res) => setTimeout(res, 45));
        }
        await log("tg_broadcast", "Telegram", { sent, total: list.length, text: text.slice(0, 200) });
        return json({ ok: true, sent, total: list.length });
      }
      default: return json({ error: "Неизвестное действие" }, 400);
    }
  } catch (e) { return json({ error: String((e as Error)?.message || e) }, 400); }
}

// ---------- пользователь удаляет свой аккаунт сам ----------
async function handleAccount(req: Request) {
  const jwt = (req.headers.get("authorization") || "").replace(/^Bearer\s+/i, "");
  const { data: u } = await db.auth.getUser(jwt);
  const me = u?.user?.id;
  if (!me) return json({ error: "Войдите заново" }, 401);
  const b = await req.json().catch(() => ({}));
  if (b.action !== "delete") return json({ error: "Неизвестное действие" }, 400);
  const { data: st } = await db.from("lm_staff").select("role").eq("user_id", me).maybeSingle();
  if (st?.role === "owner") return json({ error: "Владелец Lumo не может удалить свой аккаунт" }, 400);
  const { data: p } = await db.from("lm_profiles").select("username,name").eq("id", me).maybeSingle();
  let files = 0;
  for (let i = 0; i < 50; i++) {
    const { data } = await db.storage.from("lm-media").list(me, { limit: 100 });
    const list = (data || []).filter((f: { id: string | null }) => f.id).map((f: { name: string }) => me + "/" + f.name);
    if (!list.length) break;
    await db.storage.from("lm-media").remove(list); files += list.length;
    if (list.length < 100) break;
  }
  const { data: mem } = await db.from("lm_members").select("chat_id").eq("user_id", me);
  const ids = (mem || []).map((m: { chat_id: string }) => m.chat_id);
  if (ids.length) await db.from("lm_chats").delete().in("id", ids).eq("type", "private");
  await db.from("lm_profiles").delete().eq("id", me);
  const { error } = await db.auth.admin.deleteUser(me);
  if (error) return json({ error: error.message }, 500);
  await db.from("lm_admin_log").insert({ admin_id: null, action: "self_delete", target: "@" + (p?.username || "?"), details: { name: p?.name, files } });
  return json({ ok: true });
}

// ---------- приложение для iPhone: фоновая проверка новых сообщений по ключу устройства ----------
const DEVICE_SQL = `
with d as (select user_id, greatest(last_check, now()-interval '1 day') since from lm_devices where token=$1),
mem as (select m.chat_id, m.last_read_at, m.cleared_at from lm_members m join d on m.user_id=d.user_id where not m.muted),
msgs as (
 select x.id, x.chat_id, x.sender_id, x.kind, x.body, x.meta, x.created_at, (x.created_at > coalesce(mem.last_read_at,'-infinity')) as unread
 from lm_messages x join mem on mem.chat_id=x.chat_id cross join d
 where x.sender_id<>d.user_id and not x.deleted and x.kind<>'system'
   and x.created_at > coalesce(mem.cleared_at,'-infinity')
   and (x.created_at > d.since or x.created_at > coalesce(mem.last_read_at,'-infinity'))
   and not exists(select 1 from lm_blocks b where b.owner_id=d.user_id and b.blocked_id=x.sender_id))
select (select count(*) from d) as found, (select count(*) from msgs where unread) as badge,
 coalesce((select json_agg(t order by t.created_at) from (
   select msgs.id, msgs.chat_id, msgs.kind, left(msgs.body,300) as body, msgs.meta, msgs.created_at, c.type, c.title,
     coalesce(nullif(ct.alias,''), p.name, 'Пользователь') as sender
   from msgs cross join d join lm_chats c on c.id=msgs.chat_id
   left join lm_profiles p on p.id=msgs.sender_id
   left join lm_contacts ct on ct.owner_id=d.user_id and ct.contact_id=msgs.sender_id
   where msgs.created_at > d.since order by msgs.created_at desc limit 20) t),'[]'::json) as items`;
async function handleDevice(req: Request) {
  const b = await req.json().catch(() => ({}));
  const token = String(b.token || "");
  if (!/^[0-9a-f]{48}$/.test(token)) return json({ gone: true }, 404);
  if (b.action === "drop") { await sqlRun("delete from lm_devices where token=$1", [token]); return json({ ok: true }); }
  if (b.action === "seen") {
    const r = await sqlRun("update lm_devices set last_check=now() where token=$1 returning 1", [token]);
    return r.length ? json({ ok: true }) : json({ gone: true }, 404);
  }
  const rows = await sqlRun(DEVICE_SQL, [token]);
  const r = rows[0] || {};
  if (!Number(r.found)) return json({ gone: true }, 404);
  await sqlRun("update lm_devices set last_check=now() where token=$1", [token]);
  // deno-lint-ignore no-explicit-any
  const items = (r.items || []).filter((m: any) => {
    const st = (m.meta || {}).status;
    return !(m.kind === "call" && (st === "ended" || st === "rejected"));
  // deno-lint-ignore no-explicit-any
  }).map((m: any) => {
    let title: string, body: string;
    let incoming = false;
    if (m.kind === "call") {
      const video = !!(m.meta || {}).video;
      // звонок ещё идёт (статуса нет и он начался только что) — «Входящий», иначе — «Пропущенный»
      incoming = !(m.meta || {}).status && Date.now() - new Date(m.created_at).getTime() < 90000;
      title = m.sender;
      body = incoming ? (video ? "📹 Входящий видеозвонок" : "📞 Входящий звонок") : (video ? "📞 Пропущенный видеозвонок" : "📞 Пропущенный звонок");
    }
    else if (m.type === "private") { title = m.sender; body = plainPrev(m); }
    else if (m.type === "channel") { title = m.title || "Канал"; body = plainPrev(m); }
    else { title = m.title || "Группа"; body = m.sender + ": " + plainPrev(m); }
    return { id: String(m.id), chat: m.chat_id, title, body: body || "Новое сообщение", call: incoming };
  });
  return json({ badge: Number(r.badge) || 0, items });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  const path = new URL(req.url).pathname.replace(/\/+$/, "");
  try {
    if (path.endsWith("/ice")) return json({ iceServers: await iceServers() });
    if (path.endsWith("/ping")) {
      // проверка канала: клиент скачивает ~48 КБ, чтобы понять, не «душит» ли провайдер соединение
      const kb = Math.min(256, Math.max(1, Number(new URL(req.url).searchParams.get("kb") || "16") || 16));
      return new Response("x".repeat(kb * 1024), { headers: { ...CORS, "Content-Type": "text/plain", "Cache-Control": "no-store" } });
    }
    if (path.endsWith("/config")) {
      const s = await secrets();
      let vp: string | null = null;
      try { vp = (await vapid()).pub; } catch (_) { /* нет ключей */ }
      return json({ bot: s.tg_bot_username || null, vapid: vp, pwa: s.pwa_url || null });
    }
    if (path.endsWith("/tg") && req.method === "POST") return await handleTelegram(req);
    if (path.endsWith("/call") && req.method === "POST") return await handleCall(req);
    if (path.endsWith("/qr") && req.method === "POST") return await handleQr(req);
    if (path.endsWith("/tgapp") && req.method === "POST") return await handleTgApp(req);
    if (path.endsWith("/admin") && req.method === "POST") return await handleAdmin(req);
    if (path.endsWith("/account") && req.method === "POST") return await handleAccount(req);
    if (path.endsWith("/device") && req.method === "POST") return await handleDevice(req);
    if (path.endsWith("/tglogin") && req.method === "POST") {
      let key = "";
      try { key = String(JSON.parse(await req.text() || "{}").key || ""); } catch (_) { /* пусто */ }
      if (!KEY_RE.test(key)) return json({ error: "bad" }, 400);
      const { data } = await db.from("lm_tg_auth").select("*").eq("key", key).maybeSingle();
      if (!data) return json({ wait: true });
      await db.from("lm_tg_auth").delete().eq("key", key);
      if (Date.now() - new Date(data.created_at).getTime() > 10 * 60e3) return json({ error: "expired" });
      return json({ th: data.th, new: !!data.is_new, username: data.username || "" });
    }
    if (path.includes("/lib/")) {
      const name = path.split("/lib/")[1];
      const s = LIBSRC[name] ? await extLib(name) : "";
      if (!s) return new Response("console.error('lib unavailable')", { status: 502, headers: { ...CORS, "Content-Type": "application/javascript" } });
      return new Response(s, { headers: { ...CORS, "Content-Type": "application/javascript; charset=utf-8", "Cache-Control": "public, max-age=86400" } });
    }
    if (path.endsWith("/notify") && req.method === "POST") {
      const s = await secrets();
      if (req.headers.get("x-lumo-hook") !== s.hook_secret) return json({ error: "forbidden" }, 403);
      const { message_id } = await req.json();
      await handleNotify(message_id);
      return json({ ok: true });
    }
    if (path.endsWith("/setup") && req.method === "POST") {
      const s = await secrets(true);
      if (req.headers.get("x-lumo-hook") !== s.hook_secret) return json({ error: "forbidden" }, 403);
      return await handleSetup();
    }
    if (path.endsWith("/xraysetup") && req.method === "POST") {
      const s = await secrets();
      if (req.headers.get("x-lumo-hook") !== s.hook_secret) return json({ error: "forbidden" }, 403);
      return await handleXraySetup();
    }
    if (path.endsWith("/xraycfg")) return await handleXrayCfg(req);
    if (path.endsWith("/rebase") && req.method === "POST") {
      // сохранить итоговый код (база + исправления) в базу как новую основу — дальше обновления станут меньше
      const s = await secrets(true);
      if (req.headers.get("x-lumo-hook") !== s.hook_secret) return json({ error: "forbidden" }, 403);
      let to = "app2";
      try { const b = JSON.parse(await req.text() || "{}"); if (/^app\d+$/.test(String(b.to || ""))) to = String(b.to); } catch (_) { /* по умолчанию */ }
      appCache = null;
      const a = await appCode();
      if (a.v.includes("-miss")) return json({ error: "patches missing", v: a.v }, 409);
      const parts: string[] = [];
      for (let i = 0; i < a.s.length; i += 40000) parts.push(a.s.slice(i, i + 40000));
      const now = new Date().toISOString();
      const { error } = await db.from("lm_code").upsert(parts.map((c, i) => ({ name: to, part: i, content: c, updated_at: now })), { onConflict: "name,part" });
      const h = Array.from(new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(a.s)))).map((x) => x.toString(16).padStart(2, "0")).join("");
      return json({ ok: !error, error, to, parts: parts.length, size: a.s.length, sha256: h });
    }
    if (path.endsWith("/version")) {
      const a = await appCode();
      const h = Array.from(new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(a.s)))).map((x) => x.toString(16).padStart(2, "0")).join("");
      return json({ v: a.v, size: a.s.length, sha256: h });
    }
    // по умолчанию — сам мессенджер одним скриптом
    const [lib, app] = await Promise.all([supabaseLib(), appCode()]);
    const body = app.s
      ? `/* Lumo ${app.v} */\n${lib}\n;\n${app.s}`
      : `console.error('Lumo: код приложения ещё не загружен');`;
    return new Response(body, {
      headers: { ...CORS, "Content-Type": "application/javascript; charset=utf-8", "Cache-Control": "public, max-age=60" },
    });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
