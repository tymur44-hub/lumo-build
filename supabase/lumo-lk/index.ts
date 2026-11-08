// Lumo: групповые звонки через LiveKit — выдача доступа к комнате и состояние звонка
import { createClient } from "npm:@supabase/supabase-js@2";
import { pushUsers } from "./push.ts";

const SB_URL = Deno.env.get("SUPABASE_URL")!;
const SRK = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const db = createClient(SB_URL, SRK, { auth: { persistSession: false } });

const CORS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};
const json = (d: unknown, status = 200) =>
  new Response(JSON.stringify(d), { status, headers: { ...CORS, "Content-Type": "application/json; charset=utf-8" } });

let cfg: { t: number; url: string; key: string; secret: string } | null = null;
async function lk() {
  if (cfg && Date.now() - cfg.t < 60000) return cfg;
  const { data } = await db.from("lm_secrets").select("key,value").in("key", ["livekit_url", "livekit_key", "livekit_secret"]);
  const v: Record<string, string> = {};
  (data || []).forEach((r: { key: string; value: string }) => (v[r.key] = r.value));
  cfg = { t: Date.now(), url: v.livekit_url || "", key: v.livekit_key || "", secret: v.livekit_secret || "" };
  return cfg;
}

const b64u = (b: Uint8Array | string) => {
  const bytes = typeof b === "string" ? new TextEncoder().encode(b) : b;
  let s = ""; bytes.forEach((x) => (s += String.fromCharCode(x)));
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
};
async function jwt(payload: Record<string, unknown>, secret: string) {
  const head = b64u(JSON.stringify({ alg: "HS256", typ: "JWT" }));
  const body = b64u(JSON.stringify(payload));
  const k = await crypto.subtle.importKey("raw", new TextEncoder().encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const sig = new Uint8Array(await crypto.subtle.sign("HMAC", k, new TextEncoder().encode(head + "." + body)));
  return head + "." + body + "." + b64u(sig);
}

const roomOf = (chat: string) => "g_" + chat;

async function participants(room: string): Promise<{ identity: string; name: string }[]> {
  const c = await lk();
  const now = Math.floor(Date.now() / 1000);
  const t = await jwt({ iss: c.key, nbf: now - 10, exp: now + 300, video: { roomAdmin: true, room, roomList: true } }, c.secret);
  const http = c.url.replace(/^wss:/, "https:").replace(/^ws:/, "http:");
  const r = await fetch(http + "/twirp/livekit.RoomService/ListParticipants", {
    method: "POST", headers: { Authorization: "Bearer " + t, "Content-Type": "application/json" }, body: JSON.stringify({ room }),
  });
  if (!r.ok) return [];
  const j = await r.json().catch(() => ({}));
  // deno-lint-ignore no-explicit-any
  return (j.participants || []).map((p: any) => ({ identity: p.identity, name: p.name || "" }));
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: CORS });
  try {
    const tok = (req.headers.get("authorization") || "").replace(/^Bearer\s+/i, "");
    const { data: u } = await db.auth.getUser(tok);
    if (!u?.user) return json({ error: "unauthorized" }, 401);
    const me = u.user.id;
    const body = await req.json();
    const { chat_id, action } = body;
    if (!chat_id) return json({ error: "chat_id" }, 400);
    const { data: chat } = await db.from("lm_chats").select("id,type,title,avatar_url,color,calls").eq("id", chat_id).maybeSingle();
    if (!chat || chat.type !== "group") return json({ error: "Групповые звонки — только в группах" }, 400);
    const { data: mem } = await db.from("lm_members").select("user_id,role").eq("chat_id", chat_id).eq("user_id", me).maybeSingle();
    if (!mem) return json({ error: "Вы не участник группы" }, 403);
    const admin = mem.role === "owner" || mem.role === "admin";
    const mode = chat.calls || "all";
    const c = await lk();
    if (!c.url || !c.key || !c.secret) return json({ error: "Групповые звонки не настроены" }, 500);
    const room = roomOf(chat_id);

    if (action === "status") {
      const ps = mode === "off" ? [] : await participants(room);
      return json({ active: ps.length > 0, count: ps.length, ids: ps.map((p) => p.identity), names: ps.map((p) => p.name),
        mode, admin, can_start: mode === "all" || (mode === "admins" && admin) });
    }

    if (action === "members") {
      const ps = await participants(room);
      const inCall = new Set(ps.map((p) => p.identity));
      const { data: ms } = await db.from("lm_members").select("user_id").eq("chat_id", chat_id).limit(500);
      const ids = (ms || []).map((m: { user_id: string }) => m.user_id).filter((id: string) => id !== me);
      const { data: profs } = ids.length ? await db.from("lm_profiles").select("id,name,avatar_url,color").in("id", ids) : { data: [] };
      // deno-lint-ignore no-explicit-any
      return json({ members: (profs || []).map((p: any) => ({ id: p.id, name: p.name, avatar: p.avatar_url, color: p.color, in_call: inCall.has(p.id) })) });
    }

    if (action === "invite") {
      if (mode === "off") return json({ error: "Звонки в этой группе отключены" }, 403);
      const want: string[] = Array.isArray(body.user_ids) ? body.user_ids.slice(0, 50) : [];
      if (!want.length) return json({ ok: true, sent: 0 });
      const { data: ok } = await db.from("lm_members").select("user_id").eq("chat_id", chat_id).in("user_id", want);
      const to = (ok || []).map((m: { user_id: string }) => m.user_id);
      const ps = await participants(room);
      const { data: from } = await db.from("lm_profiles").select("name,avatar_url").eq("id", me).maybeSingle();
      const payload = { chat_id, title: chat.title || "Группа", avatar: chat.avatar_url, color: chat.color ?? 0,
        from: from?.name || "Участник", from_id: me, names: ps.map((p) => p.name).filter(Boolean), count: ps.length, at: Date.now() };
      const r = await fetch(SB_URL + "/realtime/v1/api/broadcast", {
        method: "POST", headers: { apikey: SRK, Authorization: "Bearer " + SRK, "Content-Type": "application/json" },
        body: JSON.stringify({ messages: to.map((u) => ({ topic: "lm-gc-" + u, event: "invite", payload })) }),
      });
      // уведомление тем, у кого Lumo сейчас закрыт (вкладка, браузер или приложение)
      const { data: act } = await db.from("lm_profiles").select("id,app_active,last_seen").in("id", to);
      const away = (act || []).filter((p: { app_active?: boolean; last_seen?: string }) =>
        !(p.app_active && p.last_seen && Date.now() - new Date(p.last_seen).getTime() < 100000)).map((p: { id: string }) => p.id);
      const pushed = await pushUsers(away, { title: chat.title || "Групповой звонок", body: `Входящий групповой звонок · ${from?.name || "Участник"} приглашает вас`,
        tag: "gcall-" + chat_id, chat: chat_id, call: true, gcall: true }, 60);
      return json({ ok: r.ok, sent: to.length, pushed });
    }

    if (mode === "off") return json({ error: "Звонки в этой группе отключены администратором" }, 403);

    const { data: prof } = await db.from("lm_profiles").select("name,avatar_url,color").eq("id", me).maybeSingle();
    const now = Math.floor(Date.now() / 1000);
    const token = await jwt({
      iss: c.key, sub: me, nbf: now - 10, exp: now + 6 * 3600,
      name: prof?.name || "Участник",
      metadata: JSON.stringify({ avatar: prof?.avatar_url || null, color: prof?.color ?? 0 }),
      video: { room, roomJoin: true, canPublish: true, canSubscribe: true, canPublishData: true },
    }, c.secret);
    let started = false;
    if (action === "start") {
      const ps = await participants(room);
      if (ps.length === 0) {
        if (mode === "admins" && !admin) return json({ error: "Начать звонок в этой группе могут только администраторы" }, 403);
        const { data: last } = await db.from("lm_messages").select("id,created_at").eq("chat_id", chat_id).eq("kind", "system")
          .contains("meta", { gcall: true }).order("created_at", { ascending: false }).limit(1);
        const recent = last?.[0] && Date.now() - new Date(last[0].created_at).getTime() < 120000;
        if (!recent) {
          await db.from("lm_messages").insert({ chat_id, sender_id: me, kind: "system",
            body: `${prof?.name || "Участник"} начал(а) групповой звонок`, meta: { gcall: true } });
          started = true;
        }
      }
    }
    return json({ url: c.url, token, room, started });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
