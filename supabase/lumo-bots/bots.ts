// Боты Lumo: встроенные (Lumo Premium, BotFather) и Bot API для своих ботов
import { createClient } from "npm:@supabase/supabase-js@2";

const SB_URL = Deno.env.get("SUPABASE_URL")!;
const SRK = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
export const db = createClient(SB_URL, SRK, { auth: { persistSession: false } });

const CORS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info, x-init-data",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};
const json = (d: unknown, status = 200) =>
  new Response(JSON.stringify(d), { status, headers: { ...CORS, "Content-Type": "application/json; charset=utf-8" } });

type Btn = { text: string; data?: string; url?: string; web_app?: string };
type Kb = Btn[][];
// deno-lint-ignore no-explicit-any
export type Row = Record<string, any>;

const BUILTIN = [
  {
    key: "premium", username: "lumo_premium", name: "Lumo Premium", color: 1,
    description: "Подписка Lumo Premium и люмены: покупка, баланс и уведомления.",
    commands: [
      { command: "start", description: "Меню Premium" }, { command: "plan", description: "Моя подписка" },
      { command: "buy", description: "Купить Premium" }, { command: "lumens", description: "Купить люмены: /lumens 100" },
      { command: "balance", description: "Баланс люменов" },
    ],
    web_app_url: null as string | null, menu_text: null as string | null,
  },
  {
    key: "botfather", username: "botfather", name: "BotFather", color: 5,
    description: "Создание и управление ботами Lumo. Доступно с подпиской Premium.",
    commands: [
      { command: "newbot", description: "Создать бота" }, { command: "mybots", description: "Мои боты" },
      { command: "token", description: "Токен бота" }, { command: "setdescription", description: "Описание бота" },
      { command: "deletebot", description: "Удалить бота" },
    ],
    web_app_url: "lumo://builtin/botfather", menu_text: "Конструктор",
  },
  {
    key: "verify", username: "bot_verification", name: "Верификация Lumo", color: 4,
    description: "Заявка на галочку подтверждения для вашего профиля или канала. Заявки рассматривает администрация Lumo.",
    commands: [
      { command: "start", description: "Подать заявку" }, { command: "status", description: "Мои заявки" },
    ],
    web_app_url: null as string | null, menu_text: null as string | null,
  },
];

export const rnd = (n: number) => {
  const a = crypto.getRandomValues(new Uint8Array(n));
  return Array.from(a).map((x) => "abcdefghijklmnopqrstuvwxyz0123456789"[x % 36]).join("");
};
const ruDate = (d: string | Date) => new Date(d).toLocaleDateString("ru-RU", { timeZone: "Europe/Moscow", day: "2-digit", month: "2-digit", year: "numeric" });

// ---------- вспомогательное ----------
async function isOwner(uid: string) {
  const { data } = await db.from("lm_staff").select("role").eq("user_id", uid).maybeSingle();
  return data?.role === "owner";
}
async function premiumUntil(uid: string): Promise<{ owner: boolean; until: string | null }> {
  const owner = await isOwner(uid);
  const { data } = await db.from("lm_premium").select("until").eq("user_id", uid).maybeSingle();
  const u = data?.until && new Date(data.until).getTime() > Date.now() ? data.until : null;
  return { owner, until: u };
}
export async function isPremium(uid: string) {
  const p = await premiumUntil(uid);
  return p.owner || !!p.until;
}
async function botSend(botId: string, chatId: string, text: string, kb?: Kb, replyTo?: number | null) {
  const meta: Row = { bot: true };
  if (kb && kb.length) meta.buttons = kb;
  const { data, error } = await db.from("lm_messages").insert({ chat_id: chatId, sender_id: botId, kind: "text", body: text.slice(0, 4000), meta, reply_to: replyTo ?? null }).select("id").single();
  if (error) console.log("botSend", error.message);
  return data?.id as number | undefined;
}
async function botEdit(msgId: number, text: string, kb?: Kb) {
  const meta: Row = { bot: true };
  if (kb && kb.length) meta.buttons = kb;
  const { error } = await db.from("lm_messages").update({ body: text.slice(0, 4000), meta }).eq("id", msgId);
  if (error) console.log("botEdit", error.message);
}
export async function userByName(name: string) {
  const u = name.replace(/^@/, "").toLowerCase();
  const { data } = await db.from("lm_profiles").select("id,username,name").eq("username", u).maybeSingle();
  return data as Row | null;
}

// ---------- Lumo Premium ----------
export const PREMIUM_FEATURES =
  "✨ Что даёт Premium\n\n" +
  "Уже работает:\n" +
  "• значок Premium и эмодзи-статус\n" +
  "• эксклюзивные цвета и фоны, цвет сообщений в чате\n" +
  "• отложенная отправка, тихие сообщения, исчезающие сообщения\n" +
  "• блокировка приложения кодом (веб)\n" +
  "• статистика канала, истории до 7 дней, ссылки в профиле\n" +
  "• создание своих ботов и мини-приложений через BotFather\n" +
  "• групповые голосовые и видеозвонки\n\n" +
  "В разработке: секретные чаты, перевод и расшифровка голосовых, запись звонков, размытие фона, большие файлы, посты в каналах по расписанию, красивые ссылки, видео-аватар.";
