using System.Text.Json.Nodes;
using Lumo.Core;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.Web.WebView2.Core;

namespace Lumo.UI;

/// <summary>Общее окружение встроенного Edge (WebView2) для звонков, игр и мини-приложений</summary>
public static class WebEnv
{
    static Task<CoreWebView2Environment>? env;
    public static readonly string WebDir = Path.Combine(Prefs.Dir, "web");
    public static Task<CoreWebView2Environment> Get() => env ??= CoreWebView2Environment.CreateWithOptionsAsync(null, Path.Combine(Prefs.Dir, "webview"),
        new CoreWebView2EnvironmentOptions { AdditionalBrowserArguments = "--autoplay-policy=no-user-gesture-required" }).AsTask();

    public static async Task Setup(WebView2 web)
    {
        await web.EnsureCoreWebView2Async(await Get());
        var cw = web.CoreWebView2;
        Directory.CreateDirectory(WebDir);
        cw.SetVirtualHostNameToFolderMapping("lumo.app.local", Path.Combine(AppContext.BaseDirectory, "Assets"), CoreWebView2HostResourceAccessKind.Allow);
        cw.SetVirtualHostNameToFolderMapping("lumo.web.local", WebDir, CoreWebView2HostResourceAccessKind.Allow);
        cw.PermissionRequested += (_, e) =>
        {
            if (e.PermissionKind is CoreWebView2PermissionKind.Microphone or CoreWebView2PermissionKind.Camera or CoreWebView2PermissionKind.Autoplay or CoreWebView2PermissionKind.ClipboardRead)
                e.State = CoreWebView2PermissionState.Allow;
        };
        cw.Settings.AreDevToolsEnabled = false;
        cw.Settings.IsStatusBarEnabled = false;
        // ссылки «открыть в новом окне» — в обычном браузере
        cw.NewWindowRequested += (_, e) =>
        {
            e.Handled = true;
            try { System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo(e.Uri) { UseShellExecute = true }); } catch { }
        };
    }
}

/// <summary>
/// Игра вдвоём или мини-приложение бота поверх чатов. Игру можно свернуть в плашку внизу — страница продолжает жить.
/// Игры — та же страница games.html, что в приложениях для телефона.
/// </summary>
public sealed class WebOverlay
{
    public static WebOverlay? I { get; private set; }
    readonly MainWindow win;
    readonly Grid layer;
    readonly Grid panel = new() { Background = T.Bg };
    readonly Grid header = new() { Background = T.Panel, Padding = new Thickness(8, 6, 8, 6), ColumnSpacing = 6 };
    readonly TextBlock title = T.Txt("", 16, bold: true, lines: 1);
    readonly Button back;
    WebView2? web;
    public string? Mode { get; private set; }   // "game" | "mini"
    public bool Minimized { get; private set; }
    public string BarTitle { get; private set; } = "Игра";
    public string BarStatus { get; private set; } = "";
    public event Action? Changed;
    string? botId;
    bool miniBack;

    public WebOverlay(MainWindow w, Grid layer)
    {
        win = w; this.layer = layer; I = this;
        panel.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        panel.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
        header.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        header.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        header.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        back = T.IconButton("\uE711", "Закрыть", OnBack, 36, 14);
        header.Children.Add(back);
        title.VerticalAlignment = VerticalAlignment.Center;
        Grid.SetColumn(title, 1); header.Children.Add(title);
        var min = T.IconButton("\uE921", "Свернуть", Minimize, 36, 14);
        Grid.SetColumn(min, 2); header.Children.Add(min);
        panel.Children.Add(header);
        layer.Children.Add(panel);
        layer.Visibility = Visibility.Collapsed;
    }

