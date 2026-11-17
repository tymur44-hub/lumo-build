using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace Lumo.UI;

/// <summary>Встроенный браузер: ссылки из сообщений открываются в окне Lumo</summary>
public static class Browser
{
    public static void Open(Uri u)
    {
        if (u.Scheme is not ("http" or "https")) { Shell(u.ToString()); return; }
        try { new BrowserWindow(u).Activate(); }
        catch (Exception e) { App.Log("browser: " + e); Shell(u.ToString()); }
    }
    public static void Shell(string u) { try { System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo(u) { UseShellExecute = true }); } catch { } }
}

public sealed class BrowserWindow : Window
{
    readonly WebView2 web = new();
    readonly TextBlock title = T.Txt("Загрузка…", 13.5, bold: true, lines: 1);
    readonly TextBlock host = T.Txt("", 11.5, T.Muted, lines: 1);
    readonly ProgressBar bar = new() { IsIndeterminate = true, Height = 2, VerticalAlignment = VerticalAlignment.Bottom };
    readonly Button back, fwd, reload;
    Uri cur;

    public BrowserWindow(Uri start)
    {
        cur = start;
        Title = "Lumo — браузер";
        try { AppWindow.Resize(new Windows.Graphics.SizeInt32(1100, 800)); } catch { }
        var root = new Grid { Background = T.Bg };
        root.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        root.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
        var bar0 = new Grid { Padding = new Thickness(8, 6, 8, 6), ColumnSpacing = 6, Background = T.Panel };
        for (int i = 0; i < 3; i++) bar0.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        bar0.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        bar0.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        back = T.IconButton("", "Назад", () => { if (web.CanGoBack) web.GoBack(); });
        fwd = T.IconButton("", "Вперёд", () => { if (web.CanGoForward) web.GoForward(); });
        reload = T.IconButton("", "Обновить", () => web.Reload());
        bar0.Children.Add(back); Grid.SetColumn(fwd, 1); bar0.Children.Add(fwd); Grid.SetColumn(reload, 2); bar0.Children.Add(reload);
        var info = new StackPanel { VerticalAlignment = VerticalAlignment.Center, Margin = new Thickness(6, 0, 6, 0) };
        info.Children.Add(title); info.Children.Add(host);
        Grid.SetColumn(info, 3); bar0.Children.Add(info);
        var tools = new StackPanel { Orientation = Orientation.Horizontal };
        tools.Children.Add(T.IconButton("", "Скопировать ссылку", () =>
        {
            var dp = new Windows.ApplicationModel.DataTransfer.DataPackage(); dp.SetText(cur.ToString());
            Windows.ApplicationModel.DataTransfer.Clipboard.SetContent(dp);
        }));
        tools.Children.Add(T.IconButton("", "Открыть в браузере", () => Browser.Shell(cur.ToString())));
        Grid.SetColumn(tools, 4); bar0.Children.Add(tools);
        var head = new Grid(); head.Children.Add(bar0); head.Children.Add(bar);
        root.Children.Add(head);
        Grid.SetRow(web, 1); root.Children.Add(web);
        Content = root;
        Upd();
        _ = Init(start);
    }

    async Task Init(Uri start)
    {
        await web.EnsureCoreWebView2Async(await WebEnv.Get());
        var cw = web.CoreWebView2;
        cw.NavigationStarting += (_, e) => { bar.Visibility = Visibility.Visible; if (Uri.TryCreate(e.Uri, UriKind.Absolute, out var u)) cur = u; Upd(); };
        cw.NavigationCompleted += (_, _) => { bar.Visibility = Visibility.Collapsed; Upd(); };
        cw.DocumentTitleChanged += (_, _) => { title.Text = cw.DocumentTitle; Title = cw.DocumentTitle + " — Lumo"; };
        cw.SourceChanged += (_, _) => { if (Uri.TryCreate(cw.Source, UriKind.Absolute, out var u)) cur = u; Upd(); };
        cw.NewWindowRequested += (_, e) => { e.Handled = true; if (Uri.TryCreate(e.Uri, UriKind.Absolute, out var u)) cw.Navigate(u.ToString()); };
        cw.Navigate(start.ToString());
    }

    void Upd()
    {
        host.Text = (cur.Scheme == "https" ? "🔒 " : "") + cur.Host;
        host.Text = cur.Host;
        back.IsEnabled = web.CanGoBack; fwd.IsEnabled = web.CanGoForward;
    }
}