async function featuresText(): Promise<string> {
  try {
    const { data } = await db.from("lm_code").select("content").eq("name", "bot_features").eq("part", 0).maybeSingle();
    if (data?.content) return String(data.content);
  } catch (_) { /* запасной текст */ }
  return PREMIUM_FEATURES;
}

const menuKb = (): Kb => [
  [{ text: "📋 Что входит", data: "features" }, { text: "👤 Моя подписка", data: "my" }],
  [{ text: "💳 Купить Premium", data: "buy" }],
  [{ text: "💎 Купить люмены", data: "lum" }, { text: "👛 Баланс", data: "wallet" }],
];
const backKb = (): Kb => [[{ text: "⬅️ Назад", data: "menu" }]];

// ---------- тарифы и люмены ----------
const PREM_PLANS: Record<string, { days: number; price: number; title: string }> = {
  p1: { days: 30, price: 199, title: "1 месяц" },
  p6: { days: 180, price: 1490, title: "6 месяцев" },
  p12: { days: 365, price: 2490, title: "12 месяцев" },
};
const LUM_RATE = 1.7;
const LUM_MIN = 50;
const LUM_MAX = 100000;
const LUM_PACKS = [50, 100, 500, 1000];
const money = (v: number) => {
  const r = Math.round(v * 100) / 100;
  const s = Number.isInteger(r) ? String(r) : r.toFixed(2).replace(".", ",");
  return s.replace(/\B(?=(\d{3})+(?!\d))/g, " ") + " ₽";
};
const lumPrice = (n: number) => Math.round(n * LUM_RATE * 100) / 100;
const STUB = "Оплата пока недоступна. Платёжная система ещё подключается — мы сообщим, когда покупка заработает.";

function tariffsView(): { text: string; kb: Kb } {
  return {
    text: "💳 Тарифы Lumo Premium\n\n" +
      Object.values(PREM_PLANS).map((p) => `• ${p.title} — ${money(p.price)}`).join("\n") +
      "\n\nВыберите тариф. Подписка продлевается вручную, автоматических списаний нет.",
    kb: [
      ...Object.entries(PREM_PLANS).map(([k, p]) => [{ text: `${p.title} — ${money(p.price)}`, data: k }]),
      [{ text: "⬅️ Назад", data: "menu" }],
    ],
  };
}
function planView(key: string): { text: string; kb: Kb } {
  const p = PREM_PLANS[key];
  return {
    text: `💳 Покупка Premium\n\nТариф: ${p.title}\nЦена: ${money(p.price)}\n\nПосле оплаты Premium включится сразу, вы получите уведомление.`,
    kb: [[{ text: `Оплатить ${money(p.price)}`, data: "pay_" + key }], [{ text: "⬅️ К тарифам", data: "buy" }]],
  };
}
function lumListView(): { text: string; kb: Kb } {
  return {
    text: "💎 Покупка люменов\n\nЛюмены — внутренняя валюта Lumo: ими дарят подарки и поддерживают друзей.\n\n" +
      `Курс: 1 люмен = ${money(LUM_RATE)}\nМинимум: ${LUM_MIN} люменов\n\n` +
      LUM_PACKS.map((n) => `• ${n} — ${money(lumPrice(n))}`).join("\n") +
      `\n\nДругое количество: напишите /lumens число (например, /lumens 250).\nВозврат люменов не предусмотрен.`,
    kb: [
      ...LUM_PACKS.map((n) => [{ text: `${n} люменов — ${money(lumPrice(n))}`, data: "l" + n }]),
      [{ text: "⬅️ Назад", data: "menu" }],
    ],
  };
}
function lumSummary(n: number): { text: string; kb: Kb } {
  return {
    text: `💎 Покупка люменов\n\nКоличество: ${n}\nКурс: 1 люмен = ${money(LUM_RATE)}\nК оплате: ${money(lumPrice(n))}\n\nЛюмены поступят на ваш счёт сразу после оплаты. Возврат люменов не предусмотрен.`,
    kb: [[{ text: `Оплатить ${money(lumPrice(n))}`, data: "pay_l" + n }], [{ text: "⬅️ Назад", data: "lum" }]],
  };
}
async function creditLumens(uid: string, n: number) {
  const { data: w } = await db.from("lm_wallets").select("balance").eq("user_id", uid).maybeSingle();
  const nb = Number(w?.balance || 0) + n;
  await db.from("lm_wallets").upsert({ user_id: uid, balance: nb });
  await db.from("lm_ledger").insert({ user_id: uid, delta: n, kind: "grant" });
  return nb;
}
async function walletText(uid: string) {
  const { data: w } = await db.from("lm_wallets").select("balance").eq("user_id", uid).maybeSingle();
  return `👛 Ваш баланс: ${Number(w?.balance || 0)} люменов.`;
}

async function myText(uid: string) {
  const p = await premiumUntil(uid);
  if (p.owner) return "👑 Вы владелец Lumo — Premium у вас включён навсегда.";
  if (p.until) return `✅ Premium активен до ${ruDate(p.until)}.`;
  return "У вас пока нет подписки Premium.";
}

