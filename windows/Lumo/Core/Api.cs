using System.Net;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json.Nodes;

namespace Lumo.Core;

public static class Config
{
    public const string SUPABASE = "https://foniukmpiukuwpcdvdhp.supabase.co";
    public const string ANON = "sb_publishable_cE72E1dUPnfaVn8mPnc9sA_U2HO-mxN";
    public const string EMAIL_DOMAIN = "@lumo.app";
    public const string BUCKET = "lm-media";
    public const string SITE = "https://lumomess.ru/";
    /// <summary>Свой адрес сервера (прокси к Supabase) — чтобы Lumo работал в России без VPN</summary>
    public const string PROXY = "https://api.lumomess.ru";
    public static string RealtimeUrl => Net.Base.Replace("https://", "wss://") + "/realtime/v1/websocket?apikey=" + ANON + "&vsn=1.0.0";
}

public class ApiError : Exception
{
    public int Status { get; }
    public ApiError(string message, int status) : base(message) { Status = status; }
}

public record Session(string Access, string Refresh, long ExpiresAt, string UserId);

/// <summary>Выбор адреса сервера: напрямую (supabase.co) или через свой прокси (api.lumomess.ru)</summary>
public static class Net
{
    public static string Base { get; private set; } = Prefs.Get("net_base") ?? Config.SUPABASE;
    static DateTime lastPick = DateTime.MinValue;
    static readonly HttpClient probe = new() { Timeout = TimeSpan.FromSeconds(8) };

    static async Task<bool> Ok(string b)
    {
        try
        {
            using var rq = new HttpRequestMessage(HttpMethod.Get, b + "/functions/v1/lumo/ping?kb=48");
            rq.Headers.TryAddWithoutValidation("apikey", Config.ANON);
            rq.Headers.TryAddWithoutValidation("Authorization", "Bearer " + Config.ANON);
            using var r = await probe.SendAsync(rq);
            if (!r.IsSuccessStatusCode) return false;
            var bytes = await r.Content.ReadAsByteArrayAsync();
            return bytes.Length > 40000;
        }
        catch { return false; }
    }

    /// <summary>Проверить оба пути и выбрать работающий (не чаще раза в 20 секунд)</summary>
    public static async Task Pick(bool force = false)
    {
        if (!force && (DateTime.UtcNow - lastPick).TotalSeconds < 20) return;
        lastPick = DateTime.UtcNow;
        var a = Ok(Config.SUPABASE); var p = Ok(Config.PROXY);
        await Task.WhenAll(a, p);
        string? nb = p.Result ? Config.PROXY : a.Result ? Config.SUPABASE : null;
        if (nb != null && nb != Base) { Base = nb; Prefs.Set("net_base", nb); }
    }

    /// <summary>Ссылка на файл через выбранный адрес</summary>
    public static string? Px(string? url)
    {
        if (url == null || Base == Config.SUPABASE) return url;
        return url.StartsWith(Config.SUPABASE) ? Base + url[Config.SUPABASE.Length..] : url;
    }
}

/// <summary>Сервер Lumo (Supabase): вход, база (PostgREST), файлы, функции</summary>
public static class Api
{
    public static readonly HttpClient Http = new(new SocketsHttpHandler
    {
        ConnectTimeout = TimeSpan.FromSeconds(20),
        PooledConnectionLifetime = TimeSpan.FromMinutes(5),
        AutomaticDecompression = DecompressionMethods.All,
    }) { Timeout = TimeSpan.FromMinutes(5) };

    public static Session? Session { get; private set; }
    public static event Action<Session?>? SessionChanged;
    static readonly SemaphoreSlim refreshLock = new(1, 1);

    public static void Init()
    {
        var a = Prefs.GetSecret("auth_a"); var r = Prefs.GetSecret("auth_r"); var u = Prefs.Get("auth_u");
        if (a != null && r != null && u != null) Session = new Session(a, r, Prefs.GetLong("auth_e"), u);
    }

    public static string? UserId => Session?.UserId;

