using Lumo.Core;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;

namespace Lumo.UI;

/// <summary>Полоса историй над списком чатов</summary>
public sealed class StoriesStrip : ScrollViewer
{
    readonly StackPanel row = new() { Orientation = Orientation.Horizontal, Spacing = 10, Padding = new Thickness(12, 2, 12, 8) };
    public event Action<int>? Open;

    public StoriesStrip()
    {
        HorizontalScrollBarVisibility = ScrollBarVisibility.Hidden; HorizontalScrollMode = ScrollMode.Enabled;
        VerticalScrollBarVisibility = ScrollBarVisibility.Disabled; VerticalScrollMode = ScrollMode.Disabled;
        Content = row;
        Store.StoriesChanged += Build;
        Build();
    }

    public void Detach() => Store.StoriesChanged -= Build;

    void Build()
    {
        row.Children.Clear();
        var list = Store.Stories;
        Visibility = list.Count == 0 ? Visibility.Collapsed : Visibility.Visible;
        for (int i = 0; i < list.Count; i++)
        {
            var g = list[i];
            var sp = new StackPanel { Spacing = 4, Width = 62, Background = T.Transparent };
            var ring = new Border
            {
                Width = 58, Height = 58, CornerRadius = new CornerRadius(29), Padding = new Thickness(3), HorizontalAlignment = HorizontalAlignment.Center,
                BorderThickness = new Thickness(2.5), BorderBrush = g.UserId == Store.MyId ? T.Accent : g.Unseen ? T.Grad(0xFFFF9F1A, 0xFFFF3B8A) : T.B(0x33FFFFFF),
            };
            var av = new AvatarView(47); av.Set(g.UserId == Store.MyId ? "Вы" : g.Name, g.AvatarUrl, g.Color);
            ring.Child = av;
            sp.Children.Add(ring);
            var n = new TextBlock { Text = g.UserId == Store.MyId ? "Моя история" : g.Name.Split(' ')[0], FontSize = 11.5, Foreground = g.Unseen ? T.Text : T.Muted, TextTrimming = TextTrimming.CharacterEllipsis, HorizontalAlignment = HorizontalAlignment.Center, MaxWidth = 62 };
            sp.Children.Add(n);
            var idx = i;
            sp.Tapped += (_, _) => Open?.Invoke(idx);
            row.Children.Add(sp);
        }
    }
}

