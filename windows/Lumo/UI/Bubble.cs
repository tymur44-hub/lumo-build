using System.Text;
using System.Text.RegularExpressions;
using Lumo.Core;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Controls.Primitives;
using Microsoft.UI.Xaml.Documents;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Media.Imaging;

namespace Lumo.UI;

/// <summary>Одно сообщение в переписке</summary>
public sealed class BubbleView : Grid
{
    public Message M { get; private set; }
    public string Sig { get; }
    readonly ChatView owner;
    readonly bool mine;
    readonly StackPanel reacts = new() { Orientation = Orientation.Horizontal, Spacing = 4, Margin = new Thickness(0, 4, 0, 0) };
    readonly CheckMark check = new(11);
    readonly Border? box;

    public static string Signature(Message m) => $"{m.Id}|{m.Body}|{m.EditedAt?.Ticks}|{m.Pending}|{m.MediaUrl}|{m.Meta.ToJsonString().GetHashCode()}";

    public BubbleView(Message m, ChatView owner, bool showName, bool tail)
    {
        M = m; this.owner = owner; Sig = Signature(m);
        mine = m.SenderId == Store.MyId && m.SenderId != null;
        var chat = Store.Chat(m.ChatId);
        if (chat?.IsChannel == true && chat.CanPost) mine = m.SenderId == Store.MyId;
        Padding = new Thickness(16, tail ? 6 : 1, 16, 1);

        if (m.Kind == "system")
        {
            var pill = new Border { Background = T.B(0x26FFFFFF), CornerRadius = new CornerRadius(12), Padding = new Thickness(12, 5, 12, 5), HorizontalAlignment = HorizontalAlignment.Center, Margin = new Thickness(0, 6, 0, 6) };
            var t = T.Txt(m.Body ?? "", 12.5, T.Text); t.TextAlignment = TextAlignment.Center;
            pill.Child = t;
            Children.Add(pill);
            return;
        }

        var col = new StackPanel { HorizontalAlignment = mine ? HorizontalAlignment.Right : HorizontalAlignment.Left, MaxWidth = 520 };
        var big = m.Kind == "text" && IsEmojiOnly(m.Body);
        var bare = m.Kind is "sticker" or "video_note" or "game" or "dice" || big;
        var inner = new StackPanel { Spacing = 4 };

        if (showName && !mine && chat != null && !chat.IsPrivate && !chat.IsChannel && m.SenderId != null)
        {
            var color = Store.Profiles.GetValueOrDefault(m.SenderId)?.Color ?? m.SenderId.GetHashCode();
            inner.Children.Add(T.Txt(Store.DisplayName(m.SenderId), 13, T.NameBrush(color), bold: true, lines: 1));
        }
        if (!string.IsNullOrEmpty(m.ForwardedFrom))
            inner.Children.Add(T.Txt("Переслано от " + m.ForwardedFrom, 12.5, mine ? T.OutMuted : T.A2, lines: 1));
        if (m.ReplyTo is int rid) inner.Children.Add(ReplyQuote(rid));

        inner.Children.Add(Content(m, big));
        var btns = BotButtons(m);
        if (btns != null) inner.Children.Add(btns);

        // время и галочки
        var foot = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 4, HorizontalAlignment = HorizontalAlignment.Right };
        var fg = mine && !bare ? T.OutMuted : T.Muted;
        if (m.Enc) { var l = T.Icon("\uE72E", 10, fg); l.VerticalAlignment = VerticalAlignment.Center; ToolTipService.SetToolTip(l, "Сквозное шифрование"); foot.Children.Add(l); }
        if (m.EditedAt != null) foot.Children.Add(T.Txt("изм.", 11, fg));
        foot.Children.Add(T.Txt(Fmt.Clock(m.CreatedAt), 11, fg));
        if (mine) foot.Children.Add(check);
        inner.Children.Add(foot);

