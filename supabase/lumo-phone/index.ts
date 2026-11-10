import { createClient } from "npm:@supabase/supabase-js@2";

const URL_ = Deno.env.get("SUPABASE_URL")!;
const SVC = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const sb = createClient(URL_, SVC, { auth: { persistSession: false } });
const CORS = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type", "Access-Control-Allow-Methods": "POST, OPTIONS" };
const J = (o: unknown, s = 200) => new Response(JSON.stringify(o), { status: s, headers: { ...CORS, "Content-Type": "application/json" } });

async function secret(k: string): Promise<string | null> {
  const { data } = await sb.from("lm_secrets").select("value").eq("key", k).maybeSingle();
  return data?.value ?? null;
}
function normPhone(raw: string): string | null {
  let d = String(raw || "").replace(/\D/g, "");
  if (d.length === 11 && d[0] === "8") d = "7" + d.slice(1);
  if (d.length === 10 && d[0] === "9") d = "7" + d;
  return /^79\d{9}$/.test(d) ? d : null;
}
// SMS идут только номерам Билайн и Теле2 (по коду DEF); остальным — Telegram
const SMS_DEF = new Set([
  "903", "905", "906", "909", "960", "961", "962", "963", "964", "965", "966", "967", "968", "969", "980", "983", "986", // Билайн
  "900", "901", "902", "904", "908", "950", "951", "952", "958", "977", "991", "992", "993", "994", "995", "996", "999", // Теле2
]);
const smsOperator = (phone: string) => SMS_DEF.has(phone.slice(1, 4));
async function sha(s: string): Promise<string> {
  const b = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(s));
  return Array.from(new Uint8Array(b)).map((x) => x.toString(16).padStart(2, "0")).join("");
}
async function codeHash(phone: string, code: string) {
  const salt = (await secret("phone_salt")) ?? SVC.slice(-16);
  return await sha(salt + ":" + phone + ":" + code);
}
async function smscCall(phone: string, mes: string, tg: boolean): Promise<string | null> {
  const key = await secret("smsc_apikey");
  if (!key) return "sms_off";
  const q = new URLSearchParams({ apikey: key, phones: phone, mes, charset: "utf-8", fmt: "3" });
  if (tg) q.set("tg", "1");
  try {
    const r = await fetch("https://smsc.ru/sys/send.php?" + q.toString());
    const j = await r.json();
    if (j.error) {
      console.log("smsc error", tg ? "tg" : "sms", j.error, j.error_code);
      await sb.from("lm_secrets").upsert({ key: tg ? "smsc_tg_last_error" : "smsc_last_error", value: String(j.error) + " " + String(j.error_code) });
      return "sms_fail";
    }
    return null;
  } catch (e) { console.log("smsc exc", String(e)); return "sms_fail"; }
}
const sendSms = (phone: string, text: string) => smscCall(phone, text, false);
// Код в Telegram через API SMSC (tg=1): только числовой код 4–8 цифр
const smscTelegram = (phone: string, code: string) => smscCall(phone, code, true);
// запасной вариант: Telegram Gateway, если задан его токен
async function gatewaySend(phone: string, code: string): Promise<boolean> {
  const t = await secret("tg_gateway_token");
  if (!t) return false;
  try {
    const r = await fetch("https://gatewayapi.telegram.org/sendVerificationMessage", {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: "Bearer " + t },
      body: JSON.stringify({ phone_number: "+" + phone, code, ttl: 600 }),
    });
    const j = await r.json();
    if (!j.ok) { console.log("gateway", String(j.error)); await sb.from("lm_secrets").upsert({ key: "tg_gateway_last_error", value: String(j.error) }); }
    return !!j.ok;
  } catch (e) { console.log("gateway exc", String(e)); return false; }
}
async function tgSend(chatId: number, text: string): Promise<boolean> {
  const t = await secret("tg_token");
  if (!t) return false;
  try {
    const r = await fetch(`https://api.telegram.org/bot${t}/sendMessage`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ chat_id: chatId, text, parse_mode: "HTML" }) });
    const j = await r.json();
    return !!j.ok;
  } catch (_) { return false; }
}
async function knownTg(phone: string): Promise<number | null> {
  const { data: a } = await sb.from("lm_tg_phones").select("tg_chat_id").eq("phone", phone).maybeSingle();
  if (a?.tg_chat_id) return Number(a.tg_chat_id);
  const { data: p } = await sb.from("lm_phones").select("user_id").eq("phone", phone).maybeSingle();
  if (p?.user_id) {
    const { data: l } = await sb.from("lm_tg_links").select("tg_chat_id").eq("user_id", p.user_id).limit(1);
    if (l?.[0]?.tg_chat_id) return Number(l[0].tg_chat_id);
  }
  return null;
}
async function userByJwt(req: Request) {
  const t = (req.headers.get("authorization") || "").replace(/^Bearer /i, "");
  if (!t) return null;
  const { data } = await sb.auth.getUser(t);
  return data?.user ?? null;
}
async function magic(uid: string) {
  const { data: u } = await sb.auth.admin.getUserById(uid);
  const email = u?.user?.email;
  if (!email) return null;
  const { data, error } = await sb.auth.admin.generateLink({ type: "magiclink", email });
  if (error) { console.log("link", error.message); return null; }
  return data?.properties?.hashed_token ?? null;
}

