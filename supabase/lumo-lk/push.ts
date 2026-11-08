// Веб-пуш (VAPID, aes128gcm) — тот же механизм, что в функции lumo
import { createClient } from "npm:@supabase/supabase-js@2";
const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });
async function secrets(_force = false) {
  const { data } = await db.from("lm_secrets").select("key,value").in("key", ["vapid", "vapid_sub"]);
  const v: Record<string, string> = {};
  (data || []).forEach((r: { key: string; value: string }) => (v[r.key] = r.value));
  return v;
}
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
let vapidCache: { jwk: { x: string; y: string; d: string }; pub: string } | null = null;
async function vapid() {
  if (vapidCache) return vapidCache;
  const s = await secrets();
  if (!s.vapid) return null;
  vapidCache = JSON.parse(s.vapid);
  return vapidCache!;
}
export async function pushUsers(ids: string[], data: Record<string, unknown>, ttl = 86400) {
  if (!ids.length) return 0;
  const { data: subs } = await db.from("lm_push").select("endpoint,p256dh,auth").in("user_id", ids);
  if (!subs?.length) return 0;
  const v = await vapid();
  if (!v) return 0;
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
    } catch (_e) { /* пропускаем */ }
  }));
  return n;
}