    async Task<WebView2?> Fresh()
    {
        Close(false);
        var wv = new WebView2 { DefaultBackgroundColor = T.C(0xFF0C0D1A) };
        Grid.SetRow(wv, 1);
        panel.Children.Add(wv);
        try { await WebEnv.Setup(wv); }
        catch (Exception e) { App.Log("web: " + e.Message); Store.Say("Нужен компонент Microsoft Edge WebView2"); panel.Children.Remove(wv); return null; }
        wv.CoreWebView2.WebMessageReceived += (_, e) => OnMessage(e.WebMessageAsJson);
        web = wv;
        return wv;
    }

    // ---------- игры ----------

    public async void OpenGame(string gameId)
    {
        if (Mode == "game" && web != null && openGame == gameId) { Expand(); return; }
        string token;
        try { token = await Api.Token(); } catch { Store.Say("Войдите заново"); return; }
        var wv = await Fresh(); if (wv == null) return;
        Mode = "game"; openGame = gameId; BarTitle = "Игра"; BarStatus = "";
        header.Visibility = Visibility.Collapsed;
        var cfg = new JsonObject
        {
            ["api"] = Net.Base + "/functions/v1/lumo-games", ["apikey"] = Config.ANON, ["token"] = token,
            ["gameId"] = gameId, ["theme"] = "dark", ["mini"] = true,
        };
        var html = await GamesHtml();
        File.WriteAllText(Path.Combine(WebEnv.WebDir, "game.html"), html.Replace("/*CFG*/", "window.LUMO_GAME=" + cfg.ToJsonString() + ";"));
        await wv.CoreWebView2.AddScriptToExecuteOnDocumentCreatedAsync(
            "window.LumoBridge={post:function(m){chrome.webview.postMessage({op:'game',m:String(m)})},leave:function(){chrome.webview.postMessage({op:'leave'})}};");
        wv.Source = new Uri("https://lumo.web.local/game.html?t=" + DateTime.UtcNow.Ticks);
        Expand();
    }
    string? openGame;