        if (bare)
        {
            col.Children.Add(inner);
            foot.Padding = new Thickness(8, 2, 8, 2);
            box = null;
        }
        else
        {
            box = new Border
            {
                Background = mine ? T.Out : T.Bubble, Padding = new Thickness(12, 8, 12, 6), Child = inner,
                CornerRadius = mine ? new CornerRadius(18, 18, tail ? 6 : 18, 18) : new CornerRadius(18, 18, 18, tail ? 6 : 18),
                HorizontalAlignment = mine ? HorizontalAlignment.Right : HorizontalAlignment.Left,
            };
            col.Children.Add(box);
        }
        reacts.HorizontalAlignment = mine ? HorizontalAlignment.Right : HorizontalAlignment.Left;
        col.Children.Add(reacts);
        Children.Add(col);
        UpdateStatus();
        UpdateReactions();

        col.RightTapped += (_, e) => { e.Handled = true; owner.Menu(this, col, e.GetPosition(col)); };
        col.DoubleTapped += (_, e) => { e.Handled = true; owner.Reply(M); };
    }

    static bool IsEmojiOnly(string? s)
    {
        if (string.IsNullOrWhiteSpace(s) || s.Length > 16) return false;
        foreach (var r in s.EnumerateRunes())
        {
            if (Rune.IsLetterOrDigit(r) || Rune.IsPunctuation(r)) return false;
            if (r.Value < 0x2000 && !Rune.IsWhiteSpace(r)) return false;
        }
        return true;
    }

    FrameworkElement ReplyQuote(int rid)
    {
        var r = Store.Find(rid, M.ChatId);
        var g = new Grid { ColumnSpacing = 8, Background = mine ? T.B(0x22FFFFFF) : T.B(0x147C5CFF), CornerRadius = new CornerRadius(8), Padding = new Thickness(0, 4, 8, 4) };
        g.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(3) });
        g.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        g.Children.Add(new Border { Background = mine ? T.White : T.A1, CornerRadius = new CornerRadius(2) });
        var sp = new StackPanel();
        sp.Children.Add(T.Txt(r == null ? "Сообщение" : Store.DisplayName(r.SenderId), 12.5, mine ? T.White : T.A2, bold: true, lines: 1));
        sp.Children.Add(T.Txt(r == null ? "…" : r.Preview.Replace('\n', ' '), 12.5, mine ? T.OutMuted : T.Muted, lines: 1));
        Grid.SetColumn(sp, 1); g.Children.Add(sp);
        g.Tapped += (_, e) => { e.Handled = true; owner.JumpTo(rid); };
        return g;
    }

    FrameworkElement Content(Message m, bool big)
    {
        var fg = mine ? T.White : T.Text;
        switch (m.Kind)
        {
            case "text":
                if (big) return T.Txt(m.Body ?? "", 44);
                return RichText(m.Body ?? "", fg);
            case "image":
            case "video":
            {
                var sp = new StackPanel { Spacing = 6 };
                sp.Children.Add(MediaFrame(m));
                if (!string.IsNullOrEmpty(m.Body)) sp.Children.Add(RichText(m.Body, fg));
                return sp;
            }
            case "sticker":
            {
                var img = new Image { Width = 160, Height = 160, Stretch = Stretch.Uniform, Source = T.Bitmap(m.MediaUrl, 320) };
                return img;
            }
            case "video_note":
            {
                var g = new Grid { Width = 220, Height = 220 };
                g.Children.Add(new Microsoft.UI.Xaml.Shapes.Ellipse { Fill = T.Bubble });
                var pl = new Border { Width = 56, Height = 56, CornerRadius = new CornerRadius(28), Background = T.B(0x99000000), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center, Child = T.Icon("\uE768", 22, T.White) };
                g.Children.Add(pl);
                var d = T.Txt(Fmt.Duration(m.Duration), 12, T.White); d.HorizontalAlignment = HorizontalAlignment.Center; d.VerticalAlignment = VerticalAlignment.Bottom; d.Margin = new Thickness(0, 0, 0, 14);
                g.Children.Add(d);
                g.Tapped += (_, e) => { e.Handled = true; owner.ShowVideo(m, true); };
                return g;
            }
            case "voice": return new VoiceView(m, mine);
            case "game": return GameCard(m);
            case "dice": return ThrowCard(m);
            case "file": return FileView(m, fg);
            case "call":
            {
                var sp = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 10 };
                var mineCall = m.SenderId == Store.MyId;
                var st = m.MetaStatus;
                var missed = st is "missed" or "rejected" or "busy" || (st == null && !mineCall);
                var ic = T.Icon(m.IsVideoCall ? "\uE714" : "\uE717", 18, missed ? T.Danger : fg); ic.VerticalAlignment = VerticalAlignment.Center;
                sp.Children.Add(ic);
                var tx = new StackPanel();
                tx.Children.Add(T.Txt((mineCall ? "Исходящий" : "Входящий") + (m.IsVideoCall ? " видеозвонок" : " звонок"), 14, fg, bold: true));
                var dur = m.Meta.Dbl("dur") ?? m.Meta.Dbl("duration");
                tx.Children.Add(T.Txt(dur is > 0 ? Fmt.Duration(dur.Value) : st switch { "rejected" => "Отклонён", "missed" => "Пропущен", "busy" => "Занято", _ => "" }, 12.5, mine ? T.OutMuted : T.Muted));
                sp.Children.Add(tx);
                ToolTipService.SetToolTip(sp, "Позвонить ещё раз");
                sp.Background = T.Transparent;
                sp.Tapped += (_, e) => { e.Handled = true; var c = Store.Chat(m.ChatId); if (c != null && c.IsPrivate) CallHost.I?.Start(c, m.IsVideoCall); };
                return sp;
            }
            default:
            {
                var t = T.Txt(Message.PreviewText(m.Kind, m.Body), 14, fg);
                t.FontStyle = Windows.UI.Text.FontStyle.Italic;
                var sp = new StackPanel { Spacing = 2 };
                sp.Children.Add(t);
                if (m.Kind is "game" or "poll" or "capsule")
                    sp.Children.Add(T.Txt("Откройте на телефоне — на компьютере появится в следующем обновлении", 11.5, mine ? T.OutMuted : T.Muted));
                return sp;
            }
        }
    }

    static readonly Dictionary<string, string> gameTitles = new() { ["ttt"] = "Крестики-нолики", ["checkers"] = "Шашки", ["sea"] = "Морской бой", ["chess"] = "Шахматы" };
    static readonly Dictionary<string, (uint, uint)> gameColors = new() { ["ttt"] = (0xFF22C1FF, 0xFF3A7BFF), ["checkers"] = (0xFFA7743F, 0xFF6B4426), ["sea"] = (0xFF2BB3FF, 0xFF1460C8), ["chess"] = (0xFF4A4F5C, 0xFF16181D) };
    static readonly Dictionary<string, string> gameGlyphs = new() { ["ttt"] = "\uE711", ["checkers"] = "\uEA3A", ["sea"] = "\uE804", ["chess"] = "\uE7FC" };

    public static FrameworkElement GameIcon(string k, double size = 46) => Art.Game(k, size);

    /// <summary>Карточка игры вдвоём (как на телефонах)</summary>
    FrameworkElement GameCard(Message m)
    {
        var mt = m.Meta; var k = mt.Str("g") ?? "ttt"; var st = mt.Str("st") ?? "invite"; var me = Store.MyId;
        var p1 = mt.Str("p1"); var p2 = mt.Str("p2");
        var player = me != null && (me == p1 || me == p2);
        var btn = st switch
        {
            "invite" => p1 != me && m.SenderId != me ? "Принять" : "Открыть",
            "active" or "setup" => player ? "Играть" : "Смотреть",
            _ => "Посмотреть",
        };
        var status = st switch
        {
            "invite" => p1 == me ? "Ждём соперника" : "Приглашение сыграть",
            "setup" => "Расстановка кораблей",
            "active" => "Идёт игра",
            "declined" => "Приглашение отклонено",
            "canceled" => "Игра отменена",
            _ => mt.Str("winner") is { } w ? (w == me ? "Вы победили" : "Победил(а) " + (mt.Str("wn") ?? "")) : "Ничья",
        };
        var fg = mine ? T.White : T.Text;
        var card = new StackPanel { Width = 280, Spacing = 8, Padding = new Thickness(12), CornerRadius = new CornerRadius(18), Background = mine ? T.Out : T.Bubble };
        var top = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 11 };
        top.Children.Add(GameIcon(k));
        var tt = new StackPanel { VerticalAlignment = VerticalAlignment.Center };
        tt.Children.Add(T.Txt(gameTitles.GetValueOrDefault(k, "Игра"), 15.5, fg, bold: true));
        tt.Children.Add(T.Txt(status, 13, mine ? T.OutMuted : T.Muted));
        top.Children.Add(tt);
        card.Children.Add(top);
        var vs = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 6 };
        vs.Children.Add(T.Txt(mt.Str("p1n") ?? Store.DisplayName(m.SenderId), 13.5, fg, bold: true, lines: 1));
        vs.Children.Add(T.Txt("VS", 11, mine ? T.OutMuted : T.Muted, bold: true));
        vs.Children.Add(T.Txt(p2 == null ? "ждём соперника" : mt.Str("p2n") ?? "", 13.5, fg, bold: p2 != null, lines: 1));
        var stake = mt.Int("stake") ?? 0;
        if (stake > 0) vs.Children.Add(T.Txt("  " + stake + " люм.", 13, T.B(0xFFF5B942), bold: true));
        card.Children.Add(vs);
        var b = new Button { Content = new TextBlock { Text = btn, FontWeight = Microsoft.UI.Text.FontWeights.Bold, Foreground = btn == "Посмотреть" && !mine ? T.Text : T.White },
            HorizontalAlignment = HorizontalAlignment.Stretch, Height = 40, CornerRadius = new CornerRadius(12), BorderThickness = new Thickness(0) };
        T.Fill(b, mine ? T.B(0x2EFFFFFF) : btn == "Посмотреть" ? T.Panel2 : T.Accent);
        b.Click += (_, _) => { var id = mt.Str("game"); if (id != null) WebOverlay.I?.OpenGame(id); };
        card.Children.Add(b);
        return card;
    }

    /// <summary>Бросок в чат: кубик, дартс, баскетбол, футбол, монетка</summary>
    FrameworkElement ThrowCard(Message m)
    {
        var k = m.Meta.Str("g") ?? "dice"; var v = m.Meta.Int("v") ?? 1;
        var (name, label) = k switch
        {
            "dice" => ("Кубик", "Выпало " + v),
            "darts" => ("Дартс", v == 6 ? "В яблочко!" : v == 1 ? "Мимо" : "Очков: " + v),
            "basket" => ("Баскетбол", v >= 4 ? "Попал!" : "Мимо"),
            "football" => ("Футбол", v >= 3 ? "Гол!" : "Мимо"),
            _ => ("Монетка", v == 1 ? "Орёл" : "Решка"),
        };
        var card = new StackPanel { Width = 170, Spacing = 6, Padding = new Thickness(12), CornerRadius = new CornerRadius(18), Background = mine ? T.Out : T.Bubble, HorizontalAlignment = HorizontalAlignment.Left };
        var face = Art.Throw(k, v, 72); face.HorizontalAlignment = HorizontalAlignment.Center;
        card.Children.Add(face);
        var l1 = T.Txt(name, 12.5, mine ? T.OutMuted : T.Muted); l1.HorizontalAlignment = HorizontalAlignment.Center; card.Children.Add(l1);
        var l2 = T.Txt(label, 15, mine ? T.White : T.Text, bold: true); l2.HorizontalAlignment = HorizontalAlignment.Center; card.Children.Add(l2);
        return card;
    }

    /// <summary>Кнопки под сообщением бота: строки по [текст, data | url | web_app]</summary>
    FrameworkElement? BotButtons(Message m)
    {
        if (m.Meta.Arr("buttons") is not { Count: > 0 } rows) return null;
        var sp = new StackPanel { Spacing = 4, Margin = new Thickness(0, 4, 0, 0) };
        foreach (var row in rows.OfType<System.Text.Json.Nodes.JsonArray>())
        {
            var g = new Grid { ColumnSpacing = 4 };
            int i = 0;
            foreach (var b in row.OfType<System.Text.Json.Nodes.JsonObject>())
            {
                g.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
                var text = b.Str("text") ?? ""; var data = b.Str("data"); var url = b.Str("url"); var web = b.Str("web_app");
                var sp2 = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 6, HorizontalAlignment = HorizontalAlignment.Center };
                if (url != null || web != null) sp2.Children.Add(T.Icon(web != null ? "\uE8A7" : "\uE71B", 11, mine ? T.White : T.A2));
                sp2.Children.Add(new TextBlock { Text = text, FontSize = 13, Foreground = mine ? T.White : T.Text, TextTrimming = TextTrimming.CharacterEllipsis });
                var btn = new Button { Content = sp2, HorizontalAlignment = HorizontalAlignment.Stretch, Height = 34, CornerRadius = new CornerRadius(10), BorderThickness = new Thickness(0) };
                T.Fill(btn, mine ? T.B(0x2EFFFFFF) : T.B(0x22FFFFFF), mine ? T.B(0x44FFFFFF) : T.B(0x33FFFFFF));
                btn.Click += async (_, _) =>
                {
                    if (web != null && m.SenderId != null) { WebOverlay.I?.OpenMini(m.SenderId, web); return; }
                    if (url != null) { try { System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo(url) { UseShellExecute = true }); } catch { } return; }
                    if (data == null) return;
                    try
                    {
                        var r = await Api.Raw("POST", "/functions/v1/lumo-bots/cb", body: J.O(("message_id", m.Id), ("data", data)));
                        var t = r.Str("toast"); if (t != null) Store.Say(t);
                    }
                    catch { Store.Say("Не удалось выполнить действие"); }
                };
                Grid.SetColumn(btn, i++);
                g.Children.Add(btn);
            }
            sp.Children.Add(g);
        }
        return sp;
    }

    static readonly Regex linkRx = new(@"(https?://[^\s<>""]+)|(\*\*(.+?)\*\*)|(@[A-Za-z0-9_]{3,32})", RegexOptions.Compiled);

    public static RichTextBlock RichText(string text, Brush fg)
    {
        var rtb = new RichTextBlock { IsTextSelectionEnabled = true, TextWrapping = TextWrapping.Wrap, FontSize = 14.5, Foreground = fg };
        var p = new Paragraph();
        int pos = 0;
        foreach (Match mt in linkRx.Matches(text))
        {
            if (mt.Index > pos) p.Inlines.Add(new Run { Text = text[pos..mt.Index] });
            if (mt.Groups[1].Success && Uri.TryCreate(mt.Value.TrimEnd('.', ',', ')', '!', '?'), UriKind.Absolute, out var u))
            {
                var h = new Hyperlink { NavigateUri = u, Foreground = T.A2 };
                h.Inlines.Add(new Run { Text = mt.Value });
                p.Inlines.Add(h);
            }
            else if (mt.Groups[2].Success) p.Inlines.Add(new Run { Text = mt.Groups[3].Value, FontWeight = Microsoft.UI.Text.FontWeights.Bold });
            else p.Inlines.Add(new Run { Text = mt.Value, Foreground = T.A2 });
            pos = mt.Index + mt.Length;
        }
        if (pos < text.Length) p.Inlines.Add(new Run { Text = text[pos..] });
        rtb.Blocks.Add(p);
        return rtb;
    }

    FrameworkElement MediaFrame(Message m)
    {
        double w = m.Width ?? 0, h = m.Height ?? 0;
        double maxW = 360, maxH = 400;
        if (w <= 0 || h <= 0) { w = 300; h = m.Kind == "video" ? 200 : 260; }
        var k = Math.Min(maxW / w, maxH / h); if (k > 1) k = Math.Min(k, 1.0);
        w = Math.Max(120, w * k); h = Math.Max(90, h * k);
        var g = new Grid { Width = w, Height = h, CornerRadius = new CornerRadius(12), Background = T.B(0x33000000) };
        if (m.Kind == "image")
        {
            BitmapImage? src = null;
            if (m.MediaUrl != null) src = T.Bitmap(m.MediaUrl, (int)(w * 2));
            else if (m.LocalPath != null) try { src = new BitmapImage(new Uri(m.LocalPath)); } catch { }
            g.Children.Add(new Image { Source = src, Stretch = Stretch.UniformToFill });
            g.Tapped += (_, e) => { e.Handled = true; owner.ShowImage(m); };
        }
        else
        {
            var thumb = m.Meta.Str("thumb") ?? m.Meta.Str("poster");
            if (thumb != null) g.Children.Add(new Image { Source = T.Bitmap(thumb, (int)(w * 2)), Stretch = Stretch.UniformToFill });
            var pl = new Border { Width = 54, Height = 54, CornerRadius = new CornerRadius(27), Background = T.B(0x99000000), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center, Child = T.Icon("\uE768", 22, T.White) };
            g.Children.Add(pl);
            if (m.Duration > 0)
            {
                var d = new Border { Background = T.B(0x99000000), CornerRadius = new CornerRadius(8), Padding = new Thickness(6, 2, 6, 2), Margin = new Thickness(8), HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top, Child = T.Txt(Fmt.Duration(m.Duration), 11.5, T.White) };
                g.Children.Add(d);
            }
            g.Tapped += (_, e) => { e.Handled = true; owner.ShowVideo(m, false); };
        }
        if (m.Pending) g.Children.Add(new ProgressRing { IsActive = true, Width = 34, Height = 34, Foreground = T.White });
        return g;
    }

    FrameworkElement FileView(Message m, Brush fg)
    {
        var g = new Grid { ColumnSpacing = 12, MinWidth = 220 };
        g.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        g.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        var icBox = new Grid { Width = 44, Height = 44 };
        icBox.Children.Add(new Border { CornerRadius = new CornerRadius(22), Background = mine ? T.B(0x33FFFFFF) : T.Accent });
        var ic = T.Icon(m.Pending ? "\uE898" : "\uE896", 18, T.White); ic.HorizontalAlignment = HorizontalAlignment.Center; ic.VerticalAlignment = VerticalAlignment.Center;
        icBox.Children.Add(ic);
        var ring = new ProgressRing { IsActive = false, Width = 44, Height = 44, Foreground = T.White, Visibility = Visibility.Collapsed, IsIndeterminate = false, Maximum = 1 };
        icBox.Children.Add(ring);
        g.Children.Add(icBox);
        var sp = new StackPanel { VerticalAlignment = VerticalAlignment.Center };
        sp.Children.Add(T.Txt(m.FileName, 14, fg, bold: true, lines: 1));
        var size = T.Txt(m.FileSize is long s ? Fmt.Size(s) : "", 12.5, mine ? T.OutMuted : T.Muted);
        sp.Children.Add(size);
        Grid.SetColumn(sp, 1); g.Children.Add(sp);
        g.Tapped += async (_, e) =>
        {
            e.Handled = true;
            if (m.MediaUrl == null || ring.Visibility == Visibility.Visible) return;
            ring.Visibility = Visibility.Visible; ring.IsActive = true; ic.Visibility = Visibility.Collapsed;
            var prog = new Progress<double>(v => ring.Value = v);
            var path = await Media.Cached(m.MediaUrl, m.FileName, m.Parts, prog);
            ring.Visibility = Visibility.Collapsed; ring.IsActive = false; ic.Visibility = Visibility.Visible;
            if (path == null) { Store.Say("Не удалось скачать файл"); return; }
            try { System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo(path) { UseShellExecute = true }); }
            catch { Store.Say("Файл скачан: " + path); }
        };
        return g;
    }

    public void UpdateStatus()
    {
        if (!mine) return;
        var c = Store.Chat(M.ChatId);
        var bare = box == null;
        var fg = bare ? T.A2 : T.OutMuted;
        int st = M.Pending ? 1 : c?.IsChannel == true ? 0 : c?.OthersReadAt != null && c.OthersReadAt >= M.CreatedAt ? 3 : 2;
        check.Set(st, fg);
    }

    public void UpdateReactions()
    {
        reacts.Children.Clear();
        var list = Store.Reactions.GetValueOrDefault(M.Id);
        if (list == null || list.Count == 0) { reacts.Visibility = Visibility.Collapsed; return; }
        reacts.Visibility = Visibility.Visible;
        foreach (var g in list.GroupBy(r => r.Emoji))
        {
            var me = g.Any(r => r.UserId == Store.MyId);
            var b = new Button
            {
                Padding = new Thickness(8, 2, 8, 2), MinHeight = 0, CornerRadius = new CornerRadius(12), BorderThickness = new Thickness(me ? 1.5 : 0),
                BorderBrush = T.A2,
            };
            T.Fill(b, me ? T.B(0x407C5CFF) : T.B(0x22FFFFFF), me ? T.B(0x557C5CFF) : T.B(0x33FFFFFF));
            var sp = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 5 };
            sp.Children.Add(new TextBlock { Text = g.Key, FontSize = 15 });
            sp.Children.Add(new TextBlock { Text = g.Count().ToString(), FontSize = 12.5, Foreground = T.Text, VerticalAlignment = VerticalAlignment.Center });
            b.Content = sp;
            var who = string.Join(", ", g.Select(r => Store.DisplayName(r.UserId)).Take(8));
            ToolTipService.SetToolTip(b, who);
            var emoji = g.Key;
            b.Click += async (_, _) => await Store.React(M, emoji);
            reacts.Children.Add(b);
        }
    }
}

