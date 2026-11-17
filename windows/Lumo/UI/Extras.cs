using Lumo.Core;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;

namespace Lumo.UI;

/// <summary>Над списком чатов: у собеседника сегодня день рождения</summary>
public sealed class BirthdayBar : Grid
{
    readonly TextBlock text = T.Txt("", 13.5, T.White, bold: true, lines: 1);
    readonly Action<string> open;
    List<ChatItem> today = new();

    public BirthdayBar(Action<string> open)
    {
        this.open = open;
        Margin = new Thickness(12, 0, 12, 8); CornerRadius = new CornerRadius(14); Padding = new Thickness(12, 9, 12, 9);
        Background = T.Grad(0xFFFF7AB6, 0xFFFF9D4D);
        Visibility = Visibility.Collapsed; Opacity = 0;
        var sp = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 10 };
        sp.Children.Add(T.Icon("", 18, T.White));
        var col = new StackPanel();
        col.Children.Add(text);
        col.Children.Add(T.Txt("Нажмите, чтобы подарить подарок", 11.5, T.B(0xE6FFFFFF)));
        sp.Children.Add(col);
        Children.Add(sp);
        Tapped += async (_, _) => { if (today.Count > 0 && today[0].PeerId is string pid) await Gifts.ShowShop(pid); };
        Loaded += (_, _) => { Store.ChatsChanged += Upd; Upd(); };
        Unloaded += (_, _) => Store.ChatsChanged -= Upd;
    }

    void Upd()
    {
        var d = DateTime.Now;
        today = Store.Chats.Where(c => c.IsPrivate && c.PeerId != null && !c.PeerBot && Store.Profiles.TryGetValue(c.PeerId, out var p) && IsToday(p.Birthday, d)).ToList();
        if (today.Count > 0)
            text.Text = today.Count == 1 ? "У " + today[0].DisplayName + " день рождения" : "День рождения: " + today[0].DisplayName + " и ещё " + (today.Count - 1);
        Music.Fade(this, today.Count > 0);
    }

    static bool IsToday(string? b, DateTime d)
    {
        if (string.IsNullOrEmpty(b) || b.Length < 10) return false;
        var p = b[..10].Split('-');
        return p.Length == 3 && int.TryParse(p[1], out var m) && int.TryParse(p[2], out var day) && m == d.Month && day == d.Day;
    }
}

/// <summary>Звонки: недавние, пропущенные, перезвонить</summary>
public static class CallsSheet
{
    public static async Task Show(Action<string> openChat)
    {
        var list = new StackPanel { Spacing = 2 };
        var filter = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 6, Margin = new Thickness(0, 0, 0, 8) };
        var all = new ToggleButton2("Все", true); var missed = new ToggleButton2("Пропущенные", false);
        filter.Children.Add(all); filter.Children.Add(missed);
        var root = new StackPanel(); root.Children.Add(filter); root.Children.Add(list);
        var ring = new ProgressRing { IsActive = true, Width = 26, Height = 26, Margin = new Thickness(20) };
        list.Children.Add(ring);
        var sheet = new Sheet { Title = "Звонки", Content = root, Width = 460 };
        List<Message> calls = new();
        void Render()
        {
            list.Children.Clear();
            var me = Store.MyId;
            bool Miss(Message m) => m.SenderId != me && m.MetaStatus is not ("ended" or "rejected");
            var rows = calls.Where(m => !missed.On || Miss(m)).Select(m => (m, c: Store.Chat(m.ChatId))).Where(x => x.c is { IsPrivate: true }).ToList();
            if (rows.Count == 0) { list.Children.Add(T.Txt(missed.On ? "Пропущенных звонков нет" : "Звонков пока нет", 14, T.Muted)); return; }
            // подряд идущие звонки одному человеку за день — одной строкой
            var groups = new List<List<(Message m, ChatItem? c)>>();
            foreach (var r in rows)
            {
                var last = groups.LastOrDefault();
                if (last != null && last[0].c!.Id == r.c!.Id && last[0].m.CreatedAt.LocalDateTime.Date == r.m.CreatedAt.LocalDateTime.Date) last.Add(r);
                else groups.Add(new() { r });
            }
            foreach (var g in groups)
            {
                var (m, c) = g[0];
                string Kind(Message x) => x.SenderId == me ? (x.MetaStatus == "ended" ? "Исходящий" : "Отменённый") : x.MetaStatus == "ended" ? "Входящий" : x.MetaStatus == "rejected" ? "Отклонённый" : "Пропущенный";
                var label = string.Join(", ", g.Select(x => Kind(x.m)).Distinct()) + (g.Count > 1 ? $" ({g.Count})" : m.Duration > 0 ? " · " + Fmt.Duration(m.Duration) : "");
                var row = new Grid { ColumnSpacing = 10, Padding = new Thickness(6, 6, 6, 6) };
                row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
                row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
                row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
                var av = new AvatarView(40); av.Set(c!.DisplayName, c.DisplayAvatar, c.DisplayColor);
                row.Children.Add(av);
                var sp = new StackPanel { VerticalAlignment = VerticalAlignment.Center };
                sp.Children.Add(T.Txt(c.DisplayName, 14.5, Miss(m) ? T.B(0xFFFF5A6E) : T.Text, bold: true, lines: 1));
                sp.Children.Add(T.Txt(label + " · " + Fmt.ListTime(m.CreatedAt), 12, T.Muted, lines: 1));
                Grid.SetColumn(sp, 1); row.Children.Add(sp);
                var tools = new StackPanel { Orientation = Orientation.Horizontal };
                var cc = c; var vid = m.IsVideoCall;
                tools.Children.Add(T.IconButton(vid ? "" : "", "Перезвонить", () => { sheet.Hide(); CallHost.I?.Start(cc, vid); }));
                tools.Children.Add(T.IconButton("", "Открыть чат", () => { sheet.Hide(); openChat(cc.Id); }));
                Grid.SetColumn(tools, 2); row.Children.Add(tools);
                list.Children.Add(row);
            }
        }
        all.Click += () => { all.On = true; missed.On = false; Render(); };
        missed.Click += () => { all.On = false; missed.On = true; Render(); };
        _ = Task.Run(async () =>
        {
            try
            {
                var rows = await Api.Select("lm_messages", new() { ["select"] = "*", ["kind"] = "eq.call", ["order"] = "id.desc", ["limit"] = "100" });
                var ms = rows.Select(Message.From).ToList();
                list.DispatcherQueue.TryEnqueue(() => { calls = ms; Render(); });
            }
            catch { list.DispatcherQueue.TryEnqueue(() => { list.Children.Clear(); list.Children.Add(T.Txt("Не удалось загрузить звонки", 14, T.Muted)); }); }
        });
        await sheet.ShowAsync();
    }
}

/// <summary>Кнопка-переключатель в виде «пилюли»</summary>
public sealed class ToggleButton2 : Button
{
    bool on;
    public new event Action? Click;
    public bool On { get => on; set { on = value; T.Fill(this, on ? T.Accent : T.Panel2); } }
    public ToggleButton2(string text, bool on)
    {
        Content = T.Txt(text, 13, T.White, bold: true); CornerRadius = new CornerRadius(16); Padding = new Thickness(14, 6, 14, 6); BorderThickness = new Thickness(0);
        On = on;
        base.Click += (_, _) => Click?.Invoke();
    }
}