async function send(b: any, req: Request) {
  const phone = normPhone(b.phone);
  if (!phone) return J({ error: "bad_phone" });
  const purpose = b.purpose === "bind" ? "bind" : "auth";
  // служебный номер +7 999 999-99-99: кода нет, приложение показывает вход по юзернейму и паролю
  if (phone === "79999999999" && purpose === "auth") return J({ error: "sms_off", legacy: true });
  let uid: string | null = null;
  if (purpose === "bind") {
    const u = await userByJwt(req);
    if (!u) return J({ error: "auth" }, 401);
    uid = u.id;
    const { data: taken } = await sb.from("lm_phones").select("user_id").eq("phone", phone).maybeSingle();
    if (taken && taken.user_id !== uid) return J({ error: "phone_taken" });
  }
  const since = new Date(Date.now() - 3600_000).toISOString();
  const { data: recent } = await sb.from("lm_phone_codes").select("created_at").eq("phone", phone).gte("created_at", since).order("created_at", { ascending: false });
  if ((recent?.length ?? 0) >= 5) return J({ error: "too_many" });
  if (recent?.[0] && Date.now() - new Date(recent[0].created_at).getTime() < 40_000) return J({ error: "wait", seconds: 40 });
  const day = new Date(Date.now() - 86400_000).toISOString();
  const { count } = await sb.from("lm_phone_codes").select("id", { count: "exact", head: true }).gte("created_at", day);
  if ((count ?? 0) > 400) return J({ error: "busy" });
  const code = String(Math.floor(10000 + Math.random() * 90000));
  const forceTg = b.channel === "telegram";
  let channel: "sms" | "telegram" = "telegram";
  let link: string | null = null;
  let direct = false;
  if (!forceTg && smsOperator(phone)) {
    const err = await sendSms(phone, `Lumo: код ${code}. Никому его не сообщайте.`);
    if (!err) channel = "sms";
  }
  if (channel === "telegram") {
    if ((await smscTelegram(phone, code)) === null || (await gatewaySend(phone, code))) {
      direct = true; // код ушёл официальным сообщением Telegram (через SMSC)
    } else {
      const bot = await secret("tg_bot_username");
      if (!bot || !(await secret("tg_token"))) return J({ error: "sms_off" });
      const chat = await knownTg(phone);
      if (chat && (await tgSend(chat, `🔐 Код для входа в Lumo: <b>${code}</b>\nНикому его не сообщайте.`))) direct = true;
      else {
        const token = "p_" + crypto.randomUUID().replace(/-/g, "").slice(0, 24);
        await sb.from("lm_phone_tg").delete().lt("created_at", new Date(Date.now() - 3600_000).toISOString());
        await sb.from("lm_phone_tg").insert({ token, phone, code });
        link = `https://t.me/${bot}?start=${token}`;
      }
    }
  }
  await sb.from("lm_phone_codes").insert({ phone, purpose, code_hash: await codeHash(phone, code), expires_at: new Date(Date.now() + 10 * 60_000).toISOString() });
  const { data: ex } = await sb.from("lm_phones").select("user_id").eq("phone", phone).maybeSingle();
  return J({ ok: true, exists: !!ex, channel, direct, link });
}

async function checkCode(phone: string, purpose: string, code: string, consume: boolean): Promise<Response | null> {
  const { data: rows } = await sb.from("lm_phone_codes").select("*").eq("phone", phone).eq("purpose", purpose).eq("used", false).gt("expires_at", new Date().toISOString()).order("created_at", { ascending: false }).limit(1);
  const row = rows?.[0];
  if (!row) return J({ error: "expired" });
  if (row.attempts >= 5) return J({ error: "locked" });
  if (row.code_hash !== (await codeHash(phone, String(code || "").trim()))) {
    await sb.from("lm_phone_codes").update({ attempts: row.attempts + 1 }).eq("id", row.id);
    return J({ error: "bad_code", left: 4 - row.attempts });
  }
  if (consume) await sb.from("lm_phone_codes").update({ used: true }).eq("id", row.id);
  return null;
}

