using System.Security.Cryptography;
using System.Text.Json.Nodes;
using Lumo.Core;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Media.Imaging;
using QRCoder;

namespace Lumo.UI;

/// <summary>
/// Вход только по QR-коду: телефон с Lumo сканирует код (Настройки → Подключить компьютер) и подтверждает вход.
/// Протокол тот же, что в веб-версии: канал lm-qr-{ключ}, события scan / cancel / login (token_hash) / ok / fail.
/// </summary>
public sealed class LoginView : Grid
{
    readonly Grid qrBox = new() { Width = 260, Height = 260, CornerRadius = new CornerRadius(24), Background = T.White, HorizontalAlignment = HorizontalAlignment.Center };
    readonly Image qrImg = new() { Width = 236, Height = 236, Stretch = Stretch.Uniform };
    readonly Border scanned = new() { Visibility = Visibility.Collapsed, Background = T.B(0xE6FFFFFF), CornerRadius = new CornerRadius(24) };
    readonly ProgressRing ring = new() { IsActive = true, Width = 34, Height = 34 };
    readonly TextBlock status = T.Txt("", 14, T.A2, bold: true);
    string? key;
    Realtime.Channel? ch;
    CancellationTokenSource? rot;
    bool done;

    public LoginView()
    {
        Background = T.Bg;
        var card = new StackPanel { Width = 420, Spacing = 14, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
        qrBox.Children.Add(ring);
        qrImg.HorizontalAlignment = HorizontalAlignment.Center; qrImg.VerticalAlignment = VerticalAlignment.Center;
        qrBox.Children.Add(qrImg);
        // логотип в центре кода
        try
        {
            var logo = new Border { Width = 52, Height = 52, CornerRadius = new CornerRadius(14), Background = T.White, Padding = new Thickness(4), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center,
                Child = new Image { Source = new BitmapImage(new Uri(Path.Combine(AppContext.BaseDirectory, "Assets", "logo.png"))) } };
            qrBox.Children.Add(logo);
        }
        catch { }
        var sc = new StackPanel { Spacing = 8, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
        var ok = T.Icon("\uE8EA", 40, T.A1); ok.HorizontalAlignment = HorizontalAlignment.Center;
        sc.Children.Add(ok);
        var st = T.Txt("Подтвердите вход\nна телефоне", 15, T.B(0xFF25264A), bold: true); st.TextAlignment = TextAlignment.Center;
        sc.Children.Add(st);
        scanned.Child = sc;
        qrBox.Children.Add(scanned);
        card.Children.Add(qrBox);

        var title = T.Txt("Вход в Lumo по QR-коду", 22, bold: true); title.HorizontalAlignment = HorizontalAlignment.Center; title.Margin = new Thickness(0, 8, 0, 0);
        card.Children.Add(title);
        var steps = new StackPanel { Spacing = 8, Margin = new Thickness(20, 0, 20, 0) };
        string[] lines = { "Откройте Lumo на телефоне", "Зайдите в Настройки → Подключить компьютер", "Наведите камеру телефона на этот код" };
        for (int i = 0; i < lines.Length; i++)
        {
            var r = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 12 };
            var n = new Border { Width = 26, Height = 26, CornerRadius = new CornerRadius(13), Background = T.Accent, Child = new TextBlock { Text = (i + 1).ToString(), Foreground = T.White, FontWeight = Microsoft.UI.Text.FontWeights.Bold, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center } };
            r.Children.Add(n);
            var t = T.Txt(lines[i], 14.5, T.Text); t.VerticalAlignment = VerticalAlignment.Center;
            r.Children.Add(t);
            steps.Children.Add(r);
        }
        card.Children.Add(steps);
        status.HorizontalAlignment = HorizontalAlignment.Center; status.TextAlignment = TextAlignment.Center;
        card.Children.Add(status);
        var hint = T.Txt("Нет аккаунта? Зарегистрируйтесь в приложении Lumo на телефоне.", 12.5, T.Muted); hint.HorizontalAlignment = HorizontalAlignment.Center; hint.TextAlignment = TextAlignment.Center;
        card.Children.Add(hint);
        var pl = new HyperlinkButton { Content = "Политика конфиденциальности", HorizontalAlignment = HorizontalAlignment.Center, FontSize = 12 };
        pl.Click += async (_, _) => await Dialogs.Policy(App.Win);
        card.Children.Add(pl);
        Children.Add(card);

        Loaded += async (_, _) => { await Net.Pick(); Rotate(); };
        Unloaded += (_, _) => Stop();
    }

    static string NewKey()
    {
        var b = RandomNumberGenerator.GetBytes(18);
        return Convert.ToBase64String(b).Replace('+', '-').Replace('/', '_').TrimEnd('=');
    }

    void Stop()
    {
        rot?.Cancel();
        if (key != null) Realtime.Leave("lm-qr-" + key);
        ch = null; key = null;
    }

    /// <summary>Новый код каждую минуту (как в веб-версии)</summary>
    async void Rotate()
    {
        if (done || Api.Session != null) return;
        Stop();
        var k = NewKey(); key = k;
        scanned.Visibility = Visibility.Collapsed;
        try
        {
            using var gen = new QRCodeGenerator();
            using var data = gen.CreateQrCode("https://lumomess.ru/#lmqr=" + k, QRCodeGenerator.ECCLevel.Q);
            var png = new PngByteQRCode(data).GetGraphic(12, new byte[] { 0x14, 0x14, 0x2B, 0xFF }, new byte[] { 0xFF, 0xFF, 0xFF, 0xFF }, false);
            var bmp = new BitmapImage();
            using (var ms = new MemoryStream(png)) await bmp.SetSourceAsync(ms.AsRandomAccessStream());
            qrImg.Source = bmp;
            ring.IsActive = false; ring.Visibility = Visibility.Collapsed;
        }
        catch (Exception e) { App.Log("qr: " + e.Message); status.Text = "Не удалось показать QR-код"; }
        Realtime.Connect();
        ch = Realtime.Get("lm-qr-" + k);
        ch.OnBroadcast = (ev, p) => { if (ev == "qr") OnMsg(p, k); };
        var c = new CancellationTokenSource(); rot = c;
        try { await Task.Delay(60000, c.Token); } catch { return; }
        Rotate();
    }

    async void OnMsg(JsonObject p, string k)
    {
        if (k != key || done) return;
        switch (p.Str("t"))
        {
            case "scan":
                rot?.Cancel();
                scanned.Visibility = Visibility.Visible;
                status.Text = "Подтвердите вход на телефоне…";
                var c = new CancellationTokenSource(); rot = c;
                try { await Task.Delay(120000, c.Token); } catch { return; }
                status.Text = ""; Rotate();
                break;
            case "cancel":
                status.Text = "Вход отменён на телефоне";
                await Task.Delay(1500);
                if (key == k) { status.Text = ""; Rotate(); }
                break;
            case "login":
            {
                var th = p.Str("th"); if (th == null) return;
                status.Text = "Входим…";
                var chan = ch;
                bool okLogin;
                try { await Api.SignInWithHash(th); okLogin = true; }
                catch (Exception e) { App.Log("qr login: " + e.Message); okLogin = false; }
                if (chan != null) Realtime.Broadcast(chan, "qr", J.O(("t", okLogin ? "ok" : "fail")));
                if (!okLogin) { status.Text = "Не удалось войти — попробуйте ещё раз"; await Task.Delay(1500); Rotate(); return; }
                done = true;
                await Task.Delay(400);
                Stop();
                break;
            }
        }
    }
}