async function premiumMsg(chatId: string, bot: Row, sender: Row, text: string, msgId: number) {
  const t = text.trim();
  const cmd = t.split(/\s+/)[0].toLowerCase().replace(/@.*$/, "");
  const owner = await isOwner(sender.id);
  if (owner && cmd === "/grant") {
    const [, uname, d] = t.split(/\s+/);
    const days = Math.max(1, Math.min(3650, parseInt(d || "30", 10) || 30));
    const u = uname ? await userByName(uname) : null;
    if (!u) { await botSend(bot.id, chatId, "Использование: /grant @username [дней]"); return; }
    const cur = await db.from("lm_premium").select("until").eq("user_id", u.id).maybeSingle();
    const base = cur.data?.until && new Date(cur.data.until).getTime() > Date.now() ? new Date(cur.data.until).getTime() : Date.now();
    const until = new Date(base + days * 86400e3).toISOString();
    await db.from("lm_premium").upsert({ user_id: u.id, until, plan: "manual", source: "owner" });
    await db.from("lm_admin_log").insert({ admin_id: sender.id, action: "premium_grant", target: "@" + u.username, details: { days } });
    await botSend(bot.id, chatId, `✅ Premium для @${u.username} продлён до ${ruDate(until)}.`);
    return;
  }
  if (owner && cmd === "/revoke") {
    const u = await userByName(t.split(/\s+/)[1] || "");
    if (!u) { await botSend(bot.id, chatId, "Использование: /revoke @username"); return; }
    await db.from("lm_premium").delete().eq("user_id", u.id);
    await db.from("lm_admin_log").insert({ admin_id: sender.id, action: "premium_revoke", target: "@" + u.username, details: {} });
    await botSend(bot.id, chatId, `Premium у @${u.username} отключён.`);
    return;
  }
  if (owner && cmd === "/premiumlist") {
    const { data } = await db.from("lm_premium").select("user_id,until").gt("until", new Date().toISOString()).order("until", { ascending: false }).limit(50);
    const ids = (data || []).map((x: Row) => x.user_id);
    const { data: ps } = ids.length ? await db.from("lm_profiles").select("id,username").in("id", ids) : { data: [] };
    const nm = new Map((ps || []).map((p: Row) => [p.id, p.username]));
    await botSend(bot.id, chatId, (data || []).length ? "Подписчики:\n" + (data || []).map((x: Row) => `@${nm.get(x.user_id)} — до ${ruDate(x.until)}`).join("\n") : "Платных подписчиков пока нет.");
    return;
  }
  if (cmd === "/plan") { await botSend(bot.id, chatId, await myText(sender.id), menuKb()); return; }
  if (cmd === "/balance") { await botSend(bot.id, chatId, await walletText(sender.id), menuKb()); return; }
  if (cmd === "/buy") { const v = tariffsView(); await botSend(bot.id, chatId, v.text, v.kb); return; }
  if (cmd === "/lumens") {
    const arg = t.split(/\s+/)[1];
    if (!arg) { const v = lumListView(); await botSend(bot.id, chatId, v.text, v.kb); return; }
    const n = Math.floor(Number(arg));
    if (!isFinite(n) || n < LUM_MIN) { await botSend(bot.id, chatId, `Минимальная покупка — ${LUM_MIN} люменов. Пример: /lumens 100`); return; }
    if (n > LUM_MAX) { await botSend(bot.id, chatId, `За один раз можно купить не больше ${LUM_MAX} люменов.`); return; }
    const v = lumSummary(n);
    await botSend(bot.id, chatId, v.text, v.kb);
    return;
  }
  const head = "✨ Lumo Premium\n\nПодписка с дополнительными возможностями и покупка люменов. Здесь же приходят уведомления, когда вам выдали Premium или отправили люмены.";
  const extra = owner ? "\n\nКоманды владельца: /grant @user [дней], /revoke @user, /premiumlist" : "";
  await botSend(bot.id, chatId, head + extra, menuKb(), msgId);
}

async function premiumCb(msg: Row, user: Row, data: string): Promise<Row> {
  const owner = await isOwner(user.id);
  if (data === "menu") {
    await botEdit(msg.id, "✨ Lumo Premium\n\nПодписка с дополнительными возможностями и покупка люменов. Здесь же приходят уведомления, когда вам выдали Premium или отправили люмены.", menuKb());
    return {};
  }
  if (data === "features") {
    await botEdit(msg.id, await featuresText(), backKb());
    return {};
  }
  if (data === "my") {
    await botEdit(msg.id, await myText(user.id), backKb());
    return {};
  }
  if (data === "wallet") {
    await botEdit(msg.id, await walletText(user.id), [[{ text: "💎 Купить люмены", data: "lum" }], [{ text: "⬅️ Назад", data: "menu" }]]);
    return {};
  }
  if (data === "buy") { const v = tariffsView(); await botEdit(msg.id, v.text, v.kb); return {}; }
  if (PREM_PLANS[data]) { const v = planView(data); await botEdit(msg.id, v.text, v.kb); return {}; }
  if (data === "lum") { const v = lumListView(); await botEdit(msg.id, v.text, v.kb); return {}; }
  const lm = data.match(/^l(\d{1,6})$/);
  if (lm) {
    const n = Number(lm[1]);
    if (n < LUM_MIN || n > LUM_MAX) return { toast: `Количество — от ${LUM_MIN} до ${LUM_MAX} люменов`, alert: true };
    const v = lumSummary(n);
    await botEdit(msg.id, v.text, v.kb);
    return {};
  }
  const pp = data.match(/^pay_(p1|p6|p12)$/);
  if (pp) {
    if (!owner) return { toast: STUB, alert: true };
    const plan = PREM_PLANS[pp[1]];
    const cur = await db.from("lm_premium").select("until").eq("user_id", user.id).maybeSingle();
    const base = cur.data?.until && new Date(cur.data.until).getTime() > Date.now() ? new Date(cur.data.until).getTime() : Date.now();
    const until = new Date(base + plan.days * 86400e3).toISOString();
    await db.from("lm_premium").upsert({ user_id: user.id, until, plan: pp[1], source: "test" });
    await botEdit(msg.id, `✅ Готово (тестовый режим, деньги не списывались).\nТариф: ${plan.title}. Подписка записана до ${ruDate(until)}.`, backKb());
    return { toast: "Подписка оформлена (тест)" };
  }
  const pl = data.match(/^pay_l(\d{1,6})$/);
  if (pl) {
    const n = Number(pl[1]);
    if (n < LUM_MIN || n > LUM_MAX) return { toast: `Количество — от ${LUM_MIN} до ${LUM_MAX} люменов`, alert: true };
    if (!owner) return { toast: STUB, alert: true };
    const nb = await creditLumens(user.id, n);
    await botEdit(msg.id, `✅ Готово (тестовый режим, деньги не списывались).\nЗачислено ${n} люменов. Баланс: ${nb}.`, backKb());
    return { toast: "Люмены зачислены (тест)" };
  }
  return {};
}