/// <summary>Голосовое сообщение: кнопка, полоса прослушивания, длительность</summary>
public sealed class VoiceView : Grid
{
    static Windows.Media.Playback.MediaPlayer? player;
    static VoiceView? playing;
    readonly Message m;
    readonly FontIcon icon;
    readonly ProgressBar bar = new() { Minimum = 0, Maximum = 1, Height = 4, MinWidth = 150, VerticalAlignment = VerticalAlignment.Center };
    readonly TextBlock time;

    public VoiceView(Message m, bool mine)
    {
        this.m = m;
        ColumnSpacing = 10;
        ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        var btn = new Button { Width = 42, Height = 42, CornerRadius = new CornerRadius(21), Padding = new Thickness(0), BorderThickness = new Thickness(0) };
        T.Fill(btn, mine ? T.B(0x33FFFFFF) : T.Accent);
        icon = T.Icon("\uE768", 16, T.White);
        btn.Content = icon;
        btn.Click += (_, _) => Toggle();
        Children.Add(btn);
        var sp = new StackPanel { VerticalAlignment = VerticalAlignment.Center, Spacing = 6, MinWidth = 160 };
        bar.Foreground = mine ? T.White : T.A2;
        bar.Background = mine ? T.B(0x44FFFFFF) : T.B(0x33FFFFFF);
        sp.Children.Add(bar);
        time = T.Txt(Fmt.Duration(m.Duration), 12, mine ? T.OutMuted : T.Muted);
        sp.Children.Add(time);
        Grid.SetColumn(sp, 1); Children.Add(sp);
    }

