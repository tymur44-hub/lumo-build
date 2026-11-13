using Lumo.Core;
using Lumo.UI;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Media.Imaging;
using Windows.Graphics;

namespace Lumo;

public sealed class MainWindow : Window
{
    public IntPtr Hwnd { get; }
    readonly Grid root = new() { Background = T.Bg };
    readonly Grid host = new();
    readonly Grid layer = new() { Visibility = Visibility.Collapsed };
    readonly Border toast;
    readonly TextBlock toastText = new() { Foreground = T.Text, FontSize = 13, TextWrapping = TextWrapping.Wrap };
    readonly TextBlock titleText = new() { Text = "Lumo", FontSize = 12, Foreground = T.Muted, VerticalAlignment = VerticalAlignment.Center };
    ShellView? shell;
    bool loggedIn;
    public XamlRoot? Root => root.XamlRoot;

    public MainWindow()
    {
        Title = "Lumo";
        ExtendsContentIntoTitleBar = true;
        root.RowDefinitions.Add(new RowDefinition { Height = new GridLength(34) });
        root.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });

        var bar = new Grid { Background = T.Transparent };
        var bp = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 8, Margin = new Thickness(14, 0, 0, 0), VerticalAlignment = VerticalAlignment.Center };
        try { bp.Children.Add(new Image { Source = new BitmapImage(new Uri(Path.Combine(AppContext.BaseDirectory, "Assets", "logo.png"))), Width = 16, Height = 16 }); } catch { }
        bp.Children.Add(titleText);
        bar.Children.Add(bp);
        root.Children.Add(bar);
        SetTitleBar(bar);

        Grid.SetRow(host, 1);
        root.Children.Add(host);

        toast = new Border
        {
            Background = T.Panel2, CornerRadius = new CornerRadius(12), Padding = new Thickness(16, 10, 16, 10), BorderBrush = T.Line, BorderThickness = new Thickness(1),
            HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Bottom, Margin = new Thickness(0, 0, 0, 90),
            MaxWidth = 460, Child = toastText, Visibility = Visibility.Collapsed, IsHitTestVisible = false,
        };
        Grid.SetRowSpan(layer, 2);
        root.Children.Add(layer);
        Sheet.Layer = layer;
        Grid.SetRowSpan(toast, 2);
        root.Children.Add(toast);
        Content = root;

        Hwnd = WinRT.Interop.WindowNative.GetWindowHandle(this);
        try
        {
            AppWindow.Resize(new SizeInt32(1240, 820));
            AppWindow.SetIcon(Path.Combine(AppContext.BaseDirectory, "Assets", "lumo.ico"));
            var tb = AppWindow.TitleBar;
            tb.ButtonBackgroundColor = Colors.Transparent; tb.ButtonInactiveBackgroundColor = Colors.Transparent;
            tb.ButtonForegroundColor = T.C(0xFFEEF0FF); tb.ButtonInactiveForegroundColor = T.C(0xFF8D90B8);
            tb.ButtonHoverBackgroundColor = T.C(0x22FFFFFF);
        }
        catch { }

        Realtime.Post = a => DispatcherQueue.TryEnqueue(() => a());
        Activated += (_, e) =>
        {
            Store.WindowActive = e.WindowActivationState != WindowActivationState.Deactivated;
            if (Store.WindowActive && Store.OpenChatId != null) { Store.MarkRead(Store.OpenChatId); Notifications.ClearChat(Store.OpenChatId); }
        };
        Closed += (_, _) => { Store.Presence(false); Notifications.Shutdown(); };
        Store.Toast += ShowToast;
        Store.Notify += (c, t, b) => { if (!Store.WindowActive || Store.OpenChatId != c) Notifications.Show(c, t, b); };
        Store.ChatsChanged += UpdateTitle;
        Store.NetState += _ => UpdateTitle();
        Api.SessionChanged += s => DispatcherQueue.TryEnqueue(() =>
        {
            if (s != null && loggedIn) { Realtime.UpdateToken(s.Access); return; }
            Route();
        });
        Route();
    }

    void UpdateTitle()
    {
        var n = Store.UnreadTotal;
        Title = n > 0 ? $"Lumo ({n})" : "Lumo";
        titleText.Text = loggedIn && Store.Started && !Realtime.IsOpen ? "Lumo · соединение…" : "Lumo";
    }

    void Route()
    {
        var want = Api.Session != null || Store.Demo;
        if (want == loggedIn && host.Children.Count > 0) return;
        loggedIn = want;
        shell?.Detach();
        host.Children.Clear();
        if (!want)
        {
            Store.Stop(); shell = null;
            host.Children.Add(new LoginView());
        }
        else
        {
            shell = new ShellView(this);
            host.Children.Add(shell);
            _ = StartAsync();
        }
        UpdateTitle();
    }

    async Task StartAsync()
    {
        await Store.Start();
        if (Store.Demo) { _ = DemoScript(); return; }
        if (E2E.Status == E2E.State.NeedRestore) await Dialogs.RestoreKeys(this);
    }

    /// <summary>Демо-режим (LUMO_DEMO=1): открыть экраны по очереди и сохранить снимки окна — для проверки сборки</summary>
    async Task DemoScript()
    {
        var dir = Path.Combine(Prefs.Dir, "shots");
        Directory.CreateDirectory(dir);
        try
        {
            await Task.Delay(2500);
            await Capture(Path.Combine(dir, "0-list.png"));
            var first = Store.Chats.FirstOrDefault();
            if (first != null) OpenChat(first.Id);
            await Task.Delay(2500);
            await Capture(Path.Combine(dir, "1-chat.png"));
            _ = Dialogs.Settings(this);
            await Task.Delay(1500);
            await Capture(Path.Combine(dir, "2-profile.png"));
            Sheet.CloseTop();
            await Task.Delay(600);
            if (first != null) _ = Dialogs.ChatInfo(this, first);
            await Task.Delay(1500);
            await Capture(Path.Combine(dir, "3-info.png"));
            Sheet.CloseTop();
            await Task.Delay(600);
            if (Store.Chats.Count > 1) OpenChat(Store.Chats[1].Id);
            await Task.Delay(2500);
            await Capture(Path.Combine(dir, "4-group.png"));
            await DemoExtra(dir);
        }
        catch (Exception e) { App.Log("demo: " + e); }
        File.WriteAllText(Path.Combine(dir, "done.txt"), "ok");
    }

    /// <summary>Дополнительные экраны демо (этапы 2–3)</summary>
    async Task DemoExtra(string dir)
    {
        await Task.CompletedTask;
    }

    public async Task Capture(string path)
    {
        try
        {
            var rtb = new Microsoft.UI.Xaml.Media.Imaging.RenderTargetBitmap();
            await rtb.RenderAsync(root);
            var px = await rtb.GetPixelsAsync();
            var folder = await Windows.Storage.StorageFolder.GetFolderFromPathAsync(Path.GetDirectoryName(path)!);
            var file = await folder.CreateFileAsync(Path.GetFileName(path), Windows.Storage.CreationCollisionOption.ReplaceExisting);
            using var st = await file.OpenAsync(Windows.Storage.FileAccessMode.ReadWrite);
            var enc = await Windows.Graphics.Imaging.BitmapEncoder.CreateAsync(Windows.Graphics.Imaging.BitmapEncoder.PngEncoderId, st);
            enc.SetPixelData(Windows.Graphics.Imaging.BitmapPixelFormat.Bgra8, Windows.Graphics.Imaging.BitmapAlphaMode.Premultiplied,
                (uint)rtb.PixelWidth, (uint)rtb.PixelHeight, 96, 96, System.Runtime.InteropServices.WindowsRuntime.WindowsRuntimeBufferExtensions.ToArray(px));
            await enc.FlushAsync();
        }
        catch (Exception e) { App.Log("capture: " + e.Message); }
    }

    public void OpenChat(string chatId) => shell?.Open(chatId);

    public void BringToFront()
    {
        try { if (AppWindow.Presenter is Microsoft.UI.Windowing.OverlappedPresenter p && p.State == Microsoft.UI.Windowing.OverlappedPresenterState.Minimized) p.Restore(); } catch { }
        Activate();
    }

    CancellationTokenSource? toastCts;
    public async void ShowToast(string text)
    {
        toastText.Text = text;
        toast.Visibility = Visibility.Visible;
        toastCts?.Cancel(); var c = new CancellationTokenSource(); toastCts = c;
        try { await Task.Delay(2600, c.Token); } catch { return; }
        toast.Visibility = Visibility.Collapsed;
    }
}