// ---------- Верификация: заявки на галочку для профиля или канала ----------
async function staffIds(): Promise<string[]> {
  const { data } = await db.from("lm_staff").select("user_id,role").in("role", ["owner", "admin"]);
  return (data || []).map((x: Row) => x.user_id);
}
/** личный чат бота с человеком (создаётся при необходимости) */
async function botDm(botId: string, uid: string): Promise<string | null> {
  const k = botId < uid ? botId + ":" + uid : uid + ":" + botId;
  const { data: ex } = await db.from("lm_chats").select("id").eq("dm_key", k).maybeSingle();
  if (ex) {
    const { data: m } = await db.from("lm_members").select("user_id").eq("chat_id", ex.id).eq("user_id", uid).maybeSingle();
    if (!m) await db.from("lm_members").insert({ chat_id: ex.id, user_id: uid, role: "member" });
    return ex.id;
  }
  const { data: c, error } = await db.from("lm_chats").insert({ type: "private", dm_key: k, created_by: botId }).select("id").single();
  if (error || !c) return null;
  await db.from("lm_members").insert([{ chat_id: c.id, user_id: botId, role: "member" }, { chat_id: c.id, user_id: uid, role: "member" }]);
  return c.id;
}
const verifyMenu = (): Kb => [[{ text: "Галочка для моего профиля", data: "v:me" }], [{ text: "Галочка для моего канала", data: "v:ch" }], [{ text: "Мои заявки", data: "v:st" }]];
const VERIFY_HELLO = "Верификация Lumo\n\nГалочка подтверждения показывает, что профиль или канал настоящий и проверен администрацией Lumo.\n\nЧтобы подать заявку, выберите ниже, что подтвердить. Для канала нужно быть его владельцем или администратором.";

async function verifyCreate(chatId: string, bot: Row, sender: Row, kind: "user" | "chat", target: Row) {
  const { data: dup } = await db.from("lm_verify_requests").select("id").eq("kind", kind).eq("target_id", target.id).eq("status", "pending").maybeSingle();
  if (dup) { await botSend(bot.id, chatId, "Заявка уже отправлена и ждёт рассмотрения. Мы напишем вам здесь, когда администрация примет решение.", verifyMenu()); return; }
  const { data: r, error } = await db.from("lm_verify_requests").insert({ user_id: sender.id, kind, target_id: target.id, chat_id: chatId }).select("id").single();
  if (error || !r) { await botSend(bot.id, chatId, "Не удалось отправить заявку, попробуйте позже."); return; }
  await botSend(bot.id, chatId, `Заявка №${r.id} отправлена. Администрация Lumo рассмотрит её и ответит здесь.`, verifyMenu());
  let what = "";
  if (kind === "user") what = `профиль ${target.name || ""} (@${target.username || "—"})`;
  else {
    const { count } = await db.from("lm_members").select("user_id", { count: "exact", head: true }).eq("chat_id", target.id);
    what = `${target.type === "channel" ? "канал" : "группа"} «${target.title || ""}»${target.username ? " (@" + target.username + ")" : ""}, участников: ${count ?? 0}`;
  }
  const text = `Заявка на галочку №${r.id}\n\nЧто подтвердить: ${what}\nОт кого: ${sender.name || ""} (@${sender.username || "—"})`;
  for (const sid of await staffIds()) {
    const dm = await botDm(bot.id, sid);
    if (dm) await botSend(bot.id, dm, text, [[{ text: "Подтвердить", data: "v:ok:" + r.id }, { text: "Отклонить", data: "v:no:" + r.id }]]);
  }
}

async function verifyStatus(uid: string): Promise<string> {
  const { data } = await db.from("lm_verify_requests").select("id,kind,status,created_at").eq("user_id", uid).order("id", { ascending: false }).limit(5);
  if (!data || !data.length) return "У вас пока нет заявок.";
  const st: Row = { pending: "на рассмотрении", approved: "подтверждена", rejected: "отклонена" };
  return "Ваши заявки:\n\n" + data.map((x: Row) => `№${x.id} · ${x.kind === "user" ? "профиль" : "канал"} · ${st[x.status] || x.status} · ${ruDate(x.created_at)}`).join("\n");
}

