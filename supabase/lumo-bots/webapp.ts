// Мини-приложения ботов Lumo (по образцу Telegram Web Apps): подписанные данные пользователя, мост JS и конструктор ботов
import { db, botJson as json, rnd, isPremium, createBotFor, deleteBotFor, pushUpdate, fromObj } from "./bots.ts";
import type { Row } from "./bots.ts";

const enc = new TextEncoder();
const hex = (b: ArrayBuffer) => Array.from(new Uint8Array(b)).map((x) => x.toString(16).padStart(2, "0")).join("");
async function hmac(key: ArrayBuffer | string, msg: string): Promise<ArrayBuffer> {
  const k = await crypto.subtle.importKey("raw", typeof key === "string" ? enc.encode(key) : key, { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  return await crypto.subtle.sign("HMAC", k, enc.encode(msg));
}
// как в Telegram: secret = HMAC("WebAppData", токен бота); hash = HMAC(secret, отсортированные key=value через \n)
async function signFields(token: string, f: Record<string, string>) {
  const dcs = Object.keys(f).sort().map((k) => `${k}=${f[k]}`).join("\n");
  return hex(await hmac(await hmac("WebAppData", token), dcs));
}
async function makeInit(bot: Row, user: Row) {
  const f: Record<string, string> = {
    auth_date: String(Math.floor(Date.now() / 1000)),
    user: JSON.stringify({ id: user.id, first_name: user.name, username: user.username, language_code: "ru" }),
    bot_id: bot.id,
  };
  const hash = await signFields(bot.token, f);
  return new URLSearchParams({ ...f, hash }).toString();
}
async function verifyInit(initData: string, token: string): Promise<Row | null> {
  try {
    const sp = new URLSearchParams(initData);
    const hash = sp.get("hash") || "";
    sp.delete("hash");
    const f: Record<string, string> = {};
    sp.forEach((v, k) => (f[k] = v));
    if ((await signFields(token, f)) !== hash) return null;
    if (Date.now() / 1000 - Number(f.auth_date || 0) > 86400) return null;
    return JSON.parse(f.user || "null");
  } catch (_) { return null; }
}

const THEME_KEYS = ["bg_color", "text_color", "hint_color", "link_color", "button_color", "button_text_color", "secondary_bg_color"];
function cleanTheme(t: Row | undefined) {
  const o: Record<string, string> = {};
  for (const k of THEME_KEYS) { const v = t?.[k]; if (typeof v === "string" && /^#[0-9a-fA-F]{6}$/.test(v)) o[k] = v; }
  return o;
}

// Скрипт моста: window.Lumo.WebApp (и псевдоним window.Telegram.WebApp). Клиент заранее задаёт window.__lumoPost(event, data)
function bridgeJs(initData: string, user: Row, theme: Record<string, string>, scheme: string, platform: string) {
  return `(function(){
if(window.Lumo&&window.Lumo.WebApp)return;
var post=function(e,d){try{window.__lumoPost(e,d||{})}catch(_){}};
var theme=${JSON.stringify(theme)};
var listeners={};
function emit(n,a){(listeners[n]||[]).slice().forEach(function(f){try{f(a)}catch(_){}})}
function applyTheme(){var r=document.documentElement;for(var k in theme){r.style.setProperty('--tg-theme-'+k.replace(/_/g,'-'),theme[k]);r.style.setProperty('--lumo-'+k.replace(/_/g,'-'),theme[k]);}r.style.setProperty('--tg-viewport-height','100vh');r.style.setProperty('--tg-viewport-stable-height','100vh');}
applyTheme();
var ready=function(f){if(document.body)f();else document.addEventListener('DOMContentLoaded',f)};
var css=document.createElement('style');css.textContent='.lm-ov{position:fixed;inset:0;background:rgba(0,0,0,.45);display:flex;align-items:center;justify-content:center;z-index:2147483646;padding:24px}.lm-box{background:'+(theme.secondary_bg_color||'#fff')+';color:'+(theme.text_color||'#000')+';border-radius:18px;padding:18px;max-width:320px;width:100%;font:15px -apple-system,system-ui,sans-serif}.lm-box h3{margin:0 0 6px;font-size:17px}.lm-box p{margin:0 0 14px;white-space:pre-wrap}.lm-row{display:flex;gap:8px;justify-content:flex-end;flex-wrap:wrap}.lm-b{border:0;border-radius:12px;padding:10px 16px;font:600 15px inherit;background:rgba(127,127,127,.18);color:'+(theme.link_color||'#2a7fff')+'}.lm-b.p{background:'+(theme.button_color||'#2a7fff')+';color:'+(theme.button_text_color||'#fff')+'}.lm-b.d{color:#ff453a}#lm-main{position:fixed;left:12px;right:12px;bottom:12px;z-index:2147483645;border:0;border-radius:14px;padding:14px;font:600 16px -apple-system,system-ui,sans-serif;display:none}';
(document.head||document.documentElement).appendChild(css);
function modal(title,msg,buttons,cb){ready(function(){var ov=document.createElement('div');ov.className='lm-ov';var bx=document.createElement('div');bx.className='lm-box';if(title){var h=document.createElement('h3');h.textContent=title;bx.appendChild(h)}var p=document.createElement('p');p.textContent=msg||'';bx.appendChild(p);var row=document.createElement('div');row.className='lm-row';buttons.forEach(function(b){var x=document.createElement('button');x.className='lm-b'+(b.type==='default'||b.type==='ok'?' p':'')+(b.type==='destructive'?' d':'');x.textContent=b.text||'OK';x.onclick=function(){ov.remove();if(cb)cb(b.id)};row.appendChild(x)});bx.appendChild(row);ov.appendChild(bx);document.body.appendChild(ov)})}
var mbEl=null,mbCb=[];
var MB={text:'',color:theme.button_color||'#2a7fff',textColor:theme.button_text_color||'#fff',isVisible:false,isActive:true,isProgressVisible:false,
render:function(){ready(function(){if(!mbEl){mbEl=document.createElement('button');mbEl.id='lm-main';mbEl.onclick=function(){if(MB.isActive)mbCb.slice().forEach(function(f){f()})};document.body.appendChild(mbEl)}mbEl.textContent=MB.isProgressVisible?'…':MB.text;mbEl.style.background=MB.color;mbEl.style.color=MB.textColor;mbEl.style.opacity=MB.isActive?1:.5;mbEl.style.display=MB.isVisible?'block':'none';document.body.style.paddingBottom=MB.isVisible?'76px':''})},
setText:function(t){MB.text=t;MB.render();return MB},onClick:function(f){mbCb.push(f);return MB},offClick:function(f){mbCb=mbCb.filter(function(x){return x!==f});return MB},show:function(){MB.isVisible=true;MB.render();return MB},hide:function(){MB.isVisible=false;MB.render();return MB},enable:function(){MB.isActive=true;MB.render();return MB},disable:function(){MB.isActive=false;MB.render();return MB},showProgress:function(){MB.isProgressVisible=true;MB.render();return MB},hideProgress:function(){MB.isProgressVisible=false;MB.render();return MB},setParams:function(p){if(p.text!==undefined)MB.text=p.text;if(p.color)MB.color=p.color;if(p.text_color)MB.textColor=p.text_color;if(p.is_visible!==undefined)MB.isVisible=p.is_visible;if(p.is_active!==undefined)MB.isActive=p.is_active;MB.render();return MB}};
var BB={isVisible:false,onClick:function(f){BB._f=f;return BB},offClick:function(){BB._f=null;return BB},show:function(){BB.isVisible=true;post('backButton',{visible:true});return BB},hide:function(){BB.isVisible=false;post('backButton',{visible:false});return BB}};
var noop=function(){};
var W={initData:${JSON.stringify(initData)},initDataUnsafe:{user:${JSON.stringify({ id: user.id, first_name: user.name, username: user.username, language_code: "ru" })},auth_date:${Math.floor(Date.now() / 1000)}},version:'7.0',platform:${JSON.stringify(platform)},colorScheme:${JSON.stringify(scheme)},themeParams:theme,isExpanded:true,viewportHeight:window.innerHeight,viewportStableHeight:window.innerHeight,headerColor:theme.bg_color,backgroundColor:theme.bg_color,isClosingConfirmationEnabled:false,
MainButton:MB,BackButton:BB,
HapticFeedback:{impactOccurred:function(s){post('haptic',{style:s||'light'})},notificationOccurred:function(t){post('haptic',{style:t||'success'})},selectionChanged:function(){post('haptic',{style:'selection'})}},
ready:function(){post('ready')},expand:noop,close:function(){post('close')},
sendData:function(d){post('sendData',{data:String(d).slice(0,4096)})},
openLink:function(u){post('openLink',{url:String(u)})},openTelegramLink:function(u){post('openLink',{url:String(u)})},
copyText:function(t){post('copy',{text:String(t)})},
showAlert:function(m,cb){modal('',m,[{id:'ok',text:'OK',type:'ok'}],function(){if(cb)cb()})},
showConfirm:function(m,cb){modal('',m,[{id:'no',text:'Отмена'},{id:'yes',text:'Да',type:'ok'}],function(i){if(cb)cb(i==='yes')})},
showPopup:function(p,cb){modal(p.title||'',p.message||'',(p.buttons||[{id:'ok',type:'ok'}]).map(function(b){return{id:b.id,text:b.text||(b.type==='cancel'?'Отмена':'OK'),type:b.type}}),function(i){if(cb)cb(i)})},
setHeaderColor:noop,setBackgroundColor:noop,enableClosingConfirmation:noop,disableClosingConfirmation:noop,
onEvent:function(n,f){(listeners[n]=listeners[n]||[]).push(f)},offEvent:function(n,f){listeners[n]=(listeners[n]||[]).filter(function(x){return x!==f})},
isVersionAtLeast:function(){return true}};
window.Lumo={WebApp:W};window.Telegram={WebApp:W};
window.__lumoBack=function(){if(BB._f)BB._f();else post('close')};
window.__lumoTheme=function(t,s){theme=t;W.themeParams=t;W.colorScheme=s;applyTheme();emit('themeChanged')};
window.addEventListener('resize',function(){W.viewportHeight=window.innerHeight;emit('viewportChanged',{isStateStable:true})});
})();`;
}

async function authUser(req: Request) {
  const jwt = (req.headers.get("authorization") || "").replace(/^Bearer\s+/i, "");
  const { data: u } = await db.auth.getUser(jwt);
  const id = u?.user?.id;
  if (!id) return null;
  const { data } = await db.from("lm_profiles").select("id,username,name").eq("id", id).maybeSingle();
  return data as Row | null;
}

export async function handleWebApp(req: Request, path: string) {
  const action = path.split("/webapp/")[1] || "";
  const b: Row = await req.json().catch(() => ({}));

  // --- открытие мини-приложения: подписанные данные + мост + (для встроенных) готовый HTML ---
  if (action === "init") {
    const user = await authUser(req);
    if (!user) return json({ ok: false, error: "unauthorized" }, 401);
    const { data: bot } = await db.from("lm_bots").select("*").eq("id", String(b.bot_id || "")).maybeSingle();
    if (!bot) return json({ ok: false, error: "Бот не найден" }, 404);
    const { data: pr } = await db.from("lm_profiles").select("username,name").eq("id", bot.id).maybeSingle();
    let url = String(b.url || bot.web_app_url || "");
    if (!url) return json({ ok: false, error: "У бота нет мини-приложения" }, 400);
    const out: Row = { ok: true, title: pr?.name || "Мини-приложение", username: pr?.username };
    const initData = await makeInit(bot, user);
    const theme = cleanTheme(b.theme);
    const scheme = b.scheme === "light" ? "light" : "dark";
    out.init_data = initData;
    out.bridge = bridgeJs(initData, user, theme, scheme, String(b.platform || "android").slice(0, 12));
    const m = url.match(/^lumo:\/\/builtin\/([a-z0-9_]+)$/);
    if (m) {
      if (bot.builtin !== m[1]) return json({ ok: false, error: "Недоступно" }, 403);
      const { data: h } = await db.from("lm_code").select("content").eq("name", "miniapp_" + m[1]).eq("part", 0).maybeSingle();
      if (!h?.content) return json({ ok: false, error: "Мини-приложение пока не опубликовано" }, 404);
      out.html = String(h.content);
    } else {
      if (!/^https:\/\//.test(url)) return json({ ok: false, error: "Нужна ссылка https" }, 400);
      const sep = url.includes("#") ? "&" : "#";
      url += sep + "tgWebAppData=" + encodeURIComponent(initData) + "&tgWebAppVersion=7.0&tgWebAppPlatform=" + encodeURIComponent(String(b.platform || "android")) + "&tgWebAppThemeParams=" + encodeURIComponent(JSON.stringify(theme));
      out.url = url;
    }
    return json(out);
  }

  // --- WebApp.sendData: служебное сообщение боту ---
  if (action === "data") {
    const user = await authUser(req);
    if (!user) return json({ ok: false, error: "unauthorized" }, 401);
    const { data: bot } = await db.from("lm_bots").select("*").eq("id", String(b.bot_id || "")).maybeSingle();
    if (!bot || bot.builtin) return json({ ok: true });
    await pushUpdate(bot, { message: { message_id: 0, from: fromObj(user), chat: { id: user.id, type: "private" }, date: Math.floor(Date.now() / 1000), web_app_data: { data: String(b.data || "").slice(0, 4096) } } });
    return json({ ok: true });
  }

  // --- API встроенного конструктора ботов: проверка подписи initData токеном BotFather ---
  if (action === "father") {
    const { data: fb } = await db.from("lm_bots").select("token").eq("builtin", "botfather").maybeSingle();
    const u = fb ? await verifyInit(req.headers.get("x-init-data") || "", fb.token) : null;
    if (!u?.id) return json({ ok: false, error: "Сессия устарела — закройте и откройте конструктор заново" }, 401);
    const uid = String(u.id);
    const mineBot = async (id: string) => {
      const { data } = await db.from("lm_bots").select("*").eq("id", id).eq("owner_id", uid).is("builtin", null).maybeSingle();
      return data as Row | null;
    };
    const op = String(b.op || "");
    if (op === "list") {
      const { data: bots } = await db.from("lm_bots").select("id,description,commands,webhook_url,web_app_url,menu_text").eq("owner_id", uid).is("builtin", null);
      const ids = (bots || []).map((x: Row) => x.id);
      const { data: ps } = ids.length ? await db.from("lm_profiles").select("id,username,name,color").in("id", ids) : { data: [] };
      const pm = new Map((ps || []).map((p: Row) => [p.id, p]));
      return json({
        ok: true, premium: await isPremium(uid), limit: 5,
        bots: (bots || []).map((x: Row) => ({ ...x, username: pm.get(x.id)?.username, name: pm.get(x.id)?.name, color: pm.get(x.id)?.color ?? 0 })),
      });
    }
    if (op === "create") {
      const r = await createBotFor(uid, String(b.username || ""), String(b.name || ""), String(b.description || ""));
      return json(r, r.ok ? 200 : 400);
    }
    const bot = await mineBot(String(b.id || ""));
    if (!bot) return json({ ok: false, error: "Бот не найден" }, 404);
    if (op === "token") return json({ ok: true, token: bot.token });
    if (op === "regen") {
      const token = bot.id.replace(/-/g, "").slice(0, 10) + ":" + rnd(32);
      await db.from("lm_bots").update({ token }).eq("id", bot.id);
      return json({ ok: true, token });
    }
    if (op === "delete") { await deleteBotFor(bot.id); return json({ ok: true }); }
    if (op === "update") {
      const upd: Row = {}, prof: Row = {};
      if (typeof b.name === "string") { const n = b.name.trim().slice(0, 64); if (!n) return json({ ok: false, error: "Название не может быть пустым" }, 400); prof.name = n; }
      if (typeof b.description === "string") { upd.description = b.description.slice(0, 300); prof.bio = b.description.slice(0, 200); }
      if (Array.isArray(b.commands)) {
        upd.commands = b.commands.slice(0, 30).map((c: Row) => ({ command: String(c.command || "").replace(/^\//, "").toLowerCase().replace(/[^a-z0-9_]/g, "").slice(0, 32), description: String(c.description || "").slice(0, 100) })).filter((c: Row) => c.command);
      }
      if (typeof b.web_app_url === "string") {
        const w = b.web_app_url.trim();
        if (w && !/^https:\/\//.test(w)) return json({ ok: false, error: "Ссылка мини-приложения должна начинаться с https://" }, 400);
        upd.web_app_url = w || null;
        upd.menu_text = w ? String(b.menu_text || "Открыть").trim().slice(0, 24) || "Открыть" : null;
      }
      if (typeof b.webhook_url === "string") {
        const w = b.webhook_url.trim();
        if (w && !/^https:\/\//.test(w)) return json({ ok: false, error: "Webhook должен начинаться с https://" }, 400);
        upd.webhook_url = w || null;
      }
      if (Object.keys(upd).length) await db.from("lm_bots").update(upd).eq("id", bot.id);
      if (Object.keys(prof).length) await db.from("lm_profiles").update(prof).eq("id", bot.id);
      return json({ ok: true });
    }
    return json({ ok: false, error: "Неизвестное действие" }, 400);
  }
  return json({ ok: false, error: "not found" }, 404);
}