/// <summary>Просмотр историй: полоски прогресса, листание кликом по краям, Esc — закрыть</summary>
public sealed class StoryViewer : Grid
{
    readonly List<StoryGroup> groups;
    int gi, ii;
    readonly Grid stage = new() { Width = 420, Height = 746, CornerRadius = new CornerRadius(18), Background = T.B(0xFF000000), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
    readonly StackPanel bars = new() { Orientation = Orientation.Horizontal, Spacing = 3, Margin = new Thickness(10, 10, 10, 0), VerticalAlignment = VerticalAlignment.Top };
    readonly Grid media = new();
    readonly AvatarView av = new(34);
    readonly TextBlock name = T.Txt("", 14, T.White, bold: true, lines: 1), when = T.Txt("", 12, T.OutMuted, lines: 1), caption = T.Txt("", 14, T.White);
    readonly DispatcherTimer timer = new() { Interval = TimeSpan.FromMilliseconds(50) };
    DateTime started; double duration = 6;
    MediaPlayerElement? player;
    public event Action? Closed;

    public StoryViewer(List<StoryGroup> groups, int start)
    {
        this.groups = groups; gi = start;
        Background = T.B(0xF2050610);
        stage.Children.Add(media);
        var sh = new LinearGradientBrush { StartPoint = new Windows.Foundation.Point(0, 0), EndPoint = new Windows.Foundation.Point(0, 1) };
        sh.GradientStops.Add(new GradientStop { Color = T.C(0x99000000), Offset = 0 });
        sh.GradientStops.Add(new GradientStop { Color = T.C(0x00000000), Offset = 1 });
        var shade = new Border { Height = 90, VerticalAlignment = VerticalAlignment.Top, Background = sh };
        stage.Children.Add(shade);
        stage.Children.Add(bars);
        var head = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 10, Margin = new Thickness(12, 22, 12, 0), VerticalAlignment = VerticalAlignment.Top };
        head.Children.Add(av);
        var hs = new StackPanel { VerticalAlignment = VerticalAlignment.Center }; hs.Children.Add(name); hs.Children.Add(when);
        head.Children.Add(hs);
        stage.Children.Add(head);
        caption.Margin = new Thickness(16, 0, 16, 20); caption.VerticalAlignment = VerticalAlignment.Bottom; caption.TextAlignment = TextAlignment.Center;
        stage.Children.Add(caption);
        // края — назад / вперёд
        var nav = new Grid();
        nav.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        nav.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(2, GridUnitType.Star) });
        var l = new Border { Background = T.Transparent }; l.Tapped += (_, e) => { e.Handled = true; Prev(); };
        var r = new Border { Background = T.Transparent }; r.Tapped += (_, e) => { e.Handled = true; Next(); };
        Grid.SetColumn(r, 1); nav.Children.Add(l); nav.Children.Add(r);
        nav.Margin = new Thickness(0, 70, 0, 0);
        stage.Children.Add(nav);
        Children.Add(stage);
        var close = T.IconButton("\uE711", "Закрыть (Esc)", Close, 44, 16, T.White);
        close.HorizontalAlignment = HorizontalAlignment.Right; close.VerticalAlignment = VerticalAlignment.Top; close.Margin = new Thickness(16);
        Children.Add(close);
        Tapped += (_, e) => { if (e.OriginalSource == this) Close(); };
        var esc = new KeyboardAccelerator { Key = Windows.System.VirtualKey.Escape }; esc.Invoked += (_, e) => { e.Handled = true; Close(); }; KeyboardAccelerators.Add(esc);
        var right = new KeyboardAccelerator { Key = Windows.System.VirtualKey.Right }; right.Invoked += (_, e) => { e.Handled = true; Next(); }; KeyboardAccelerators.Add(right);
        var left = new KeyboardAccelerator { Key = Windows.System.VirtualKey.Left }; left.Invoked += (_, e) => { e.Handled = true; Prev(); }; KeyboardAccelerators.Add(left);
        timer.Tick += (_, _) => Tick();
        // первая непросмотренная в группе
        var g0 = groups[gi]; ii = Math.Max(0, g0.Items.FindIndex(x => !x.Seen));
        Loaded += (_, _) => Show();
    }

    void Show()
    {
        var g = groups[gi]; var s = g.Items[ii];
        av.Set(g.Name, g.AvatarUrl, g.Color);
        name.Text = g.UserId == Store.MyId ? "Моя история" : g.Name;
        when.Text = Fmt.ListTime(s.CreatedAt) + (g.UserId == Store.MyId ? " · просмотров: " + s.Views : "");
        caption.Text = s.Caption;
        caption.Visibility = s.Caption.Length > 0 ? Visibility.Visible : Visibility.Collapsed;
        bars.Children.Clear();
        for (int k = 0; k < g.Items.Count; k++)
            bars.Children.Add(new ProgressBar { Width = (400 - 3 * (g.Items.Count - 1)) / (double)g.Items.Count, Height = 3, Minimum = 0, Maximum = 1, Value = k < ii ? 1 : 0, Foreground = T.White, Background = T.B(0x55FFFFFF) });
        StopPlayer();
        media.Children.Clear();
        duration = 6;
        if (s.Kind == "video")
        {
            player = new MediaPlayerElement { AutoPlay = true, Stretch = Stretch.Uniform, AreTransportControlsEnabled = false };
            player.Source = Windows.Media.Core.MediaSource.CreateFromUri(new Uri(Net.Px(s.MediaUrl)!));
            media.Children.Add(player);
            duration = 15;
        }
        else media.Children.Add(new Image { Source = T.Bitmap(s.MediaUrl), Stretch = Stretch.Uniform });
        started = DateTime.UtcNow;
        timer.Start();
        _ = Store.ViewStory(s);
    }

    void Tick()
    {
        var g = groups[gi];
        if (player?.MediaPlayer?.PlaybackSession is { } ps && ps.NaturalDuration.TotalSeconds > 0) duration = ps.NaturalDuration.TotalSeconds;
        var p = Math.Min(1, (DateTime.UtcNow - started).TotalSeconds / duration);
        if (bars.Children.Count > ii && bars.Children[ii] is ProgressBar pb) pb.Value = p;
        if (p >= 1) Next();
    }

    void Next()
    {
        var g = groups[gi];
        if (ii + 1 < g.Items.Count) { ii++; Show(); return; }
        if (gi + 1 < groups.Count) { gi++; ii = Math.Max(0, groups[gi].Items.FindIndex(x => !x.Seen)); Show(); return; }
        Close();
    }

    void Prev()
    {
        if (ii > 0) { ii--; Show(); return; }
        if (gi > 0) { gi--; ii = 0; Show(); return; }
        started = DateTime.UtcNow;
    }

    void StopPlayer()
    {
        if (player == null) return;
        try { player.MediaPlayer?.Pause(); player.Source = null; } catch { }
        player = null;
    }

    void Close()
    {
        timer.Stop(); StopPlayer();
        Closed?.Invoke();
        _ = Store.LoadStories();
    }
}
