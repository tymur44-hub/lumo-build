using System.Text.Json.Nodes;
using Lumo.Core;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace Lumo.UI;

public record RemoteWall(int Id, string Url, bool Premium, string? Section);

/// <summary>Оформление: обои чата (номера те же, что в мобильной версии)</summary>
public static class Look
{
    public static int Wall => (int)Prefs.GetLong("chat_wall", 0);
    public static string? WallUrl => Prefs.Get("chat_wall_url");
    public static event Action? Changed;

    public static void SetWall(int n, string? url)
    {
        Prefs.Set("chat_wall", (long)n);
        if (url != null) Prefs.Set("chat_wall_url", url); else Prefs.Remove("chat_wall_url");
        Changed?.Invoke();
    }

    public static bool IsPremium(int i) => (i >= 6 && i <= 9) || (i >= 20 && i <= 27) || (i >= 33 && i <= 35);

    /// <summary>Обои с сервера (lm_get_config → look.walls), номер 1000+n</summary>
    public static async Task<List<RemoteWall>> Remote()
    {
        try
        {
            var o = await Api.Rpc("lm_get_config");
            var arr = o.Get("look").Arr("walls") ?? new JsonArray();
            return arr.OfType<JsonObject>().Where(j => j.Int("n") != null && j.Str("url") != null)
                .Select(j => new RemoteWall(1000 + j.Int("n")!.Value, j.Str("url")!, j.Bool("premium"), j.Str("section") is { Length: > 0 } s ? s : null)).ToList();
        }
        catch { return new(); }
    }
}

/// <summary>Раздел «Оформление» — живая страница со всеми обоями</summary>
public sealed class LookWeb : Grid, IFillPage
{
    readonly WebView2 web = new() { DefaultBackgroundColor = Windows.UI.Color.FromArgb(255, 0x0E, 0x0F, 0x22) };
    bool ready;
    List<RemoteWall> remote = new();

    public LookWeb()
    {
        Background = T.ChatBg;
        RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
        if (Vice.Available)
        {
            // временная тема: переключатель над страницей оформления
            var row = new Grid { Margin = new Thickness(16, 12, 16, 4), Padding = new Thickness(14, 10, 10, 10), CornerRadius = new CornerRadius(14), Background = T.Panel2 };
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            var ic = new Border { Width = 32, Height = 32, CornerRadius = new CornerRadius(9), Background = Vice.OutBrush, Child = T.Icon("\uE706", 16, T.White) };
            row.Children.Add(ic);
            var tx = new StackPanel { Margin = new Thickness(12, 0, 0, 0), VerticalAlignment = VerticalAlignment.Center };
            tx.Children.Add(T.Txt("Vice Nights", 15, bold: true));
            tx.Children.Add(T.Txt("Закат, неон и пальмы — до 1 декабря", 12.5, T.Muted));
            Grid.SetColumn(tx, 1); row.Children.Add(tx);
            var sw = new ToggleSwitch { IsOn = !Vice.Off, OnContent = "", OffContent = "", MinWidth = 0, VerticalAlignment = VerticalAlignment.Center };
            sw.Toggled += (_, _) => Vice.SetOff(!sw.IsOn);
            Grid.SetColumn(sw, 2); row.Children.Add(sw);
            Children.Add(row);
        }
        Grid.SetRow(web, 1);
        Children.Add(web);
        Loaded += async (_, _) => { if (!ready) await Init(); };
    }