async function verifyMsg(chatId: string, bot: Row, sender: Row, text: string) {
  const t = text.trim();
  if (t.startsWith("/status")) { await botSend(bot.id, chatId, await verifyStatus(sender.id), verifyMenu()); return; }
  if (t.startsWith("@") || /^[a-z0-9_]{3,32}$/i.test(t) || t.includes("lumomess.ru/")) {
    const un = t.replace(/^.*lumomess\.ru\//i, "").replace(/^@/, "").toLowerCase();
    const { data: c } = await db.from("lm_chats").select("id,type,title,username,verified").eq("username", un).maybeSingle();
    if (!c || (c.type !== "channel" && c.type !== "group")) { await botSend(bot.id, chatId, "Канал с таким адресом не найден. Пришлите @адрес публичного канала, например @lumo_news.", verifyMenu()); return; }
    if (c.verified) { await botSend(bot.id, chatId, "У этого канала уже есть галочка.", verifyMenu()); return; }
    const { data: m } = await db.from("lm_members").select("role").eq("chat_id", c.id).eq("user_id", sender.id).maybeSingle();
    if (!m || !["owner", "admin"].includes(m.role)) { await botSend(bot.id, chatId, "Подать заявку для канала может только его владелец или администратор.", verifyMenu()); return; }
    await verifyCreate(chatId, bot, sender, "chat", c);
    return;
  }
  await botSend(bot.id, chatId, VERIFY_HELLO, verifyMenu());
}

async function verifyCb(msg: Row, user: Row, data: string, bot: Row): Promise<Row> {
  if (data === "v:me") {
    const { data: p } = await db.from("lm_profiles").select("id,name,username,verified").eq("id", user.id).maybeSingle();
    if (p?.verified) { await botSend(bot.id, msg.chat_id, "У вашего профиля уже есть галочка.", verifyMenu()); return {}; }
    await verifyCreate(msg.chat_id, bot, user, "user", p || user);
    return { toast: "Заявка отправлена" };
  }
  if (data === "v:ch") { await botSend(bot.id, msg.chat_id, "Пришлите @адрес канала, для которого нужна галочка. Вы должны быть его владельцем или администратором."); return {}; }
  if (data === "v:st") { await botSend(bot.id, msg.chat_id, await verifyStatus(user.id), verifyMenu()); return {}; }
  const m = data.match(/^v:(ok|no):(\d+)$/);
  if (m) {
    if (!(await staffIds()).includes(user.id)) return { toast: "Только для администрации" };
    const { data: r } = await db.from("lm_verify_requests").select("*").eq("id", Number(m[2])).maybeSingle();
    if (!r) return { toast: "Заявка не найдена" };
    if (r.status !== "pending") return { toast: "Заявка уже рассмотрена" };
    const ok = m[1] === "ok";
    if (ok) {
      if (r.kind === "user") await db.from("lm_profiles").update({ verified: true }).eq("id", r.target_id);
      else await db.from("lm_chats").update({ verified: true }).eq("id", r.target_id);
    }
    await db.from("lm_verify_requests").update({ status: ok ? "approved" : "rejected", decided_by: user.id, decided_at: new Date().toISOString() }).eq("id", r.id);
    await botEdit(msg.id, String(msg.body || "") + (ok ? "\n\nПодтверждено" : "\n\nОтклонено"));
    if (r.chat_id) await botSend(bot.id, r.chat_id, ok
      ? `Заявка №${r.id} одобрена: ${r.kind === "user" ? "у вашего профиля" : "у канала"} теперь есть галочка подтверждения Lumo.`
      : `Заявка №${r.id} отклонена. Вы можете подать новую заявку позже.`, verifyMenu());
    return { toast: ok ? "Подтверждено" : "Отклонено" };
  }
  return {};
}

// ---------- создание и удаление ботов (общие для чата и мини-приложения) ----------
export async function createBotFor(ownerId: string, unameRaw: string, nameRaw: string, desc = ""): Promise<Row> {
  if (!(await isPremium(ownerId))) return { ok: false, error: "Создавать ботов могут только пользователи Premium. Оформление подписки пока недоступно для покупки — мы сообщим, когда оно откроется." };
  const uname = unameRaw.replace(/^@/, "").toLowerCase();
  const name = (nameRaw || "").trim() || uname;
  if (!/^[a-z0-9_]{3,32}$/.test(uname) || !uname.endsWith("bot")) return { ok: false, error: "Имя пользователя — латиница, цифры и _, 3–32 символа, оканчивается на «bot»." };
  const cnt = ((await db.from("lm_bots").select("id").eq("owner_id", ownerId).is("builtin", null)).data || []).length;
  if (cnt >= 5) return { ok: false, error: "Можно создать не более 5 ботов." };
  if (await userByName(uname)) return { ok: false, error: "Это имя уже занято." };
  const { data: au, error } = await db.auth.admin.createUser({ email: `bot_${rnd(12)}@bots.lumo.invalid`, password: rnd(40), email_confirm: true });
  if (error || !au?.user) return { ok: false, error: "Не удалось создать бота, попробуйте ещё раз." };
  const id = au.user.id;
  const { error: e1 } = await db.from("lm_profiles").insert({ id, username: uname, name: name.slice(0, 64), bio: desc.slice(0, 200), is_bot: true, color: Math.floor(Math.random() * 8) });
  if (e1) { await db.auth.admin.deleteUser(id); return { ok: false, error: "Не удалось создать бота: " + e1.message }; }
  const token = id.replace(/-/g, "").slice(0, 10) + ":" + rnd(32);
  // описание обязательно в таблице (пустая строка, а не null) — иначе бот создавался без записи и не был виден в «Мои боты»
  const { error: e2 } = await db.from("lm_bots").insert({ id, owner_id: ownerId, token, description: desc.slice(0, 300) });
  if (e2) { await db.auth.admin.deleteUser(id); return { ok: false, error: "Не удалось создать бота: " + e2.message }; }
  return { ok: true, id, username: uname, token };
}

export async function deleteBotFor(botId: string) {
  const ids = ((await db.from("lm_members").select("chat_id").eq("user_id", botId)).data || []).map((x: Row) => x.chat_id);
  if (ids.length) await db.from("lm_chats").delete().in("id", ids);
  await db.auth.admin.deleteUser(botId);
}

// ---------- BotFather ----------
async function fatherMsg(chatId: string, bot: Row, sender: Row, text: string, msgId: number) {
  const t = text.trim();
  const parts = t.split(/\s+/);
  const cmd = parts[0].toLowerCase().replace(/@.*$/, "");
  const help = "🤖 BotFather — создание ботов Lumo\n\nПроще всего — открыть конструктор: кнопка ниже или «Конструктор» рядом с полем ввода. В нём можно создать бота, настроить команды, мини-приложение и посмотреть токен.\n\nИли командами:\n/newbot имя_пользователя Название — создать бота\n/mybots — мои боты\n/token @бот — токен\n/setdescription @бот текст — описание\n/deletebot @бот — удалить\n\nИмя пользователя бота должно заканчиваться на «bot» (например, shop_bot). Создавать ботов могут пользователи Premium.";
  const openKb: Kb = [[{ text: "🛠 Открыть конструктор ботов", web_app: "lumo://builtin/botfather" }]];
  if (!cmd.startsWith("/") || cmd === "/start" || cmd === "/help") { await botSend(bot.id, chatId, help, openKb, msgId); return; }
  const mine = async () => (await db.from("lm_bots").select("id,token,description,builtin").eq("owner_id", sender.id).is("builtin", null)).data as Row[] || [];
  const botByName = async (n: string | undefined) => {
    const u = n ? await userByName(n) : null;
    if (!u) return null;
    const { data } = await db.from("lm_bots").select("id,token,owner_id").eq("id", u.id).eq("owner_id", sender.id).maybeSingle();
    return data ? { ...data, username: u.username } as Row : null;
  };
  if (cmd === "/newbot") {
    const r = await createBotFor(sender.id, parts[1] || "", parts.slice(2).join(" "));
    if (!r.ok) { await botSend(bot.id, chatId, r.error + "\n\nФормат: /newbot имя_пользователя Название"); return; }
    await botSend(bot.id, chatId, `✅ Бот @${r.username} создан.\n\nТокен (никому не показывайте):\n${r.token}\n\nAPI: https://foniukmpiukuwpcdvdhp.supabase.co/functions/v1/lumo-bots/botapi/${r.token}/getMe`, openKb);
    return;
  }
  if (cmd === "/mybots") {
    const list = await mine();
    if (!list.length) { await botSend(bot.id, chatId, "У вас пока нет ботов. Создайте: /newbot имя_пользователя Название", openKb); return; }
    const { data: ps } = await db.from("lm_profiles").select("id,username,name").in("id", list.map((x) => x.id));
    await botSend(bot.id, chatId, "Ваши боты:\n" + (ps || []).map((p: Row) => `@${p.username} — ${p.name}`).join("\n"), openKb);
    return;
  }
  const b = await botByName(parts[1]);
  if (["/token", "/setdescription", "/deletebot"].includes(cmd)) {
    if (!b) { await botSend(bot.id, chatId, "Бот не найден среди ваших. Укажите @имя бота."); return; }
    if (cmd === "/token") { await botSend(bot.id, chatId, `Токен @${b.username}:\n${b.token}`); return; }
    if (cmd === "/setdescription") {
      await db.from("lm_bots").update({ description: parts.slice(2).join(" ").slice(0, 300) }).eq("id", b.id);
      await db.from("lm_profiles").update({ bio: parts.slice(2).join(" ").slice(0, 200) }).eq("id", b.id);
      await botSend(bot.id, chatId, "Описание обновлено."); return;
    }
    if (cmd === "/deletebot") {
      await deleteBotFor(b.id);
      await botSend(bot.id, chatId, `Бот @${b.username} удалён.`); return;
    }
  }
  await botSend(bot.id, chatId, help, openKb);
}

// ---------- пользовательские боты: Update-ы ----------
export function fromObj(p: Row) {
  return { id: p.id, is_bot: false, first_name: p.name, username: p.username };
}
export async function pushUpdate(bot: Row, payload: Row) {
  if (bot.webhook_url) {
    try {
      const { data: row } = await db.from("lm_bot_updates").insert({ bot_id: bot.id, payload }).select("id").single();
      await fetch(bot.webhook_url, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ update_id: row?.id, ...payload }), signal: AbortSignal.timeout(8000) });
      if (row) await db.from("lm_bot_updates").delete().eq("id", row.id);
    } catch (e) { console.log("webhook", String(e)); }
    return;
  }
  await db.from("lm_bot_updates").insert({ bot_id: bot.id, payload });
}

