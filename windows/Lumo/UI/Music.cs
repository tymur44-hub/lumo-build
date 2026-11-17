using Lumo.Core;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Controls.Primitives;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Media.Animation;
using Windows.Media.Playback;

namespace Lumo.UI;

public record Track(int Id, string ChatId, string Title, string Artist, string Url);

/// <summary>Музыка из чатов: играет в фоне, очередь — все аудио этого чата</summary>
public static class Music
{
    static readonly HashSet<string> exts = new() { "mp3", "m4a", "wav", "flac", "aac", "opus", "ogg", "aiff", "alac", "wma" };
    public static bool IsAudio(string name) => exts.Contains(Path.GetExtension(name).TrimStart('.').ToLowerInvariant());

    public static Track? Current { get; private set; }
    public static List<Track> Queue { get; private set; } = new();
    public static bool Playing { get; private set; }
    public static double Position { get; private set; }
    public static double Length { get; private set; }
    public static double Progress => Length > 0 ? Math.Clamp(Position / Length, 0, 1) : 0;
    /// <summary>сменился трек или пауза</summary>
    public static event Action? Changed;
    /// <summary>сдвинулось время</summary>
    public static event Action? Tick;

    static MediaPlayer? mp;
    static Microsoft.UI.Dispatching.DispatcherQueue? ui;

    static Track? TrackOf(Message m)
    {
        if (m.MediaUrl == null) return null;
        var b = Path.GetFileNameWithoutExtension(m.FileName);
        var parts = b.Split(" - ", 2);
        return new Track(m.Id, m.ChatId, parts.Length > 1 ? parts[1] : b, parts.Length > 1 ? parts[0] : "Lumo", m.MediaUrl);
    }

    static MediaPlayer P()
    {
        if (mp != null) return mp;
        ui ??= Microsoft.UI.Dispatching.DispatcherQueue.GetForCurrentThread();
        mp = new MediaPlayer();
        mp.PlaybackSession.PositionChanged += (s, _) =>
        {
            var pos = s.Position.TotalSeconds; var len = s.NaturalDuration.TotalSeconds;
            ui?.TryEnqueue(() => { Position = pos; if (len > 0) Length = len; Tick?.Invoke(); });
        };
        mp.PlaybackSession.PlaybackStateChanged += (s, _) =>
        {
            var pl = s.PlaybackState == MediaPlaybackState.Playing;
            ui?.TryEnqueue(() => { if (Playing != pl) { Playing = pl; Changed?.Invoke(); } });
        };
        mp.MediaEnded += (_, _) => ui?.TryEnqueue(Next);
        return mp;
    }

    public static void Play(Message m, IEnumerable<Message> all)
    {
        Queue = all.Where(x => x.Kind == "file" && !x.Deleted && IsAudio(x.FileName)).Select(TrackOf).OfType<Track>().ToList();
        if (Queue.Count == 0 && TrackOf(m) is { } t0) Queue = new() { t0 };
        if (TrackOf(m) is { } t) Start(t);
    }

    public static void Start(Track t)
    {
        if (Current?.Id == t.Id && mp != null) { Resume(); return; }
        VoiceView.StopAll();
        Current = t; Position = 0; Length = 0;
        var p = P();
        p.Source = Windows.Media.Core.MediaSource.CreateFromUri(new Uri(Net.Px(t.Url)!));
        p.Play();
        Playing = true;
        Changed?.Invoke();
    }

    public static void Toggle() { if (Playing) Pause(); else Resume(); }
    public static void Resume() { if (mp == null) { if (Current != null) Start(Current); return; } mp.Play(); }
    public static void Pause() => mp?.Pause();
    public static void Seek(double f) { if (mp == null || Length <= 0) return; Position = Length * f; mp.PlaybackSession.Position = TimeSpan.FromSeconds(Position); Tick?.Invoke(); }
    public static void Next()
    {
        var i = Queue.FindIndex(x => x.Id == Current?.Id);
        if (i >= 0 && i + 1 < Queue.Count) Start(Queue[i + 1]);
        else { Pause(); if (mp != null) mp.PlaybackSession.Position = TimeSpan.Zero; }
    }
    public static void Prev()
    {
        if (Position > 3 && mp != null) { mp.PlaybackSession.Position = TimeSpan.Zero; return; }
        var i = Queue.FindIndex(x => x.Id == Current?.Id);
        if (i > 0) Start(Queue[i - 1]); else if (mp != null) mp.PlaybackSession.Position = TimeSpan.Zero;
    }
    public static void Stop()
    {
        mp?.Pause(); mp?.Dispose(); mp = null;
        Current = null; Playing = false; Position = 0; Length = 0; Queue = new();
        Changed?.Invoke();
    }