async function verify(b: any, req: Request) {
  const phone = normPhone(b.phone);
  if (!phone) return J({ error: "bad_phone" });
  const purpose = b.purpose === "bind" ? "bind" : "auth";
  if (purpose === "bind") {
    const u = await userByJwt(req);
    if (!u) return J({ error: "auth" }, 401);
    const bad = await checkCode(phone, purpose, b.code, true);
    if (bad) return bad;
    const { data: taken } = await sb.from("lm_phones").select("user_id").eq("phone", phone).maybeSingle();
    if (taken && taken.user_id !== u.id) return J({ error: "phone_taken" });
    await sb.from("lm_phones").upsert({ user_id: u.id, phone, verified_at: new Date().toISOString() });
    return J({ ok: true, phone });
  }
  const { data: ex } = await sb.from("lm_phones").select("user_id").eq("phone", phone).maybeSingle();
  if (ex) {
    const uid = ex.user_id as string;
    // заблокированный аккаунт тоже входит: в приложении он увидит окно блокировки и сможет подать апелляцию
    const { data: tf } = await sb.from("lm_twofa").select("pwd_hash,hint,reset_at").eq("user_id", uid).maybeSingle();
    const hasTf = !!tf && tf.pwd_hash !== "!";
    if (hasTf) {
      if (b.reset_tfa) {
        const bad = await checkCode(phone, purpose, b.code, false);
        if (bad) return bad;
        if (!tf!.reset_at) {
          await sb.from("lm_twofa").update({ reset_at: new Date().toISOString() }).eq("user_id", uid);
          return J({ reset_pending: true, days: 7 });
        }
        if (Date.now() - new Date(tf!.reset_at).getTime() < 7 * 86400_000) {
          return J({ reset_pending: true, until: new Date(new Date(tf!.reset_at).getTime() + 7 * 86400_000).toISOString() });
        }
        await sb.from("lm_twofa").update({ pwd_hash: "!", reset_at: null }).eq("user_id", uid);
      } else {
        const bad = await checkCode(phone, purpose, b.code, false);
        if (bad) return bad;
        if (!b.tfa) return J({ need_tfa: true, hint: tf!.hint ?? "" });
        const { data: okp } = await sb.rpc("lm_tfa_check", { p_user: uid, p_pwd: String(b.tfa) });
        if (!okp) {
          const { data: rows } = await sb.from("lm_phone_codes").select("id,attempts").eq("phone", phone).eq("used", false).order("created_at", { ascending: false }).limit(1);
          if (rows?.[0]) await sb.from("lm_phone_codes").update({ attempts: rows[0].attempts + 1 }).eq("id", rows[0].id);
          return J({ error: "bad_tfa", hint: tf!.hint ?? "" });
        }
        await sb.from("lm_twofa").update({ reset_at: null }).eq("user_id", uid);
      }
    }
    const bad2 = await checkCode(phone, purpose, b.code, true);
    if (bad2) return bad2;
    const th = await magic(uid);
    if (!th) return J({ error: "link" });
    return J({ ok: true, token_hash: th, created: false });
  }
  // новый номер: код → (имя, фамилия — по желанию) → юзернейм
  const bad = await checkCode(phone, purpose, b.code, false);
  if (bad) return bad;
  const uname = String(b.username || "").trim().toLowerCase().replace(/^@/, "");
  if (!uname) return J({ need_name: true });
  if (!/^[a-z0-9_]{3,32}$/.test(uname)) return J({ error: "bad_username" });
  const { data: busy } = await sb.from("lm_profiles").select("id").ilike("username", uname).maybeSingle();
  if (busy) return J({ error: "username_taken" });
  const name = String(b.name || "").trim().slice(0, 64) || uname;
  const lastName = String(b.last_name || "").trim().slice(0, 64);
  const bad3 = await checkCode(phone, purpose, b.code, true);
  if (bad3) return bad3;
  const pw = crypto.randomUUID() + crypto.randomUUID();
  const { data: rid, error } = await sb.rpc("lm_register", { p_username: uname, p_password: pw, p_name: name });
  if (error) {
    if (/занят/.test(error.message)) return J({ error: "username_taken" });
    console.log("reg", error.message);
    return J({ error: "reg", message: error.message });
  }
  const uid = rid as string | null;
  if (!uid) return J({ error: "reg" });
  if (lastName) await sb.from("lm_profiles").update({ last_name: lastName }).eq("id", uid);
  await sb.from("lm_phones").insert({ user_id: uid, phone });
  const th = await magic(uid);
  if (!th) return J({ error: "link" });
  return J({ ok: true, token_hash: th, created: true });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: CORS });
  try {
    const url = new URL(req.url);
    const path = url.pathname.split("/").pop();
    const b = await req.json().catch(() => ({}));
    if (path === "send") return await send(b, req);
    if (path === "verify") return await verify(b, req);
    if (path === "username") {
      const u = String(b.username || "").trim().toLowerCase().replace(/^@/, "");
      if (!/^[a-z0-9_]{3,32}$/.test(u)) return J({ free: false, error: "bad_username" });
      const { data: t } = await sb.from("lm_profiles").select("id").ilike("username", u).maybeSingle();
      return J({ free: !t });
    }
    if (path === "status") return J({ sms: !!(await secret("smsc_apikey")), telegram: !!(await secret("tg_bot_username")) });
    return J({ error: "not_found" }, 404);
  } catch (e) {
    console.log("fatal", String(e));
    return J({ error: "server" }, 500);
  }
});