// ---------- входящие сообщения и нажатия ----------
export async function handleBotMsg(messageId: number, botId: string) {
  const { data: m } = await db.from("lm_messages").select("*").eq("id", messageId).maybeSingle();
  if (!m || m.deleted || m.kind === "system" || m.sender_id === botId) return;
  const { data: bot } = await db.from("lm_bots").select("*").eq("id", botId).maybeSingle();
  if (!bot) return;
  const { data: sender } = await db.from("lm_profiles").select("id,username,name").eq("id", m.sender_id).maybeSingle();
  if (!sender) return;
  const text = m.kind === "text" ? String(m.body || "") : "";
  if (bot.builtin === "premium") return await premiumMsg(m.chat_id, bot, sender, text, m.id);
  if (bot.builtin === "botfather") return await fatherMsg(m.chat_id, bot, sender, text, m.id);
  if (bot.builtin === "verify") return await verifyMsg(m.chat_id, bot, sender, text);
  await pushUpdate(bot, {
    message: { message_id: m.id, from: fromObj(sender), chat: { id: m.chat_id, type: "private" }, date: Math.floor(new Date(m.created_at).getTime() / 1000), text: m.kind === "text" ? text : undefined, kind: m.kind, media_url: m.media_url },
  });
}

export async function handleBotCb(req: Request) {
  const jwt = (req.headers.get("authorization") || "").replace(/^Bearer\s+/i, "");
  const { data: u } = await db.auth.getUser(jwt);
  const uid = u?.user?.id;
  if (!uid) return json({ error: "unauthorized" }, 401);
  const b = await req.json().catch(() => ({}));
  const mid = Number(b.message_id), data = String(b.data || "").slice(0, 64);
  if (!mid || !data) return json({ error: "bad request" }, 400);
  const { data: msg } = await db.from("lm_messages").select("*").eq("id", mid).maybeSingle();
  if (!msg) return json({ error: "not found" }, 404);
  const { data: mem } = await db.from("lm_members").select("user_id").eq("chat_id", msg.chat_id).eq("user_id", uid).maybeSingle();
  if (!mem) return json({ error: "forbidden" }, 403);
  const { data: bot } = await db.from("lm_bots").select("*").eq("id", msg.sender_id).maybeSingle();
  if (!bot) return json({ error: "not a bot" }, 400);
  const btns: Btn[] = ((msg.meta || {}).buttons || []).flat();
  if (!btns.some((x) => x.data === data)) return json({ error: "no such button" }, 400);
  const { data: user } = await db.from("lm_profiles").select("id,username,name").eq("id", uid).maybeSingle();
  if (!user) return json({ error: "no user" }, 400);
  if (bot.builtin === "premium") return json({ ok: true, ...(await premiumCb(msg, user, data)) });
  if (bot.builtin === "verify") return json({ ok: true, ...(await verifyCb(msg, user, data, bot)) });
  if (bot.builtin) return json({ ok: true });
  await pushUpdate(bot, { callback_query: { id: rnd(16), from: fromObj(user), message: { message_id: msg.id, chat: { id: msg.chat_id, type: "private" }, text: msg.body }, data } });
  return json({ ok: true });
}

