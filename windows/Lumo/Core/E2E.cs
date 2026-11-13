using System.Security.Cryptography;
using System.Text;

namespace Lumo.Core;

/// <summary>
/// Сквозное шифрование личных чатов (совместимо с телефонами и веб-версией).
/// Ключевая пара P-256; открытая часть — на сервере (lm_keys), закрытая — на устройстве и в резервной копии (lm_key_backup).
/// Ключ чата = HKDF-SHA256(ECDH, соль = id чата, info = "lumo-e2e-v1"); сообщение = "e2e1:" + base64(iv12 ‖ шифртекст ‖ тег), AES-256-GCM.
/// </summary>
public static class E2E
{
    public const string PREFIX = "e2e1:";
    public const string LOCKED = "Не удалось расшифровать";
    public enum State { Loading, Ready, NeedRestore }

    public static State Status { get; private set; } = State.Loading;
    public static event Action? Changed;

    static string? me;
    static byte[]? myD, myPub;
    static readonly Dictionary<string, byte[]> peerPubs = new();
    static readonly Dictionary<string, DateTime> noKeyAt = new();
    static readonly Dictionary<string, byte[]> chatKeys = new();
    static readonly Dictionary<string, string> chatPeer = new();
    static readonly Dictionary<string, DateTime> checkedAt = new();
    public static readonly HashSet<string> KeyChanged = new();
    static bool verified;

    static string B64(byte[] b) => Convert.ToBase64String(b);
    static byte[] Unb64(string s) => Convert.FromBase64String(s.Trim());

    static byte[] Seal(byte[] key, byte[] plain)
    {
        var iv = RandomNumberGenerator.GetBytes(12);
        var ct = new byte[plain.Length]; var tag = new byte[16];
        using var g = new AesGcm(key, 16);
        g.Encrypt(iv, plain, ct, tag);
        return iv.Concat(ct).Concat(tag).ToArray();
    }

    static byte[]? Open(byte[] key, byte[] data)
    {
        try
        {
            if (data.Length < 28) return null;
            var iv = data[..12]; var tag = data[^16..]; var ct = data[12..^16];
            var pt = new byte[ct.Length];
            using var g = new AesGcm(key, 16);
            g.Decrypt(iv, ct, tag, pt);
            return pt;
        }
        catch { return null; }
    }

    static ECDiffieHellman Priv(byte[] d, byte[] pub) => ECDiffieHellman.Create(new ECParameters
    {
        Curve = ECCurve.NamedCurves.nistP256, D = d, Q = new ECPoint { X = pub[1..33], Y = pub[33..65] },
    });

    static ECDiffieHellman PubKey(byte[] raw)
    {
        if (raw.Length != 65 || raw[0] != 4) throw new ArgumentException("bad key");
        return ECDiffieHellman.Create(new ECParameters { Curve = ECCurve.NamedCurves.nistP256, Q = new ECPoint { X = raw[1..33], Y = raw[33..65] } });
    }

    // ---------- хранение ключа на компьютере ----------

    static void SaveLocal(string uid, byte[] d, byte[] pub) => Prefs.SetSecret("e2e_key_" + uid, B64(d.Concat(pub).ToArray()));

    static (byte[] d, byte[] pub)? LoadLocal(string uid)
    {
        var s = Prefs.GetSecret("e2e_key_" + uid);
        if (s == null) return null;
        try { var raw = Unb64(s); if (raw.Length != 97) return null; return (raw[..32], raw[32..]); } catch { return null; }
    }

    static void Install(string uid, byte[] d, byte[] pub)
    {
        me = uid; myD = d; myPub = pub;
        chatKeys.Clear(); chatPeer.Clear(); peerPubs.Clear(); noKeyAt.Clear();
    }

    static void SetStatus(State s) { Status = s; Changed?.Invoke(); }