    /// <summary>Плавное появление/исчезновение элемента</summary>
    public static void Fade(UIElement e, bool show)
    {
        if (show && e.Visibility == Visibility.Visible && e.Opacity >= 1) return;
        if (show) e.Visibility = Visibility.Visible;
        var a = new DoubleAnimation { To = show ? 1 : 0, Duration = TimeSpan.FromMilliseconds(show ? 260 : 180), EasingFunction = new CubicEase { EasingMode = EasingMode.EaseOut } };
        Storyboard.SetTarget(a, e); Storyboard.SetTargetProperty(a, "Opacity");
        var sb = new Storyboard(); sb.Children.Add(a);
        if (!show) sb.Completed += (_, _) => { if (e.Opacity == 0) e.Visibility = Visibility.Collapsed; };
        sb.Begin();
    }
}

/// <summary>Плашка «играет музыка» — над списком чатов и под шапкой чата</summary>
public sealed class MiniPlayerBar : Grid
{
    readonly TextBlock title = T.Txt("", 13.5, bold: true, lines: 1);
    readonly TextBlock sub = T.Txt("", 12, T.Muted, lines: 1);
    readonly FontIcon playIc = T.Icon("", 14, T.A2);
    readonly Border fill = new() { Height = 2.5, HorizontalAlignment = HorizontalAlignment.Left, Background = T.A2, VerticalAlignment = VerticalAlignment.Bottom, CornerRadius = new CornerRadius(2) };
    readonly Grid g;

    public MiniPlayerBar(bool compact)
    {
        Margin = compact ? new Thickness(10, 6, 10, 4) : new Thickness(12, 0, 12, 8);
        CornerRadius = new CornerRadius(12); Background = T.Panel2; BorderBrush = T.Line; BorderThickness = new Thickness(1);
        Visibility = Visibility.Collapsed; Opacity = 0;
        var root = new Grid();
        g = new Grid { Padding = new Thickness(10, 6, 6, 6), ColumnSpacing = 10 };
        g.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        g.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        g.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        var cover = new Border { Width = 32, Height = 32, CornerRadius = new CornerRadius(8), Background = T.Accent, Child = T.Icon("", 14, T.White) };
        g.Children.Add(cover);
        var sp = new StackPanel { VerticalAlignment = VerticalAlignment.Center, Background = T.Transparent };
        sp.Children.Add(title); sp.Children.Add(sub);
        Grid.SetColumn(sp, 1); g.Children.Add(sp);
        var tools = new StackPanel { Orientation = Orientation.Horizontal };
        var pb = T.IconButton("", "Пауза / играть", Music.Toggle, 32, 14); pb.Content = playIc; tools.Children.Add(pb);
        tools.Children.Add(T.IconButton("", "Следующий", Music.Next, 32, 13));
        if (!compact) tools.Children.Add(T.IconButton("", "Закрыть", Music.Stop, 30, 11));
        Grid.SetColumn(tools, 2); g.Children.Add(tools);
        root.Children.Add(g); root.Children.Add(fill);
        Children.Add(root);
        sp.Tapped += (_, _) => ShowPlayer();
        cover.Tapped += (_, _) => ShowPlayer();
        Loaded += (_, _) => { Music.Changed += Upd; Music.Tick += OnTick; Upd(); };
        Unloaded += (_, _) => { Music.Changed -= Upd; Music.Tick -= OnTick; };
        SizeChanged += (_, _) => OnTick();
    }

    void Upd()
    {
        var t = Music.Current;
        Music.Fade(this, t != null);
        if (t == null) return;
        title.Text = t.Title;
        sub.Text = Music.Playing ? t.Artist : "На паузе";
        playIc.Glyph = Music.Playing ? "" : "";
        OnTick();
    }
    void OnTick() => fill.Width = Math.Max(0, ActualWidth * Music.Progress);

    void ShowPlayer()
    {
        var fl = new Flyout { Placement = FlyoutPlacementMode.Bottom };
        fl.Content = new PlayerPanel();
        fl.ShowAt(this);
    }
}

/// <summary>Плеер: обложка, перемотка, кнопки, очередь из этого чата</summary>
public sealed class PlayerPanel : StackPanel
{
    readonly TextBlock title = T.Txt("", 17, bold: true, lines: 1);
    readonly TextBlock artist = T.Txt("", 13, T.Muted, lines: 1);
    readonly Slider slider = new() { Minimum = 0, Maximum = 1000, Width = 300 };
    readonly TextBlock pos = T.Txt("0:00", 11.5, T.Muted), len = T.Txt("0:00", 11.5, T.Muted);
    readonly FontIcon playIc = T.Icon("", 22, T.White);
    readonly StackPanel queue = new() { Spacing = 2 };
    bool dragging;