// ---------- Bot API: /botapi/<token>/<method> ----------
export async function handleBotApi(req: Request, path: string) {
  const seg = path.split("/botapi/")[1]?.split("/") || [];
  const token = decodeURIComponent(seg[0] || ""), method = seg[1] || "";
  const { data: bot } = await db.from("lm_bots").select("*").eq("token", token).maybeSingle();
  if (!bot) return json({ ok: false, description: "Unauthorized" }, 401);
  let p: Row = {};
  const url = new URL(req.url);
  url.searchParams.forEach((v, k) => (p[k] = v));
  if (req.method === "POST") { try { p = { ...p, ...JSON.parse((await req.text()) || "{}") }; } catch (_) { /* пусто */ } }
  const kbOf = (rm: Row | string | undefined): Kb | undefined => {
    try {
      const r = typeof rm === "string" ? JSON.parse(rm) : rm;
      const k = r?.inline_keyboard;
      if (!Array.isArray(k)) return undefined;
      return k.slice(0, 8).map((row: Row[]) => row.slice(0, 6).map((x) => ({
        text: String(x.text || "").slice(0, 40),
        data: x.callback_data ? String(x.callback_data).slice(0, 64) : undefined,
        url: x.url ? String(x.url).slice(0, 300) : undefined,
        web_app: x.web_app?.url && /^https:\/\//.test(String(x.web_app.url)) ? String(x.web_app.url).slice(0, 500) : undefined,
      })));
    } catch (_) { return undefined; }
  };
  const ok = (result: unknown) => json({ ok: true, result });
  const myChat = async (cid: string) => {
    const { data } = await db.from("lm_members").select("chat_id").eq("chat_id", cid).eq("user_id", bot.id).maybeSingle();
    return !!data;
  };
  switch (method) {
    case "getMe": {
      const { data: pr } = await db.from("lm_profiles").select("id,username,name").eq("id", bot.id).maybeSingle();
      return ok({ id: bot.id, is_bot: true, first_name: pr?.name, username: pr?.username });
    }
    case "getUpdates": {
      const off = Number(p.offset || 0), lim = Math.min(100, Number(p.limit || 100));
      if (off > 0) await db.from("lm_bot_updates").delete().eq("bot_id", bot.id).lt("id", off);
      const { data } = await db.from("lm_bot_updates").select("id,payload").eq("bot_id", bot.id).gte("id", off || 0).order("id").limit(lim);
      return ok((data || []).map((x: Row) => ({ update_id: x.id, ...x.payload })));
    }
    case "sendMessage": {
      const cid = String(p.chat_id || "");
      if (!cid || !(await myChat(cid))) return json({ ok: false, description: "Bad Request: chat not found" }, 400);
      if (!String(p.text || "").trim()) return json({ ok: false, description: "Bad Request: text is empty" }, 400);
      const id = await botSend(bot.id, cid, String(p.text), kbOf(p.reply_markup), p.reply_to_message_id ? Number(p.reply_to_message_id) : null);
      return id ? ok({ message_id: id, chat: { id: cid } }) : json({ ok: false, description: "Bad Request" }, 400);
    }
    case "editMessageText": {
      const mid = Number(p.message_id);
      const { data: m } = await db.from("lm_messages").select("id,sender_id").eq("id", mid).maybeSingle();
      if (!m || m.sender_id !== bot.id) return json({ ok: false, description: "Bad Request: message not found" }, 400);
      await botEdit(mid, String(p.text || ""), kbOf(p.reply_markup));
      return ok(true);
    }
    case "deleteMessage": {
      const mid = Number(p.message_id);
      const { error } = await db.from("lm_messages").update({ deleted: true }).eq("id", mid).eq("sender_id", bot.id);
      return error ? json({ ok: false, description: "Bad Request" }, 400) : ok(true);
    }
    case "answerCallbackQuery": return ok(true);
    case "setWebhook": {
      const u = String(p.url || "");
      if (u && !/^https:\/\//.test(u)) return json({ ok: false, description: "Bad Request: https url required" }, 400);
      await db.from("lm_bots").update({ webhook_url: u || null }).eq("id", bot.id);
      return ok(true);
    }
    case "deleteWebhook": await db.from("lm_bots").update({ webhook_url: null }).eq("id", bot.id); return ok(true);
    case "setMyCommands": {
      const cmds = Array.isArray(p.commands) ? p.commands : [];
      await db.from("lm_bots").update({ commands: cmds.slice(0, 30).map((c: Row) => ({ command: String(c.command || "").slice(0, 32), description: String(c.description || "").slice(0, 100) })) }).eq("id", bot.id);
      return ok(true);
    }
    // кнопка мини-приложения рядом с полем ввода: { url, text } (пустой url — убрать)
    case "setChatMenuButton":
    case "setMyWebApp": {
      const mb = p.menu_button && typeof p.menu_button === "object" ? p.menu_button : p;
      const u = String(mb.url || mb.web_app?.url || "");
      if (u && !/^https:\/\//.test(u)) return json({ ok: false, description: "Bad Request: https url required" }, 400);
      await db.from("lm_bots").update({ web_app_url: u || null, menu_text: u ? String(mb.text || "Открыть").slice(0, 24) : null }).eq("id", bot.id);
      return ok(true);
    }
    default: return json({ ok: false, description: "Not Found" }, 404);
  }
}

// ---------- создание встроенных ботов (один раз) ----------
export async function setupBuiltin() {
  const out: Row[] = [];
  for (const b of BUILTIN) {
    let { data: pr } = await db.from("lm_profiles").select("id").eq("username", b.username).maybeSingle();
    if (!pr) {
      const { data: au, error } = await db.auth.admin.createUser({ email: `${b.key}@bots.lumo.invalid`, password: rnd(40), email_confirm: true });
      if (error || !au?.user) { out.push({ key: b.key, error: error?.message }); continue; }
      const { error: e1 } = await db.from("lm_profiles").insert({ id: au.user.id, username: b.username, name: b.name, bio: b.description.slice(0, 200), is_bot: true, verified: true, color: b.color });
      if (e1) { out.push({ key: b.key, error: e1.message }); continue; }
      pr = { id: au.user.id };
    }
    await db.from("lm_profiles").update({ is_bot: true, verified: true, name: b.name, bio: b.description.slice(0, 200) }).eq("id", pr.id);
    const { data: ex } = await db.from("lm_bots").select("id").eq("id", pr.id).maybeSingle();
    if (!ex) await db.from("lm_bots").insert({ id: pr.id, owner_id: null, token: "builtin:" + rnd(40), builtin: b.key, description: b.description, commands: b.commands, web_app_url: b.web_app_url, menu_text: b.menu_text });
    else await db.from("lm_bots").update({ description: b.description, commands: b.commands, builtin: b.key, web_app_url: b.web_app_url, menu_text: b.menu_text }).eq("id", pr.id);
    out.push({ key: b.key, id: pr.id, username: b.username });
  }
  return out;
}

export { json as botJson };