    static void SetSession(Session? s)
    {
        Session = s;
        if (s == null) Prefs.Remove("auth_a", "auth_r", "auth_e", "auth_u");
        else { Prefs.SetSecret("auth_a", s.Access); Prefs.SetSecret("auth_r", s.Refresh); Prefs.Set("auth_e", s.ExpiresAt); Prefs.Set("auth_u", s.UserId); }
        SessionChanged?.Invoke(s);
    }

    static void ApplyAuth(JsonNode? j)
    {
        var at = j.Str("access_token"); var rt = j.Str("refresh_token");
        if (at == null || rt == null) throw new ApiError("Не удалось войти", 0);
        var exp = j.Has("expires_at") ? j.Long("expires_at")!.Value : DateTimeOffset.UtcNow.ToUnixTimeSeconds() + (j.Long("expires_in") ?? 3600);
        var uid = j.Get("user").Str("id") ?? Session?.UserId ?? "";
        SetSession(new Session(at, rt, exp, uid));
    }

    public static async Task SignIn(string username, string password)
    {
        var j = await Raw("POST", "/auth/v1/token", Q(("grant_type", "password")),
            J.O(("email", username.Trim().TrimStart('@').ToLowerInvariant() + Config.EMAIL_DOMAIN), ("password", password)), auth: false);
        ApplyAuth(j);
    }

    public static async Task Register(string username, string password, string name)
    {
        await Raw("POST", "/rest/v1/rpc/lm_register", body: J.O(("p_username", username), ("p_password", password), ("p_name", name)), auth: false);
        await SignIn(username, password);
    }

    public static async Task SignOut()
    {
        if (Session != null) try { await Raw("POST", "/auth/v1/logout", Q(("scope", "local")), new JsonObject()); } catch { }
        SetSession(null);
    }

    public static void Forget() => SetSession(null);

    public static async Task<string> Token()
    {
        var s = Session ?? throw new ApiError("Войдите заново", 401);
        var now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        if (s.ExpiresAt - 60 > now) return s.Access;
        await refreshLock.WaitAsync();
        try
        {
            var cur = Session ?? throw new ApiError("Войдите заново", 401);
            if (cur.ExpiresAt - 60 > DateTimeOffset.UtcNow.ToUnixTimeSeconds()) return cur.Access;
            try
            {
                var j = await Raw("POST", "/auth/v1/token", Q(("grant_type", "refresh_token")), J.O(("refresh_token", cur.Refresh)), auth: false);
                ApplyAuth(j);
            }
            catch (ApiError e) when (e.Status is 400 or 401 or 403) { SetSession(null); throw; }
        }
        finally { refreshLock.Release(); }
        return Session?.Access ?? throw new ApiError("Войдите заново", 401);
    }

    public static Dictionary<string, string> Q(params (string, string)[] p) => p.ToDictionary(x => x.Item1, x => x.Item2);

    public static async Task<JsonNode?> Raw(string method, string path, Dictionary<string, string>? query = null, JsonNode? body = null,
        Dictionary<string, string>? headers = null, bool auth = true, byte[]? bytes = null, string? contentType = null, IProgress<double>? progress = null)
    {
        var tk = auth ? await Token() : null;
        HttpRequestMessage Build()
        {
            var sb = new StringBuilder(Net.Base).Append(path);
            if (query != null && query.Count > 0)
                sb.Append('?').Append(string.Join("&", query.Select(kv => Uri.EscapeDataString(kv.Key) + "=" + Uri.EscapeDataString(kv.Value))));
            var rq = new HttpRequestMessage(new HttpMethod(method), sb.ToString());
            rq.Headers.TryAddWithoutValidation("apikey", Config.ANON);
            if (tk != null) rq.Headers.TryAddWithoutValidation("Authorization", "Bearer " + tk);
            if (headers != null) foreach (var kv in headers) rq.Headers.TryAddWithoutValidation(kv.Key, kv.Value);
            if (bytes != null)
            {
                HttpContent c = progress != null ? new ProgressContent(bytes, progress) : new ByteArrayContent(bytes);
                c.Headers.ContentType = MediaTypeHeaderValue.Parse(contentType ?? "application/octet-stream");
                rq.Content = c;
            }
            else if (body != null) rq.Content = new StringContent(body.ToJsonString(), Encoding.UTF8, "application/json");
            else if (method != "GET") rq.Content = new StringContent("", Encoding.UTF8, "application/json");
            return rq;
        }
        HttpResponseMessage resp;
        try { resp = await Http.SendAsync(Build()); }
        catch (Exception e) when (e is HttpRequestException or TaskCanceledException)
        {
            // нет связи — проверяем, какой адрес сервера сейчас работает, и пробуем ещё раз
            var was = Net.Base;
            await Net.Pick(true);
            if (Net.Base == was) throw;
            resp = await Http.SendAsync(Build());
        }
        using (resp)
        {
            var text = await resp.Content.ReadAsStringAsync();
            JsonNode? obj = null;
            if (!string.IsNullOrWhiteSpace(text)) try { obj = JsonNode.Parse(text); } catch { }
            if (!resp.IsSuccessStatusCode)
            {
                var msg = obj.Str("message") ?? obj.Str("msg") ?? obj.Str("error_description") ?? obj.Str("error") ?? $"Ошибка сервера ({(int)resp.StatusCode})";
                if (msg.Contains("Invalid login")) msg = "Неверный юзернейм или пароль";
                throw new ApiError(msg, (int)resp.StatusCode);
            }
            return obj;
        }
    }

