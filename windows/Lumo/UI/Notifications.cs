using System.Runtime.InteropServices;
using Microsoft.Windows.AppNotifications;
using Microsoft.Windows.AppNotifications.Builder;

namespace Lumo.UI;

/// <summary>Уведомления Windows о новых сообщениях; нажатие открывает чат</summary>
public static class Notifications
{
    static bool ok;
    static MainWindow? win;

    public static void Init(MainWindow w)
    {
        win = w;
        try
        {
            var m = AppNotificationManager.Default;
            m.NotificationInvoked += (_, a) =>
            {
                a.Arguments.TryGetValue("chat", out var chat);
                w.DispatcherQueue.TryEnqueue(() => { w.BringToFront(); if (!string.IsNullOrEmpty(chat)) w.OpenChat(chat); });
            };
            m.Register();
            ok = true;
        }
        catch (Exception e) { App.Log("notify init: " + e.Message); }
    }

    public static void Show(string chatId, string title, string body)
    {
        if (!Lumo.Core.Prefs.GetBool("notify_on", true)) return;
        if (win != null && Lumo.Core.Prefs.GetBool("notify_flash", true)) Flash(win.Hwnd);
        if (!ok) return;
        if (!Lumo.Core.Prefs.GetBool("notify_preview", true) && chatId != "call") body = "Новое сообщение";
        _ = ShowAsync(chatId, title, body);
    }

    /// <summary>Фото собеседника (группы, канала) вместо значка приложения — круглое, как в мобильной версии</summary>
    static async Task ShowAsync(string chatId, string title, string body)
    {
        string? face = null;
        try
        {
            var c = Lumo.Core.Store.Chat(chatId);
            var url = c?.DisplayAvatar;
            if (!string.IsNullOrEmpty(url) && url.StartsWith("http"))
            {
                var dir = Path.Combine(Lumo.Core.Prefs.Dir, "faces"); Directory.CreateDirectory(dir);
                var file = Path.Combine(dir, Convert.ToHexString(System.Security.Cryptography.SHA1.HashData(System.Text.Encoding.UTF8.GetBytes(url)))[..16] + ".img");
                if (!File.Exists(file))
                {
                    using var cts = new CancellationTokenSource(5000);
                    var bytes = await Lumo.Core.Net.Http.GetByteArrayAsync(Lumo.Core.Net.Px(url) ?? url, cts.Token);
                    await File.WriteAllBytesAsync(file, bytes);
                }
                face = file;
            }
        }
        catch (Exception e) { App.Log("notify face: " + e.Message); }
        try
        {
            var b = new AppNotificationBuilder()
                .AddArgument("chat", chatId)
                .AddText(title.Length > 120 ? title[..120] : title)
                .AddText(body.Length > 300 ? body[..300] + "…" : body);
            if (face != null) b.SetAppLogoOverride(new Uri(face), AppNotificationImageCrop.Circle);
            var n = b.BuildNotification();
            n.Group = chatId.Length > 16 ? chatId[..16] : chatId;
            AppNotificationManager.Default.Show(n);
        }
        catch (Exception e) { App.Log("notify: " + e.Message); }
    }

    public static void ClearChat(string chatId)
    {
        if (!ok) return;
        try { _ = AppNotificationManager.Default.RemoveByGroupAsync(chatId.Length > 16 ? chatId[..16] : chatId); } catch { }
    }

    public static void Shutdown() { if (ok) try { AppNotificationManager.Default.Unregister(); } catch { } }

    [StructLayout(LayoutKind.Sequential)]
    struct FLASHWINFO { public uint cbSize; public IntPtr hwnd; public uint dwFlags; public uint uCount; public uint dwTimeout; }
    [DllImport("user32.dll")] static extern bool FlashWindowEx(ref FLASHWINFO pwfi);

    /// <summary>Мигнуть кнопкой на панели задач, пока окно не в фокусе</summary>
    public static void Flash(IntPtr hwnd)
    {
        try
        {
            var f = new FLASHWINFO { cbSize = (uint)Marshal.SizeOf<FLASHWINFO>(), hwnd = hwnd, dwFlags = 2 | 12, uCount = 3, dwTimeout = 0 };
            FlashWindowEx(ref f);
        }
        catch { }
    }
}
