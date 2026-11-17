using System.Text.Json.Nodes;
using Lumo.Core;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace Lumo.UI;

/// <summary>
/// Оплата внутри Lumo: окно поверх приложения без адресной строки и кнопок браузера — только крестик.
/// После оплаты ЮMoney возвращает на lumomess.ru/?lumo_paid=1 — окно закрывается само,
/// а статус заказа проверяется, пока люмены или Premium не будут зачислены.
/// </summary>
public static class Pay
{
    public const string Return = "https://lumomess.ru/?lumo_paid=1";
    public const double Rate = 1.7;
    /// <summary>Оплата прошла — экраны обновляют баланс и историю</summary>
    public static event Action? Paid;
    static readonly HashSet<string> watching = new();

    public static string Rub(double v)
    {
        var ci = new System.Globalization.CultureInfo("ru-RU");
        return (Math.Abs(v - Math.Round(v)) < 0.001 ? v.ToString("N0", ci) : v.ToString("N2", ci)) + " ₽";
    }

    /// <summary>Создаёт заказ (люмены или Premium) и открывает окно оплаты</summary>
    public static async Task Create(string kind, int qty, string? to = null)
    {
        try
        {
            var b = new JsonObject { ["action"] = "create", ["kind"] = kind, ["qty"] = qty, ["return_url"] = Return };
            if (to != null) b["to"] = to;
            var r = await Api.Raw("POST", "/functions/v1/lumo-yoomoney", body: b);
            var u = r.Str("url");
            if (u == null || !u.StartsWith("https://")) { Store.Say(r.Str("error") ?? "Не удалось создать платёж"); return; }
            Open(u, r.Str("order_id"), to);
        }
        catch (Exception e) { Store.Say(string.IsNullOrWhiteSpace(e.Message) ? "Не удалось создать платёж" : e.Message); }
    }

    public static string? OrderFrom(string url)
    {
        try { var q = System.Web.HttpUtility.ParseQueryString(new Uri(url).Query); return q["label"]; } catch { return null; }
    }

    public static void Open(string url, string? order, string? to = null)
    {
        Sheet? sheet = null;
        var page = new PayPage(url, paid => { sheet?.Hide(); if (paid) Store.Say("Платёж принят. Зачисляем…"); }) { Height = 640 };
        sheet = new Sheet { Title = "Оплата", Content = page, Width = 540 };
        _ = sheet.ShowAsync();
        if (order != null) _ = Watch(order, to);
    }

    static async Task Watch(string order, string? to)
    {
        if (!watching.Add(order)) return;
        try
        {
            for (int i = 0; i < 400; i++)
            {
                await Task.Delay(3000);
                JsonNode? j;
                try { j = await Api.Rpc("lm_pay_status", new JsonObject { ["p_order"] = order }); } catch { continue; }
                var st = j.Str("status");
                if (st == "paid")
                {
                    var q = j.Int("qty") ?? 0;
                    if (j.Str("kind") == "prem") { try { await Store.LoadMe(); } catch { } Store.Say(to == null ? "Оплата прошла. Lumo Premium активирован" : "Оплата прошла. Premium подарен"); }
                    else Store.Say("Оплата прошла. Начислено " + q + " " + Fmt.Plural(q, "люмен", "люмена", "люменов"));
                    Paid?.Invoke();
                    return;
                }
                if (st == "unknown") return;
            }
        }
        finally { watching.Remove(order); }
    }
}

/// <summary>Страница оплаты ЮMoney во встроенном веб-движке</summary>
public sealed class PayPage : Grid
{
    readonly WebView2 web = new();
    readonly ProgressBar bar = new() { IsIndeterminate = true, Height = 3, VerticalAlignment = VerticalAlignment.Top };
    readonly StackPanel wait = new() { Spacing = 10, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
    readonly Action<bool> close;
    bool done;

    public PayPage(string url, Action<bool> close)
    {
        this.close = close;
        Background = T.Panel;
        CornerRadius = new CornerRadius(14);
        var note = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 6, HorizontalAlignment = HorizontalAlignment.Center };
        RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
        note.Children.Add(T.Icon("", 11, T.Muted));
        note.Children.Add(T.Txt("Банковская карта · ЮMoney · защищённое соединение", 12, T.Muted));
        note.Margin = new Thickness(0, 0, 0, 8);
        Children.Add(note);
        var host = new Grid { CornerRadius = new CornerRadius(14) };
        host.Children.Add(web);
        wait.Children.Add(new ProgressRing { IsActive = true, Width = 32, Height = 32 });
        wait.Children.Add(T.Txt("Открываем оплату…", 13.5, T.Muted));
        host.Children.Add(wait);
        host.Children.Add(bar);
        Grid.SetRow(host, 1); Children.Add(host);
        Loaded += async (_, _) => await Init(url);
        Unloaded += (_, _) => { try { web.Close(); } catch { } };
    }

    async Task Init(string url)
    {
        try
        {
            await web.EnsureCoreWebView2Async(await WebEnv.Get());
            var cw = web.CoreWebView2;
            cw.Settings.AreDefaultContextMenusEnabled = false;
            cw.Settings.AreDevToolsEnabled = false;
            cw.NavigationStarting += (_, e) =>
            {
                bar.Visibility = Visibility.Visible;
                if (Uri.TryCreate(e.Uri, UriKind.Absolute, out var u))
                {
                    // вернулись после оплаты — закрываем окно
                    if (u.Host.EndsWith("lumomess.ru") && e.Uri.Contains("lumo_paid")) { e.Cancel = true; Finish(true); return; }
                    if (u.Scheme is not ("http" or "https" or "about" or "data")) { e.Cancel = true; Browser.Shell(e.Uri); }
                }
            };
            cw.NavigationCompleted += (_, _) => { bar.Visibility = Visibility.Collapsed; wait.Visibility = Visibility.Collapsed; };
            cw.NewWindowRequested += (_, e) => { e.Handled = true; cw.Navigate(e.Uri); };
            cw.Navigate(url);
        }
        catch (Exception e) { App.Log("pay: " + e); wait.Children.Clear(); wait.Children.Add(T.Txt("Не удалось открыть оплату: " + e.Message, 13, T.Danger)); }
    }

    void Finish(bool paid) { if (done) return; done = true; close(paid); }
}
