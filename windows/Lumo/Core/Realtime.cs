using System.Net.WebSockets;
using System.Text;
using System.Text.Json.Nodes;

namespace Lumo.Core;

/// <summary>Живое соединение с сервером (Supabase Realtime, протокол Phoenix). Все события — на главном потоке (через Post).</summary>
public static class Realtime
{
    public class Channel
    {
        public string Topic = ""; public JsonArray Changes = new(); public string PresenceKey = "";
        public string JoinRef = ""; public bool Joined; public JsonObject? TrackPayload;
        public Action<string, JsonObject>? OnBroadcast;
        public Action<JsonObject>? OnChange;
        public Action<JsonObject>? OnPresenceState;
        public Action<JsonObject, JsonObject>? OnPresenceDiff;
    }

    /// <summary>Выполнить на главном потоке</summary>
    public static Action<Action> Post = a => a();

    static ClientWebSocket? ws;
    static int refNo;
    static readonly Dictionary<string, Channel> channels = new();
    static CancellationTokenSource? cts;
    static double backoff = 1;
    static bool wanted;
    public static bool IsOpen { get; private set; }
    public static Action? OnReconnect;
    public static Action<bool>? OnState;
    static readonly SemaphoreSlim sendLock = new(1, 1);

    static string NextRef() => (++refNo).ToString();

    public static void Connect()
    {
        wanted = true;
        if (ws != null) return;
        var s = new ClientWebSocket();
        s.Options.KeepAliveInterval = TimeSpan.FromSeconds(20);
        ws = s;
        var c = new CancellationTokenSource(); cts = c;
        _ = Task.Run(async () =>
        {
            try
            {
                await s.ConnectAsync(new Uri(Config.RealtimeUrl), c.Token);
                Post(() => Opened(s));
                var buf = new byte[64 * 1024];
                var sb = new MemoryStream();
                while (s.State == WebSocketState.Open && !c.IsCancellationRequested)
                {
                    var r = await s.ReceiveAsync(buf, c.Token);
                    if (r.MessageType == WebSocketMessageType.Close) break;
                    sb.Write(buf, 0, r.Count);
                    if (!r.EndOfMessage) continue;
                    var text = Encoding.UTF8.GetString(sb.ToArray());
                    sb.SetLength(0);
                    Post(() => { if (s == ws) { try { Handle(JsonNode.Parse(text) as JsonObject); } catch { } } });
                }
            }
            catch { }
            Post(() => { if (s == ws) Dropped(); });
        });
    }

    public static void Disconnect()
    {
        wanted = false;
        cts?.Cancel();
        try { ws?.Abort(); } catch { }
        ws = null; IsOpen = false;
        channels.Clear();
    }

    public static void Ensure() { if (wanted && ws == null) Connect(); }

    static CancellationTokenSource? hb;

    static void Opened(ClientWebSocket s)
    {
        if (s != ws) return;
        IsOpen = true; backoff = 1;
        hb?.Cancel(); var h = new CancellationTokenSource(); hb = h;
        _ = Task.Run(async () =>
        {
            while (!h.IsCancellationRequested)
            {
                try { await Task.Delay(25000, h.Token); } catch { return; }
                Post(() => Push("phoenix", "heartbeat", new JsonObject()));
            }
        });
        foreach (var c in channels.Values) Join(c);
        OnState?.Invoke(true);
        OnReconnect?.Invoke();
    }

    static void Dropped()
    {
        hb?.Cancel();
        try { ws?.Abort(); } catch { }
        ws = null; IsOpen = false;
        foreach (var c in channels.Values) c.Joined = false;
        if (!wanted) return;
        OnState?.Invoke(false);
        var d = backoff; backoff = Math.Min(backoff * 2, 20);
        _ = Task.Run(async () =>
        {
            try { await Net.Pick(); } catch { }
            await Task.Delay(TimeSpan.FromSeconds(d));
            Post(() => { if (wanted) Connect(); });
        });
    }