    public static Task<JsonNode?> Rpc(string name, JsonObject? p = null) => Raw("POST", "/rest/v1/rpc/" + name, body: p ?? new JsonObject());

    public static async Task<List<JsonObject>> Select(string table, Dictionary<string, string> q) => (await Raw("GET", "/rest/v1/" + table, q)).Objects();

    public static async Task<JsonObject?> Insert(string table, JsonObject row) =>
        (await Raw("POST", "/rest/v1/" + table, body: row, headers: Q(("Prefer", "return=representation")))).Objects().FirstOrDefault();

    public static Task InsertQuiet(string table, JsonObject row) => Raw("POST", "/rest/v1/" + table, body: row, headers: Q(("Prefer", "return=minimal")));

    public static Task Update(string table, Dictionary<string, string> match, JsonObject values) =>
        Raw("PATCH", "/rest/v1/" + table, match.ToDictionary(k => k.Key, k => "eq." + k.Value), values, Q(("Prefer", "return=minimal")));

    public static Task Delete(string table, Dictionary<string, string> match) =>
        Raw("DELETE", "/rest/v1/" + table, match.ToDictionary(k => k.Key, k => "eq." + k.Value), headers: Q(("Prefer", "return=minimal")));

    public static async Task<string> Upload(byte[] data, string ext, string contentType, IProgress<double>? progress = null)
    {
        var uid = UserId ?? throw new ApiError("Войдите заново", 401);
        var path = uid + "/" + Guid.NewGuid().ToString("N")[..8] + "." + ext;
        await Raw("POST", "/storage/v1/object/" + Config.BUCKET + "/" + path, headers: Q(("x-upsert", "false"), ("Cache-Control", "max-age=31536000")),
            bytes: data, contentType: contentType, progress: progress);
        return Config.SUPABASE + "/storage/v1/object/public/" + Config.BUCKET + "/" + path;
    }

    public static Task<JsonNode?> Function(string path, JsonObject? body = null, bool auth = true) =>
        Raw(body == null ? "GET" : "POST", "/functions/v1/lumo" + path, body: body, auth: auth);

    /// <summary>Скачать файл (через выбранный адрес сервера)</summary>
    public static async Task<byte[]> Download(string url) => await Http.GetByteArrayAsync(Net.Px(url) ?? url);
}

/// <summary>Тело запроса, которое сообщает, сколько уже отправлено (0…1)</summary>
class ProgressContent : HttpContent
{
    readonly byte[] data; readonly IProgress<double> cb;
    public ProgressContent(byte[] d, IProgress<double> p) { data = d; cb = p; }
    protected override async Task SerializeToStreamAsync(Stream stream, TransportContext? context)
    {
        const int step = 64 * 1024;
        for (int off = 0; off < data.Length; off += step)
        {
            var n = Math.Min(step, data.Length - off);
            await stream.WriteAsync(data.AsMemory(off, n));
            cb.Report((double)(off + n) / data.Length);
        }
    }
    protected override bool TryComputeLength(out long length) { length = data.Length; return true; }
}
