using System.Text.Json.Nodes;
using Lumo.Core;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.Web.WebView2.Core;

namespace Lumo.UI;

/// <summary>
/// Звонки один на один. Сигналы (ring/accept/offer/answer/ice/…) идут через живое соединение Lumo — канал lm-call-{id},
/// тот же протокол, что на телефонах и в веб-версии. Звук и видео (WebRTC) — во встроенном движке Edge (WebView2),
/// экран звонка — Assets/call.html в оформлении Lumo.
/// </summary>
public sealed class CallHost
{
    public static CallHost? I { get; private set; }
    readonly MainWindow win;
    readonly Grid layer;
    readonly WebView2 web = new() { DefaultBackgroundColor = Microsoft.UI.Colors.Transparent };
    bool ready, failed;
    readonly List<string> pending = new();
    Realtime.Channel? myCh;
    readonly Dictionary<string, Realtime.Channel> outCh = new();
    string? attachedTo;

    public string? State { get; private set; }
    public int Seconds { get; private set; }
    public string PeerName { get; private set; } = "";
    public bool Minimized { get; private set; }
    public event Action? Changed;

    public CallHost(MainWindow w, Grid layer)
    {
        win = w; this.layer = layer; I = this;
        layer.Children.Add(web);
        Collapse();
        _ = Init();
    }

    async Task Init()
    {
        try
        {
            var opts = new CoreWebView2EnvironmentOptions { AdditionalBrowserArguments = "--autoplay-policy=no-user-gesture-required" };
            var env = await CoreWebView2Environment.CreateWithOptionsAsync(null, Path.Combine(Prefs.Dir, "webview"), opts);
            await web.EnsureCoreWebView2Async(env);
            var cw = web.CoreWebView2;
            cw.SetVirtualHostNameToFolderMapping("lumo.app.local", Path.Combine(AppContext.BaseDirectory, "Assets"), CoreWebView2HostResourceAccessKind.Allow);
            cw.PermissionRequested += (_, e) =>
            {
                if (e.PermissionKind is CoreWebView2PermissionKind.Microphone or CoreWebView2PermissionKind.Camera or CoreWebView2PermissionKind.Autoplay)
                    e.State = CoreWebView2PermissionState.Allow;
            };
            cw.Settings.AreDevToolsEnabled = false;
            cw.Settings.AreDefaultContextMenusEnabled = false;
            cw.Settings.IsStatusBarEnabled = false;
            cw.WebMessageReceived += (_, e) => OnMessage(e.WebMessageAsJson);
            web.Source = new Uri("https://lumo.app.local/call.html");
        }
        catch (Exception e)
        {
            failed = true;
            App.Log("call init: " + e.Message);
        }
    }

    /// <summary>Подключить канал входящих звонков после входа</summary>
    public void Attach()
    {
        var id = Store.MyId;
        if (id == null || Store.Demo || attachedTo == id) return;
        attachedTo = id;
        outCh.Clear();
        myCh = Realtime.Get("lm-call-" + id);
        myCh.OnBroadcast = (ev, p) => { if (ev == "sig") Send(new JsonObject { ["op"] = "sig", ["payload"] = p.DeepClone() }); };
        if (ready) _ = SendInit();
    }

    public void Detach() { attachedTo = null; myCh = null; outCh.Clear(); if (State != null) Send(new JsonObject { ["op"] = "hangup" }); }

    async Task SendInit()
    {
        var me = Store.Me;
        if (me == null) { await Store.LoadMe(); me = Store.Me; if (me == null) return; }
        JsonArray? ice = null;
        try { ice = (await Api.Function("/ice")).Arr("iceServers")?.DeepClone() as JsonArray; } catch { }
        var contacts = await Store.ContactIds();
        Send(new JsonObject
        {
            ["op"] = "init",
            ["me"] = J.O(("id", me.Id), ("name", me.Name), ("avatar", Net.Px(me.AvatarUrl)), ("color", me.Color)),
            ["ice"] = ice,
            ["cfg"] = new JsonObject
            {
                ["callsFrom"] = me.Privacy.Str("calls") ?? "all",
                ["contacts"] = J.ToNode(contacts),
                ["online"] = J.ToNode(Store.Online.ToList()),
            },
        });
    }

    void Send(JsonObject m)
    {
        var js = "LC.cmd(" + m.ToJsonString() + ")";
        if (!ready) { pending.Add(js); return; }
        try { _ = web.CoreWebView2?.ExecuteScriptAsync(js); } catch (Exception e) { App.Log("call send: " + e.Message); }
    }

    public void SyncOnline() { if (ready) Send(new JsonObject { ["op"] = "cfg", ["cfg"] = new JsonObject { ["online"] = J.ToNode(Store.Online.ToList()) } }); }

