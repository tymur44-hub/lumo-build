using Lumo.Core;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Media.Animation;
using Microsoft.UI.Xaml.Media.Imaging;

namespace Lumo.UI;

/// <summary>Эмодзи-статус: анимированный значок (как в мобильной версии, 48 кадров) или обычный эмодзи</summary>
public sealed class StatusEmoji : Grid
{
    public static readonly (string Key, string Glyph)[] Anim =
    {
        ("fire", "🔥"), ("heart", "❤️"), ("star", "⭐"), ("rocket", "🚀"), ("crown", "👑"), ("gem", "💎"),
        ("bolt", "⚡"), ("ghost", "👻"), ("sun", "☀️"), ("moon", "🌙"), ("clover", "🍀"), ("note", "🎵"),
        ("snow", "❄️"), ("trophy", "🏆"), ("skull", "💀"), ("pumpkin", "🎃"), ("confetti", "🎊"), ("witch", "🧙"),
    };
    static readonly List<WeakReference<StatusEmoji>> live = new();
    static readonly System.Diagnostics.Stopwatch clock = System.Diagnostics.Stopwatch.StartNew();
    static bool hooked;
    static int lastFrame = -1;

    readonly TranslateTransform tr = new();
    readonly double size;
    readonly bool sprite;

    public StatusEmoji(string s, double size = 18)
    {
        this.size = size;
        Width = size; Height = size; VerticalAlignment = VerticalAlignment.Center;
        var key = s.StartsWith("a:") ? s[2..] : null;
        var file = key != null ? Path.Combine(AppContext.BaseDirectory, "Assets", "status", "st_" + key + ".png") : null;
        if (file != null && File.Exists(file))
        {
            sprite = true;
            Clip = new RectangleGeometry { Rect = new Windows.Foundation.Rect(0, 0, size, size) };
            var img = new Image { Source = new BitmapImage(new Uri(file)), Width = size * 8, Height = size * 6, Stretch = Stretch.Fill, HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top, RenderTransform = tr };
            Children.Add(img);
            Loaded += (_, _) => { live.Add(new WeakReference<StatusEmoji>(this)); Hook(); };
            Unloaded += (_, _) => live.RemoveAll(w => !w.TryGetTarget(out var t) || t == this);
        }
        else
        {
            var g = key != null ? Anim.FirstOrDefault(a => a.Key == key).Glyph ?? "⭐" : s;
            var t = new TextBlock { Text = g, FontSize = size * 0.9, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
            Children.Add(t);
        }
    }

    static void Hook()
    {
        if (hooked) return; hooked = true;
        CompositionTarget.Rendering += (_, _) =>
        {
            if (live.Count == 0) return;
            var f = (int)(clock.Elapsed.TotalSeconds * 24) % 48;
            if (f == lastFrame) return;
            lastFrame = f;
            foreach (var w in live.ToList())
                if (w.TryGetTarget(out var e)) { e.tr.X = -(f % 8) * e.size; e.tr.Y = -(f / 8) * e.size; }
                else live.Remove(w);
        };
    }
}

/// <summary>Плашка сверху окна (как в мобильной): значок, заголовок, пояснение</summary>
public static class Plaque
{
    static Border? cur;
    public static void Show(string glyph, string title, string text)
    {
        var root = App.Win?.Content as Panel; if (root == null) return;
        if (cur != null) root.Children.Remove(cur);
        var g = new Grid { ColumnSpacing = 12, Padding = new Thickness(16, 12, 18, 12) };
        g.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        g.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        var ic = T.Icon(glyph, 24, T.A2); ic.VerticalAlignment = VerticalAlignment.Center; g.Children.Add(ic);
        var sp = new StackPanel { Spacing = 2 };
        sp.Children.Add(T.Txt(title, 15, bold: true));
        sp.Children.Add(T.Txt(text, 13.5, T.Muted));
        Grid.SetColumn(sp, 1); g.Children.Add(sp);
        var b = new Border
        {
            Child = g, CornerRadius = new CornerRadius(20), Background = T.Panel2, BorderBrush = T.B(0x22FFFFFF), BorderThickness = new Thickness(1),
            HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Top, Margin = new Thickness(0, 46, 0, 0), MaxWidth = 460,
            Shadow = new ThemeShadow(), Translation = new System.Numerics.Vector3(0, 0, 48), Opacity = 0, RenderTransform = new TranslateTransform { Y = -30 },
        };
        Canvas.SetZIndex(b, 1000);
        Grid.SetColumnSpan(b, 10); Grid.SetRowSpan(b, 10);
        root.Children.Add(b); cur = b;
        Animate(b, true);
        b.Tapped += (_, _) => Hide(b);
        _ = Task.Delay(3800).ContinueWith(_ => b.DispatcherQueue.TryEnqueue(() => Hide(b)));
    }
    static void Hide(Border b)
    {
        if (b.Parent is not Panel p) return;
        var sb = Animate(b, false);
        sb.Completed += (_, _) => { p.Children.Remove(b); if (cur == b) cur = null; };
    }
    static Storyboard Animate(Border b, bool show)
    {
        var sb = new Storyboard();
        var o = new DoubleAnimation { To = show ? 1 : 0, Duration = TimeSpan.FromMilliseconds(show ? 320 : 200) };
        Storyboard.SetTarget(o, b); Storyboard.SetTargetProperty(o, "Opacity"); sb.Children.Add(o);
        var y = new DoubleAnimation { To = show ? 0 : -20, Duration = TimeSpan.FromMilliseconds(380), EasingFunction = new BackEase { EasingMode = EasingMode.EaseOut, Amplitude = 0.35 } };
        Storyboard.SetTarget(y, b.RenderTransform); Storyboard.SetTargetProperty(y, "Y"); sb.Children.Add(y);
        sb.Begin();
        return sb;
    }

