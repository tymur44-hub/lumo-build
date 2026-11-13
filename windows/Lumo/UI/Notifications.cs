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
        if (win != null) Flash(win.Hwnd);
        if (!ok) return;
        try
        {
            var n = new AppNotificationBuilder()
                .AddArgument("chat", chatId)
                .AddText(title.Length > 120 ? title[..120] : title)
                .AddText(body.Length > 300 ? body[..300] + "…" : body)
                .BuildNotification();
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