    void Toggle()
    {
        if (m.MediaUrl == null) return;
        if (player == null)
        {
            player = new Windows.Media.Playback.MediaPlayer();
            player.PlaybackSession.PositionChanged += (s, _) =>
            {
                var v = playing; if (v == null) return;
                var pos = s.Position.TotalSeconds; var dur = s.NaturalDuration.TotalSeconds;
                v.DispatcherQueue?.TryEnqueue(() => { v.bar.Value = dur > 0 ? pos / dur : 0; v.time.Text = Fmt.Duration(pos) + " / " + Fmt.Duration(dur > 0 ? dur : v.m.Duration); });
            };
            player.MediaEnded += (_, _) => { var v = playing; v?.DispatcherQueue?.TryEnqueue(() => { v.icon.Glyph = "\uE768"; v.bar.Value = 0; v.time.Text = Fmt.Duration(v.m.Duration); }); playing = null; };
        }
        if (playing == this)
        {
            if (player.PlaybackSession.PlaybackState == Windows.Media.Playback.MediaPlaybackState.Playing) { player.Pause(); icon.Glyph = "\uE768"; }
            else { player.Play(); icon.Glyph = "\uE769"; }
            return;
        }
        if (playing != null) { playing.icon.Glyph = "\uE768"; playing.bar.Value = 0; }
        playing = this;
        player.Source = Windows.Media.Core.MediaSource.CreateFromUri(new Uri(Net.Px(m.MediaUrl)!));
        player.Play();
        icon.Glyph = "\uE769";
    }
}