    public PlayerPanel()
    {
        Width = 320; Spacing = 10;
        var cover = new Border { Width = 160, Height = 160, CornerRadius = new CornerRadius(22), Background = T.Accent, HorizontalAlignment = HorizontalAlignment.Center, Child = T.Icon("", 54, T.White) };
        Children.Add(cover);
        title.HorizontalAlignment = HorizontalAlignment.Center; artist.HorizontalAlignment = HorizontalAlignment.Center;
        Children.Add(title); Children.Add(artist);
        Children.Add(slider);
        var tl = new Grid(); tl.Children.Add(pos); len.HorizontalAlignment = HorizontalAlignment.Right; tl.Children.Add(len); Children.Add(tl);
        slider.PointerPressed += (_, _) => dragging = true;
        slider.AddHandler(PointerReleasedEvent, new Microsoft.UI.Xaml.Input.PointerEventHandler((_, _) => { dragging = false; Music.Seek(slider.Value / 1000); }), true);
        slider.ValueChanged += (_, e) => { if (dragging) pos.Text = Fmt.Duration(Music.Length * e.NewValue / 1000); };
        var btns = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 22, HorizontalAlignment = HorizontalAlignment.Center };
        btns.Children.Add(T.IconButton("", "Предыдущий", Music.Prev, 44, 18));
        var play = new Button { Width = 56, Height = 56, CornerRadius = new CornerRadius(28), Padding = new Thickness(0), Content = playIc, BorderThickness = new Thickness(0) };
        T.Fill(play, T.Accent); play.Click += (_, _) => Music.Toggle();
        btns.Children.Add(play);
        btns.Children.Add(T.IconButton("", "Следующий", Music.Next, 44, 18));
        Children.Add(btns);
        if (Music.Queue.Count > 1)
        {
            Children.Add(T.Txt("Из этого чата", 12.5, T.Muted, bold: true));
            Children.Add(new ScrollViewer { Content = queue, MaxHeight = 220 });
        }
        Loaded += (_, _) => { Music.Changed += Upd; Music.Tick += OnTick; Upd(); };
        Unloaded += (_, _) => { Music.Changed -= Upd; Music.Tick -= OnTick; };
    }

    void Upd()
    {
        var t = Music.Current; if (t == null) return;
        title.Text = t.Title; artist.Text = t.Artist;
        playIc.Glyph = Music.Playing ? "" : "";
        queue.Children.Clear();
        foreach (var q in Music.Queue)
        {
            var cur = q.Id == t.Id;
            var b = new Button { HorizontalAlignment = HorizontalAlignment.Stretch, HorizontalContentAlignment = HorizontalAlignment.Left, Background = T.Transparent, BorderThickness = new Thickness(0), Padding = new Thickness(8, 6, 8, 6) };
            var sp = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 8 };
            sp.Children.Add(T.Icon(cur ? "" : "", 12, cur ? T.A2 : T.Muted));
            sp.Children.Add(T.Txt(q.Title, 13, cur ? T.A2 : T.Text, bold: cur, lines: 1));
            b.Content = sp;
            var qq = q; b.Click += (_, _) => Music.Start(qq);
            queue.Children.Add(b);
        }
        OnTick();
    }
    void OnTick()
    {
        if (dragging) return;
        slider.Value = Music.Progress * 1000;
        pos.Text = Fmt.Duration(Music.Position); len.Text = Fmt.Duration(Music.Length);
    }
}

/// <summary>Пузырь аудиофайла в чате</summary>
public sealed class AudioView : Grid
{
    readonly Message m;
    readonly FontIcon ic = T.Icon("", 16, T.White);
    readonly ProgressBar bar = new() { Minimum = 0, Maximum = 1, Height = 3, Visibility = Visibility.Collapsed };
    public AudioView(Message m, bool mine, Brush fg)
    {
        this.m = m;
        ColumnSpacing = 10; MinWidth = 220;
        ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        var btn = new Button { Width = 44, Height = 44, CornerRadius = new CornerRadius(22), Padding = new Thickness(0), BorderThickness = new Thickness(0), Content = ic };
        T.Fill(btn, mine ? T.B(0x33FFFFFF) : T.Accent);
        btn.Click += (_, _) => { if (Music.Current?.Id == m.Id) Music.Toggle(); else Music.Play(m, Store.Msgs(m.ChatId)); };
        Children.Add(btn);
        var sp = new StackPanel { VerticalAlignment = VerticalAlignment.Center, Spacing = 4 };
        sp.Children.Add(T.Txt(Path.GetFileNameWithoutExtension(m.FileName), 14, fg, bold: true, lines: 1));
        bar.Foreground = mine ? T.White : T.A2; bar.Background = mine ? T.B(0x44FFFFFF) : T.B(0x33FFFFFF);
        sp.Children.Add(bar);
        sp.Children.Add(T.Txt(m.FileSize is long s ? Fmt.Size(s) : "Аудио", 12.5, mine ? T.OutMuted : T.Muted));
        SetColumn(sp, 1); Children.Add(sp);
        Loaded += (_, _) => { Music.Changed += Upd; Music.Tick += OnTick; Upd(); };
        Unloaded += (_, _) => { Music.Changed -= Upd; Music.Tick -= OnTick; };
    }
    void Upd()
    {
        var cur = Music.Current?.Id == m.Id;
        ic.Glyph = cur && Music.Playing ? "" : "";
        bar.Visibility = cur ? Visibility.Visible : Visibility.Collapsed;
        OnTick();
    }
    void OnTick() { if (Music.Current?.Id == m.Id) bar.Value = Music.Progress; }
}