    /// <summary>Запуск после входа</summary>
    public static async Task Setup(string uid)
    {
        if (me == uid && Status == State.Ready && myD != null && verified) return;
        var local = LoadLocal(uid);
        if (local != null && !(me == uid && myD != null)) { Install(uid, local.Value.d, local.Value.pub); SetStatus(State.Ready); }
        try
        {
            var srv = (await Api.Select("lm_keys", Api.Q(("select", "pub"), ("user_id", "eq." + uid)))).FirstOrDefault().Str("pub");
            verified = true;
            if (local != null && (srv == null || srv == B64(local.Value.pub)))
            {
                if (!(me == uid && myD != null)) Install(uid, local.Value.d, local.Value.pub);
                if (srv == null) await Publish(uid, local.Value.pub);
                var b = (await Api.Select("lm_key_backup", Api.Q(("select", "iters"), ("user_id", "eq." + uid)))).FirstOrDefault();
                SetStatus(State.Ready);
                if (b == null || b.Int("iters") != 0) await AutoBackup();
                return;
            }
            if (local != null) { Prefs.Set("e2e_key_" + uid, null); chatKeys.Clear(); }
            if (srv != null)
            {
                if (await AutoRestore(uid, srv)) return;
                me = uid; myD = null; SetStatus(State.NeedRestore); return;
            }
            await GenerateAndPublish(uid);
            await AutoBackup();
        }
        catch { if (Status == State.Loading && myD != null) SetStatus(State.Ready); }
    }

    static Task Publish(string uid, byte[] pub) =>
        Api.Raw("POST", "/rest/v1/lm_keys", Api.Q(("on_conflict", "user_id")), J.O(("user_id", uid), ("pub", B64(pub))),
            Api.Q(("Prefer", "resolution=merge-duplicates,return=minimal")));

    static async Task GenerateAndPublish(string uid)
    {
        using var k = ECDiffieHellman.Create(ECCurve.NamedCurves.nistP256);
        var p = k.ExportParameters(true);
        var d = Fixed(p.D!); var pub = new byte[] { 4 }.Concat(Fixed(p.Q.X!)).Concat(Fixed(p.Q.Y!)).ToArray();
        await Publish(uid, pub);
        SaveLocal(uid, d, pub); Install(uid, d, pub);
        SetStatus(State.Ready);
    }

    static byte[] Fixed(byte[] b) => b.Length == 32 ? b : b.Length > 32 ? b[^32..] : new byte[32 - b.Length].Concat(b).ToArray();

    public static void Forget()
    {
        me = null; myD = null; myPub = null; chatKeys.Clear(); chatPeer.Clear(); peerPubs.Clear(); noKeyAt.Clear(); KeyChanged.Clear();
        verified = false; Status = State.Loading;
    }

    // ---------- резервная копия без пароля (ключ обёртки выдаёт сервер владельцу) ----------

    static async Task<byte[]?> ServerWrap()
    {
        try
        {
            var s = (await Api.Rpc("lm_wrap_key"))?.GetValue<string>();
            if (s == null) return null;
            var d = Unb64(s);
            return d.Length == 32 ? d : null;
        }
        catch { return null; }
    }

    public static async Task<bool> AutoBackup()
    {
        if (me == null || myD == null || myPub == null) return false;
        var wk = await ServerWrap(); if (wk == null) return false;
        try
        {
            var blob = Seal(wk, myD.Concat(myPub).ToArray());
            await Api.Raw("POST", "/rest/v1/lm_key_backup", Api.Q(("on_conflict", "user_id")),
                J.O(("user_id", me), ("salt", ""), ("iters", 0), ("blob", B64(blob)), ("updated_at", Dates.Iso(DateTimeOffset.UtcNow))),
                Api.Q(("Prefer", "resolution=merge-duplicates,return=minimal")));
            return true;
        }
        catch { return false; }
    }

    static async Task<bool> AutoRestore(string uid, string srvPub)
    {
        try
        {
            var row = (await Api.Select("lm_key_backup", Api.Q(("select", "iters,blob"), ("user_id", "eq." + uid)))).FirstOrDefault();
            if (row == null || row.Int("iters") != 0) return false;
            var blob = Unb64(row.Str("blob") ?? "");
            var wk = await ServerWrap(); if (wk == null) return false;
            var plain = Open(wk, blob); if (plain == null || plain.Length != 97) return false;
            var d = plain[..32]; var pub = plain[32..];
            if (B64(pub) != srvPub) return false;
            SaveLocal(uid, d, pub); Install(uid, d, pub); SetStatus(State.Ready);
            return true;
        }
        catch { return false; }
    }