    /// <summary>Страница игр: свежая с сервера (как в приложениях), иначе встроенная</summary>
    static async Task<string> GamesHtml()
    {
        var cache = Path.Combine(WebEnv.WebDir, "games-src.html");
        try
        {
            var o = await Api.Rpc("lm_games_html");
            var h = o.Str("html");
            if (h != null && h.Contains("/*CFG*/")) { File.WriteAllText(cache, h); return h; }
        }
        catch { }
        if (File.Exists(cache)) return File.ReadAllText(cache);
        return File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "Assets", "games.html"));
    }

    /// <summary>Вызов сервера игр (создать приглашение и т.п.)</summary>
    public static async Task<JsonObject> GamesCall(JsonObject body)
    {
        var r = await Api.Raw("POST", "/functions/v1/lumo-games", body: body) as JsonObject ?? new JsonObject();
        if (r.Has("error")) throw new Exception(r.Str("error"));
        return r;
    }

    // ---------- мини-приложения ботов ----------

    public async void OpenMini(string bot, string? url)
    {
        botId = bot; miniBack = false;
        JsonObject? r;
        try
        {
            var theme = J.O(("bg_color", "#0c0d1a"), ("text_color", "#eef0ff"), ("hint_color", "#8d90b8"), ("link_color", "#7c5cff"),
                ("button_color", "#7c5cff"), ("button_text_color", "#ffffff"), ("secondary_bg_color", "#13142a"));
            var body = J.O(("bot_id", bot), ("theme", theme), ("scheme", "dark"), ("platform", "windows"));
            if (url != null) body["url"] = url;
            r = await Api.Raw("POST", "/functions/v1/lumo-bots/webapp/init", body: body) as JsonObject;
        }
        catch (Exception e) { Store.Say(e.Message); return; }
        if (r == null || !r.Bool("ok")) { Store.Say(r?.Str("error") ?? "Не удалось открыть"); return; }
        var wv = await Fresh(); if (wv == null) return;
        Mode = "mini";
        title.Text = r.Str("title") ?? Store.Profiles.GetValueOrDefault(bot)?.Name ?? "Мини-приложение";
        header.Visibility = Visibility.Visible;
        back.Content = T.Icon("\uE711", 14, T.Muted);
        var pre = "window.__lumoPost=function(e,d){chrome.webview.postMessage({op:'mini',e:String(e),d:JSON.stringify(d||{})})};";
        var bridge = r.Str("bridge") ?? "";
        var html = r.Str("html");
        if (html != null)
        {
            var inject = "<script>" + pre + bridge.Replace("</script", "<\\/script") + "</script>";
            var i = html.IndexOf("<head>", StringComparison.OrdinalIgnoreCase);
            var doc = i >= 0 ? html[..(i + 6)] + inject + html[(i + 6)..] : inject + html;
            File.WriteAllText(Path.Combine(WebEnv.WebDir, "mini.html"), doc);
            wv.Source = new Uri("https://lumo.web.local/mini.html?t=" + DateTime.UtcNow.Ticks);
        }
        else
        {
            await wv.CoreWebView2.AddScriptToExecuteOnDocumentCreatedAsync(pre + bridge);
            wv.Source = new Uri(r.Str("url") ?? "about:blank");
        }
        Expand();
    }

    async void OnMessage(string json)
    {
        JsonObject? m;
        try { m = JsonNode.Parse(json) as JsonObject; } catch { return; }
        switch (m.Str("op"))
        {
            case "leave": Close(); break;
            case "game":
            {
                var s = m.Str("m") ?? "";
                if (s == "minimize") Minimize();
                else if (s.StartsWith("info|")) { var q = s.Split('|'); if (q.Length >= 3) { BarTitle = q[1]; BarStatus = q[2]; Changed?.Invoke(); } }
                break;
            }
            case "mini":
            {
                var ev = m.Str("e"); JsonObject d;
                try { d = JsonNode.Parse(m.Str("d") ?? "{}") as JsonObject ?? new(); } catch { d = new(); }
                switch (ev)
                {
                    case "close": Close(); break;
                    case "sendData":
                        try { await Api.Raw("POST", "/functions/v1/lumo-bots/webapp/data", body: J.O(("bot_id", botId), ("data", d.Str("data") ?? ""))); } catch { }
                        Close();
                        break;
                    case "openLink":
                        var u = d.Str("url");
                        if (u != null) try { System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo(u) { UseShellExecute = true }); } catch { }
                        break;
                    case "copy":
                        var dp = new Windows.ApplicationModel.DataTransfer.DataPackage(); dp.SetText(d.Str("text") ?? "");
                        Windows.ApplicationModel.DataTransfer.Clipboard.SetContent(dp);
                        break;
                    case "backButton":
                        miniBack = d.Bool("visible");
                        back.Content = T.Icon(miniBack ? "\uE72B" : "\uE711", 14, T.Muted);
                        break;
                }
                break;
            }
        }
    }

    void OnBack()
    {
        if (Mode == "mini" && miniBack) { _ = web?.CoreWebView2?.ExecuteScriptAsync("window.__lumoBack&&window.__lumoBack()"); return; }
        Close();
    }

    public void Expand()
    {
        if (web == null) return;
        Minimized = false;
        layer.Visibility = Visibility.Visible;
        layer.IsHitTestVisible = true;
        panel.Opacity = 1;
        web.Width = double.NaN; web.Height = double.NaN;
        Changed?.Invoke();
    }

    public void Minimize()
    {
        if (web == null) return;
        Minimized = true;
        // страница продолжает работать (1×1), сверху — плашка «вернуться к игре»
        layer.IsHitTestVisible = false;
        panel.Opacity = 0.01;
        web.Width = 1; web.Height = 1;
        Changed?.Invoke();
    }

    public void Close(bool notify = true)
    {
        if (web != null) { try { panel.Children.Remove(web); web.Close(); } catch { } }
        web = null; Mode = null; openGame = null; Minimized = false;
        layer.Visibility = Visibility.Collapsed;
        if (notify) Changed?.Invoke();
    }
}