    /// <summary>Позвонить собеседнику личного чата</summary>
    public void Start(ChatItem c, bool video)
    {
        if (failed) { Store.Say("Звонки недоступны: нет компонента Microsoft Edge WebView2"); return; }
        if (c.PeerId == null || c.PeerId == Store.MyId) return;
        if (State != null) { Store.Say("Вы уже в звонке"); Expand(); return; }
        Send(new JsonObject
        {
            ["op"] = "start", ["peer"] = c.PeerId, ["chatId"] = c.Id, ["video"] = video,
            ["name"] = c.DisplayName, ["avatar"] = Net.Px(c.DisplayAvatar), ["color"] = c.DisplayColor,
        });
    }

    async void OnMessage(string json)
    {
        JsonObject? m;
        try { m = JsonNode.Parse(json) as JsonObject; } catch { return; }
        if (m == null) return;
        switch (m.Str("op"))
        {
            case "ready":
                ready = true;
                foreach (var js in pending) try { _ = web.CoreWebView2.ExecuteScriptAsync(js); } catch { }
                pending.Clear();
                if (attachedTo != null) await SendInit();
                break;
            case "sig":
            {
                var to = m.Str("to"); var payload = m.Obj("payload").DeepClone() as JsonObject;
                if (to == null || payload == null || attachedTo == null) return;
                var ch = to == attachedTo ? myCh : outCh.TryGetValue(to, out var c) ? c : outCh[to] = Realtime.Get("lm-call-" + to);
                if (ch == null) return;
                for (int i = 0; i < 60 && !ch.Joined; i++) await Task.Delay(100);
                Realtime.Broadcast(ch, "sig", payload);
                break;
            }
            case "sec":
            {
                var peer = m.Str("peer"); string? cid = null;
                var chat = Store.Chats.FirstOrDefault(x => x.IsPrivate && x.PeerId == peer);
                if (chat != null) { await E2E.Prepare(chat.Id, peer); if (E2E.Active(chat.Id)) cid = chat.Id; }
                Reply(m, cid);
                break;
            }
            case "enc": Reply(m, E2E.Encrypt(m.Str("cid") ?? "", m.Str("text") ?? "")); break;
            case "dec": Reply(m, E2E.Decrypt(m.Str("cid") ?? "", m.Str("text") ?? "")); break;
            case "toast": Store.Say(m.Str("text") ?? ""); break;
            case "pingTg":
                try { await Api.Function("/call", J.O(("peer_id", m.Str("peer")), ("video", m.Bool("video")))); } catch { }
                break;
            case "show":
                Expand();
                if (m.Bool("incoming"))
                {
                    var name = m.Str("name") ?? "Lumo";
                    if (!Store.WindowActive) Notifications.Show("call", name, m.Bool("video") ? "Входящий видеозвонок" : "Входящий звонок");
                    win.BringToFront();
                }
                break;
            case "hide": State = null; Minimized = false; Collapse(); Changed?.Invoke(); break;
            case "minimize": if (State != null) { Minimized = true; Collapse(); Changed?.Invoke(); } break;
            case "state":
                State = m.Str("st"); Seconds = m.Int("t") ?? 0; PeerName = m.Str("name") ?? "";
                Changed?.Invoke();
                break;
            case "ended":
            {
                var chatId = m.Str("chatId");
                if (m.Bool("wasCaller") && chatId != null)
                    _ = Store.Send(chatId, "call", null, meta: J.O(("status", m.Str("status") ?? "ended"), ("duration", m.Int("dur") ?? 0), ("video", m.Bool("video"))));
                break;
            }
        }
    }

    void Reply(JsonObject m, string? value) => Send(new JsonObject { ["op"] = "res", ["id"] = m.Int("id") ?? 0, ["value"] = value });

    public void Expand()
    {
        Minimized = false;
        layer.Visibility = Visibility.Visible;
        layer.IsHitTestVisible = true;
        web.Width = double.NaN; web.Height = double.NaN;
        web.HorizontalAlignment = HorizontalAlignment.Stretch; web.VerticalAlignment = VerticalAlignment.Stretch;
        web.Opacity = 1;
        Changed?.Invoke();
    }

    /// <summary>Свернуть: движок звонка продолжает работать (точка 1×1), поверх чатов — плашка «Вернуться к звонку»</summary>
    void Collapse()
    {
        layer.IsHitTestVisible = false;
        web.Width = 1; web.Height = 1;
        web.HorizontalAlignment = HorizontalAlignment.Left; web.VerticalAlignment = VerticalAlignment.Top;
        web.Opacity = 0.01;
    }

    /// <summary>Снимок экрана звонка (для демо-проверки)</summary>
    public async Task Snapshot(string path)
    {
        try
        {
            using var fs = File.Create(path);
            await web.CoreWebView2.CapturePreviewAsync(CoreWebView2CapturePreviewImageFormat.Png, fs.AsRandomAccessStream());
        }
        catch (Exception e) { App.Log("call shot: " + e.Message); }
    }

    /// <summary>Для демо: изобразить входящий звонок</summary>
    public void DemoRing() => Send(new JsonObject
    {
        ["op"] = "sig",
        ["payload"] = J.O(("t", "ring"), ("from", "u1"), ("callId", "demo1"), ("video", false), ("name", "Анна Смирнова"), ("color", 5), ("chatId", "c1")),
    });
}