    /// <summary>Старая копия под паролем; false — неверный пароль или нет копии</summary>
    public static async Task<bool> Restore(string password)
    {
        var uid = Api.UserId; if (uid == null) return false;
        try
        {
            var row = (await Api.Select("lm_key_backup", Api.Q(("select", "salt,iters,blob"), ("user_id", "eq." + uid)))).FirstOrDefault();
            if (row == null) return false;
            var salt = Unb64(row.Str("salt") ?? ""); var iters = row.Int("iters") ?? 310000; var blob = Unb64(row.Str("blob") ?? "");
            var plain = await Task.Run(() => Open(Rfc2898DeriveBytes.Pbkdf2(Encoding.UTF8.GetBytes(password), salt, iters, HashAlgorithmName.SHA256, 32), blob));
            if (plain == null || plain.Length != 97) return false;
            var d = plain[..32]; var pub = plain[32..];
            var srv = (await Api.Select("lm_keys", Api.Q(("select", "pub"), ("user_id", "eq." + uid)))).FirstOrDefault().Str("pub");
            if (srv != null && srv != B64(pub)) return false;
            SaveLocal(uid, d, pub); Install(uid, d, pub); SetStatus(State.Ready);
            await AutoBackup();
            return true;
        }
        catch { return false; }
    }

    /// <summary>Забыли пароль: новые ключи, старые зашифрованные сообщения прочитать будет нельзя</summary>
    public static async Task<bool> Reset()
    {
        var uid = Api.UserId; if (uid == null) return false;
        try
        {
            try { await Api.Delete("lm_key_backup", Api.Q(("user_id", uid))); } catch { }
            await GenerateAndPublish(uid);
            await AutoBackup();
            return true;
        }
        catch { return false; }
    }

    // ---------- ключи собеседников и чатов ----------

    static async Task<byte[]?> PeerPub(string uid)
    {
        if (uid == me) return myPub;
        if (peerPubs.TryGetValue(uid, out var k)) return k;
        var saved = Prefs.Get("e2e_last_" + uid) ?? Prefs.Get("e2e_pin_" + uid);
        if (saved != null) { try { var raw = Unb64(saved); if (raw.Length == 65) { peerPubs[uid] = raw; return raw; } } catch { } }
        if (noKeyAt.TryGetValue(uid, out var t) && (DateTime.UtcNow - t).TotalSeconds < 60) return null;
        string? s = null;
        try { s = (await Api.Select("lm_keys", Api.Q(("select", "pub"), ("user_id", "eq." + uid)))).FirstOrDefault().Str("pub"); } catch { }
        if (s == null) { noKeyAt[uid] = DateTime.UtcNow; return null; }
        return Accept(uid, s) ? peerPubs[uid] : null;
    }

    public static void DropCaches() { noKeyAt.Clear(); foreach (var k in peerPubs.Keys.Where(x => x != me).ToList()) peerPubs.Remove(k); chatKeys.Clear(); }

    /// <summary>«Запросить ключ заново»</summary>
    public static async Task ForceRefresh(string chatId, string? peerId)
    {
        if (peerId != null) { checkedAt.Remove(peerId); Prefs.Set("e2e_last_" + peerId, null); peerPubs.Remove(peerId); }
        chatKeys.Remove(chatId);
        if (!await Refresh(chatId, peerId) && peerId != null) await Prepare(chatId, peerId);
    }

    /// <summary>Собеседник мог сменить ключ — сверяемся с сервером (не чаще раза в 20 с). true — ключ обновился</summary>
    public static async Task<bool> Refresh(string chatId, string? peerId)
    {
        if (peerId == null || peerId == me || Status != State.Ready) return false;
        if (checkedAt.TryGetValue(peerId, out var t) && (DateTime.UtcNow - t).TotalSeconds < 20) return false;
        checkedAt[peerId] = DateTime.UtcNow;
        string? s = null;
        try { s = (await Api.Select("lm_keys", Api.Q(("select", "pub"), ("user_id", "eq." + peerId)))).FirstOrDefault().Str("pub"); } catch { }
        if (s == null) return false;
        if (peerPubs.TryGetValue(peerId, out var cur)) { try { if (Unb64(s).SequenceEqual(cur)) return false; } catch { } }
        if (!Accept(peerId, s)) return false;
        foreach (var c in chatKeys.Keys.Where(c => chatPeer.GetValueOrDefault(c) == peerId).ToList()) chatKeys.Remove(c);
        chatKeys.Remove(chatId);
        await Prepare(chatId, peerId);
        return true;
    }