    static void Push(string topic, string ev, JsonObject payload, string? joinRef = null, string? r = null)
    {
        var s = ws; if (s == null || !IsOpen) return;
        var m = new JsonObject { ["topic"] = topic, ["event"] = ev, ["payload"] = payload, ["ref"] = r ?? NextRef() };
        if (joinRef != null) m["join_ref"] = joinRef;
        var bytes = Encoding.UTF8.GetBytes(m.ToJsonString());
        _ = Task.Run(async () =>
        {
            await sendLock.WaitAsync();
            try { if (s.State == WebSocketState.Open) await s.SendAsync(bytes, WebSocketMessageType.Text, true, CancellationToken.None); }
            catch { }
            finally { sendLock.Release(); }
        });
    }

    public static Channel Get(string name, JsonArray? changes = null, string presenceKey = "")
    {
        var topic = "realtime:" + name;
        if (channels.TryGetValue(topic, out var ex)) return ex;
        var c = new Channel { Topic = topic, Changes = changes ?? new JsonArray(), PresenceKey = presenceKey };
        channels[topic] = c;
        if (IsOpen) Join(c); else Connect();
        return c;
    }

    public static void Leave(string name)
    {
        var topic = "realtime:" + name;
        if (!channels.Remove(topic, out var c)) return;
        if (c.Joined) Push(topic, "phx_leave", new JsonObject(), c.JoinRef);
    }

    static async void Join(Channel c)
    {
        string? token = null;
        try { token = await Api.Token(); } catch { }
        if (!channels.TryGetValue(c.Topic, out var cur) || cur != c || !IsOpen) return;
        c.JoinRef = NextRef();
        var cfg = new JsonObject
        {
            ["broadcast"] = new JsonObject { ["self"] = false, ["ack"] = false },
            ["presence"] = new JsonObject { ["key"] = c.PresenceKey },
            ["postgres_changes"] = c.Changes.DeepClone(),
            ["private"] = false,
        };
        var p = new JsonObject { ["config"] = cfg };
        if (token != null) p["access_token"] = token;
        Push(c.Topic, "phx_join", p, c.JoinRef, c.JoinRef);
    }

    public static void Broadcast(Channel c, string ev, JsonObject payload) =>
        Push(c.Topic, "broadcast", new JsonObject { ["type"] = "broadcast", ["event"] = ev, ["payload"] = payload }, c.JoinRef);

    public static void Track(Channel c, JsonObject payload)
    {
        c.TrackPayload = payload;
        if (c.Joined) Push(c.Topic, "presence", new JsonObject { ["type"] = "presence", ["event"] = "track", ["payload"] = payload.DeepClone() }, c.JoinRef);
    }

    public static void UpdateToken(string token)
    {
        foreach (var c in channels.Values.Where(x => x.Joined)) Push(c.Topic, "access_token", new JsonObject { ["access_token"] = token }, c.JoinRef);
    }

    static void Handle(JsonObject? j)
    {
        if (j == null) return;
        var topic = j.Str("topic") ?? ""; var ev = j.Str("event") ?? "";
        var payload = j.Obj("payload");
        if (!channels.TryGetValue(topic, out var c)) return;
        switch (ev)
        {
            case "phx_reply":
                if (j.Str("ref") != c.JoinRef) return;
                if (payload.Str("status") == "ok")
                {
                    c.Joined = true;
                    if (c.TrackPayload != null) Track(c, c.TrackPayload);
                }
                else RetryJoin(c, 3000);
                break;
            case "broadcast": c.OnBroadcast?.Invoke(payload.Str("event") ?? "", payload.Obj("payload")); break;
            case "postgres_changes": c.OnChange?.Invoke(payload.Obj("data")); break;
            case "presence_state": c.OnPresenceState?.Invoke(payload); break;
            case "presence_diff": c.OnPresenceDiff?.Invoke(payload.Obj("joins"), payload.Obj("leaves")); break;
            case "phx_error": case "phx_close": c.Joined = false; RetryJoin(c, 2000); break;
        }
    }

    static void RetryJoin(Channel c, int ms)
    {
        _ = Task.Run(async () =>
        {
            await Task.Delay(ms);
            Post(() => { if (channels.TryGetValue(c.Topic, out var cur) && cur == c && IsOpen && !c.Joined) Join(c); });
        });
    }
}
