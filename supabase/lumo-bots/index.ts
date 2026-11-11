// Lumo bots: обработчик ботов, Bot API, мини-приложения и крон-задачи
import { handleBotMsg, handleBotCb, handleBotApi, setupBuiltin, botJson } from "./bots.ts";
import { handleWebApp } from "./webapp.ts";
import { AVATARS } from "./avatars.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });
const CORS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info, x-init-data",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};
async function hookOk(req: Request) {
  const { data } = await db.from("lm_secrets").select("value").eq("key", "hook_secret").maybeSingle();
  return !!data && req.headers.get("x-lumo-hook") === data.value;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  const path = new URL(req.url).pathname.replace(/\/+$/, "");
  try {
    // аватарки встроенных ботов: /avatar/verify.png
    const av = path.match(/\/avatar\/([a-z]+)\.png$/);
    if (av && req.method === "GET" && AVATARS[av[1]]) {
      return new Response(AVATARS[av[1]], { headers: { ...CORS, "Content-Type": "image/png", "Cache-Control": "public, max-age=86400" } });
    }
    if (path.includes("/botapi/")) return await handleBotApi(req, path);
    if (path.includes("/webapp/")) return await handleWebApp(req, path);
    if (path.endsWith("/cb") && req.method === "POST") return await handleBotCb(req);
    if (path.endsWith("/botmsg") && req.method === "POST") {
      if (!(await hookOk(req))) return botJson({ error: "forbidden" }, 403);
      const b = await req.json();
      await handleBotMsg(Number(b.message_id), String(b.bot_id));
      return botJson({ ok: true });
    }
    if (path.endsWith("/setup") && req.method === "POST") {
      if (!(await hookOk(req))) return botJson({ error: "forbidden" }, 403);
      return botJson({ ok: true, bots: await setupBuiltin() });
    }
    return botJson({ ok: true, service: "lumo-bots" });
  } catch (e) {
    return botJson({ error: String(e) }, 500);
  }
});