    public static async Task Prefetch(IEnumerable<string> ids)
    {
        var now = DateTime.UtcNow;
        var need = ids.Where(i => i != me && !peerPubs.ContainsKey(i) && (!noKeyAt.TryGetValue(i, out var t) || (now - t).TotalSeconds > 60)).Distinct().ToList();
        if (need.Count == 0) return;
        List<System.Text.Json.Nodes.JsonObject> rows;
        try { rows = await Api.Select("lm_keys", Api.Q(("select", "user_id,pub"), ("user_id", "in.(" + string.Join(",", need) + ")"))); } catch { return; }
        var got = new HashSet<string>();
        foreach (var r in rows) { var u = r.Str("user_id"); var s = r.Str("pub"); if (u != null && s != null && Accept(u, s)) got.Add(u); }
        foreach (var i in need.Where(x => !got.Contains(x))) noKeyAt[i] = now;
    }

    static bool Accept(string uid, string s)
    {
        byte[] raw;
        try { raw = Unb64(s); } catch { return false; }
        if (raw.Length != 65) return false;
        noKeyAt.Remove(uid);
        var pinned = Prefs.Get("e2e_pin_" + uid);
        if (pinned == null) Prefs.Set("e2e_pin_" + uid, s); else if (pinned != s) KeyChanged.Add(uid);
        peerPubs[uid] = raw;
        Prefs.Set("e2e_last_" + uid, s);
        return true;
    }

    /// <summary>Подготовить ключ чата (личный чат; peerId == null — «Избранное»)</summary>
    public static async Task Prepare(string chatId, string? peerId)
    {
        if (Status != State.Ready || myD == null || myPub == null) return;
        if (chatKeys.ContainsKey(chatId)) return;
        var peer = peerId ?? me; if (peer == null) return;
        var pub = await PeerPub(peer); if (pub == null) return;
        try
        {
            using var mine = Priv(myD, myPub);
            using var other = PubKey(pub);
            var secret = mine.DeriveRawSecretAgreement(other.PublicKey);
            chatKeys[chatId] = HKDF.DeriveKey(HashAlgorithmName.SHA256, secret, 32, Encoding.UTF8.GetBytes(chatId.ToLowerInvariant()), Encoding.UTF8.GetBytes("lumo-e2e-v1"));
            chatPeer[chatId] = peer;
        }
        catch { }
    }

    public static bool Active(string chatId) => chatKeys.ContainsKey(chatId);
    public static bool IsEnc(string? body) => body != null && body.StartsWith(PREFIX);

    public static string? Encrypt(string chatId, string text) =>
        chatKeys.TryGetValue(chatId, out var k) ? PREFIX + B64(Seal(k, Encoding.UTF8.GetBytes(text))) : null;

    public static string? Decrypt(string chatId, string? body)
    {
        if (body == null || !body.StartsWith(PREFIX)) return body;
        if (!chatKeys.TryGetValue(chatId, out var k)) return LOCKED;
        byte[] raw;
        try { raw = Unb64(body[PREFIX.Length..]); } catch { return LOCKED; }
        var p = Open(k, raw);
        return p == null ? LOCKED : Encoding.UTF8.GetString(p);
    }

    /// <summary>Код безопасности: одинаковый у обоих собеседников</summary>
    public static string? Safety(string peerId)
    {
        var a = myPub; if (a == null) return null;
        var b = peerId == me ? myPub : peerPubs.GetValueOrDefault(peerId); if (b == null) return null;
        var sa = B64(a); var sb = B64(b);
        var (x, y) = string.CompareOrdinal(sa, sb) <= 0 ? (sa, sb) : (sb, sa);
        var h = SHA256.HashData(Encoding.UTF8.GetBytes(x + "|" + y));
        return string.Join(" ", Enumerable.Range(0, 8).Select(i =>
        {
            long v = ((long)h[i * 4] << 24) | ((long)h[i * 4 + 1] << 16) | ((long)h[i * 4 + 2] << 8) | h[i * 4 + 3];
            return (v % 100000).ToString().PadLeft(5, '0');
        }));
    }
}