    public static void Verified(string kind)
    {
        var who = kind switch { "канал" => "Этот канал", "группа" => "Эта группа", "бот" => "Этот бот", _ => "Этот профиль" };
        Show("", "Подтверждено", who + " подтверждён администрацией Lumo.");
    }
}

/// <summary>Значок «подтверждено»: по нажатию — пояснение</summary>
public static class VerifiedMark
{
    public static FrameworkElement Make(string kind, double size = 16)
    {
        var ic = T.Icon("", size, T.A2);
        var b = new Border { Child = ic, Background = T.Transparent, VerticalAlignment = VerticalAlignment.Center, Padding = new Thickness(2) };
        ToolTipService.SetToolTip(b, "Подтверждено");
        b.Tapped += (_, e) => { e.Handled = true; Plaque.Verified(kind); };
        return b;
    }
}

/// <summary>Выбор эмодзи-статуса (как в мобильной)</summary>
public static class StatusPicker
{
    public static async Task Show()
    {
        var me = Store.Me;
        if (me?.Premium != true) { Plaque.Show("", "Lumo Premium", "Эмодзи-статус доступен с подпиской Premium — оформить её можно в приложении на телефоне."); return; }
        var sp = new StackPanel { Spacing = 12 };
        sp.Children.Add(T.Txt("Значок показывается рядом с вашим именем. Анимированные двигаются у всех, кто пользуется Lumo.", 12.5, T.Muted));
        var grid = new VariableSizedWrapGrid { Orientation = Orientation.Horizontal, ItemWidth = 76, ItemHeight = 66 };
        Sheet? sheet = null;
        foreach (var (k, _) in StatusEmoji.Anim)
        {
            var b = new Button { Width = 68, Height = 58, CornerRadius = new CornerRadius(14), BorderThickness = new Thickness(me.EmojiStatus == "a:" + k ? 2 : 0), BorderBrush = T.A2, Content = new StatusEmoji("a:" + k, 34) };
            T.Fill(b, T.Panel2, T.B(0xFF24264A));
            var key = k;
            b.Click += async (_, _) => { sheet?.Hide(); await Set("a:" + key); };
            grid.Children.Add(b);
        }
        sp.Children.Add(grid);
        var off = new HyperlinkButton { Content = "Убрать статус", Foreground = T.Danger };
        off.Click += async (_, _) => { sheet?.Hide(); await Set(""); };
        sp.Children.Add(off);
        sheet = new Sheet { Title = "Эмодзи-статус", Content = sp, Width = 420 };
        await sheet.ShowAsync();
    }
    static async Task Set(string e)
    {
        try { await Api.Rpc("lm_set_emoji_status", new System.Text.Json.Nodes.JsonObject { ["p_emoji"] = e }); await Store.LoadMe(); Store.Say(e.Length == 0 ? "Статус убран" : "Статус установлен"); }
        catch (Exception ex) { Store.Say(ex.Message); }
    }
}