    async Task Init()
    {
        ready = true;
        try
        {
            await WebEnv.Setup(web);
            var cw = web.CoreWebView2;
            cw.WebMessageReceived += async (_, e) => await OnMsg(e.TryGetWebMessageAsString());
            cw.NavigationCompleted += async (_, _) =>
            {
                remote = await Look.Remote();
                var arr = new JsonArray();
                foreach (var w in remote) arr.Add(new JsonObject { ["id"] = w.Id, ["url"] = Net.Px(w.Url), ["premium"] = w.Premium, ["section"] = w.Section });
                var d = new JsonObject { ["cur"] = Look.Wall, ["remote"] = arr, ["premium"] = Store.Me?.Premium == true };
                await cw.ExecuteScriptAsync("setData(" + d.ToJsonString() + ")");
                if (Environment.GetEnvironmentVariable("LUMO_DEMO") == "1")
                {
                    await Task.Delay(1500);
                    try { var dir = Path.Combine(Prefs.Dir, "shots"); Directory.CreateDirectory(dir); using var fs = File.Create(Path.Combine(dir, "web-look.png")); await cw.CapturePreviewAsync(Microsoft.Web.WebView2.Core.CoreWebView2CapturePreviewImageFormat.Png, fs.AsRandomAccessStream()); } catch { }
                }
            };
            cw.Navigate("https://lumo.app.local/look.html");
        }
        catch (Exception e) { App.Log("look web: " + e); Children.Add(T.Txt("Не удалось открыть оформление: " + e.Message, 13, T.Danger)); }
    }

    async Task OnMsg(string? raw)
    {
        if (raw == null) return;
        JsonNode? m; try { m = JsonNode.Parse(raw); } catch { return; }
        if (m.Str("t") != "wall") return;
        var n = m.Int("n") ?? 0;
        if (m.Bool("premium") && Store.Me?.Premium != true)
        {
            Plaque.Show("", "Lumo Premium", "Эти обои доступны с подпиской Premium — оформите её в Настройках, раздел «Люмены и Premium», оплата картой прямо в Lumo.");
            return;
        }
        Look.SetWall(n, n >= 1000 ? remote.FirstOrDefault(x => x.Id == n)?.Url : null);
        await web.CoreWebView2.ExecuteScriptAsync("select(" + n + ")");
    }
}

/// <summary>Обои под перепиской: рисуются тем же кодом, что в «Оформлении» (живые — анимированы)</summary>
public sealed class WallLayer : Grid
{
    WebView2? web;
    int shown = -1;

    UIElement? vice;

    public WallLayer()
    {
        IsHitTestVisible = false;
        Action again = () => { shown = -1; Apply(); };
        Loaded += (_, _) => { Look.Changed += Apply; Vice.Changed += again; Apply(); };
        Unloaded += (_, _) => { Look.Changed -= Apply; Vice.Changed -= again; Drop(); };
    }

    void Drop() { if (web != null) { Children.Remove(web); try { web.Close(); } catch { } web = null; } shown = -1; }

    async void Apply()
    {
        var n = Look.Wall;
        if (n == shown) return;
        if (n == 0 || (Look.IsPremium(n) && Store.Me?.Premium != true))
        {
            Drop(); shown = n;
            // временная тема вместо стандартного фона (свои обои не трогаем)
            if (vice != null) { Children.Remove(vice); vice = null; }
            if (Vice.On) { vice = Vice.NightWall(); Children.Insert(0, vice); }
            return;
        }
        if (vice != null) { Children.Remove(vice); vice = null; }
        shown = n;
        try
        {
            if (web == null)
            {
                web = new WebView2 { DefaultBackgroundColor = Windows.UI.Color.FromArgb(255, 0x0E, 0x0F, 0x22), IsHitTestVisible = false, Opacity = 0 };
                Children.Add(web);
                await WebEnv.Setup(web);
                web.CoreWebView2.NavigationCompleted += (_, _) => Music.Fade(web!, true);
            }
            var url = n >= 1000 && Look.WallUrl is string u ? "&url=" + Uri.EscapeDataString(Net.Px(u)!) : "";
            web.CoreWebView2.Navigate("https://lumo.app.local/wallbg.html#n=" + n + url + "&r=" + Environment.TickCount);
        }
        catch (Exception e) { App.Log("wall: " + e.Message); }
    }
}
