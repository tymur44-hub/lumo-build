using Lumo.Core;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;

namespace Lumo.UI;

/// <summary>Главный экран: слева список чатов и поиск, справа открытый чат</summary>
public sealed class ShellView : Grid
{
    readonly MainWindow win;
    readonly AvatarView meAv = new(34);
    readonly TextBox search = new() { PlaceholderText = "Поиск", Height = 36, CornerRadius = new CornerRadius(18) };
    readonly ListView list = new() { SelectionMode = ListViewSelectionMode.Single, IsItemClickEnabled = true, Padding = new Thickness(6, 0, 6, 8) };
    readonly ListView results = new() { SelectionMode = ListViewSelectionMode.None, IsItemClickEnabled = true, Visibility = Visibility.Collapsed, Padding = new Thickness(6, 0, 6, 8) };
    readonly Grid right = new() { Background = T.ChatBg };
    readonly StackPanel empty;
    readonly ProgressRing loading = new() { IsActive = true, Width = 28, Height = 28, Margin = new Thickness(0, 30, 0, 0) };
    readonly Dictionary<string, ChatRow> rows = new();
    ChatView? chat;
    string? openId;

    public ShellView(MainWindow w)
    {
        win = w;
        ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(370), MinWidth = 300 });
        ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

        // ----- левая колонка -----
        var left = new Grid { Background = T.Panel, BorderBrush = T.Line, BorderThickness = new Thickness(0, 0, 1, 0) };
        left.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        left.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        left.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });

        var head = new Grid { Padding = new Thickness(14, 4, 10, 8) };
        head.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        head.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        head.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        var meBtn = new Button { Content = meAv, Padding = new Thickness(0), Background = T.Transparent, BorderThickness = new Thickness(0), CornerRadius = new CornerRadius(17) };
        ToolTipService.SetToolTip(meBtn, "Мой профиль и настройки");
        meBtn.Click += async (_, _) => await Dialogs.Settings(win);
        head.Children.Add(meBtn);
        var title = T.Txt("Чаты", 20, bold: true); title.VerticalAlignment = VerticalAlignment.Center; title.Margin = new Thickness(12, 0, 0, 0);
        Grid.SetColumn(title, 1); head.Children.Add(title);
        var tools = new StackPanel { Orientation = Orientation.Horizontal };
        tools.Children.Add(T.IconButton("\uE710", "Новый чат: найдите человека по юзернейму", () => { search.Focus(FocusState.Programmatic); win.ShowToast("Введите @юзернейм в поиске"); }));
        tools.Children.Add(T.IconButton("\uE713", "Настройки", async () => await Dialogs.Settings(win)));
        Grid.SetColumn(tools, 2); head.Children.Add(tools);
        left.Children.Add(head);

        search.Margin = new Thickness(12, 0, 12, 8);
        Grid.SetRow(search, 1); left.Children.Add(search);

        var listHost = new Grid();
        listHost.Children.Add(list); listHost.Children.Add(results);
        loading.HorizontalAlignment = HorizontalAlignment.Center; loading.VerticalAlignment = VerticalAlignment.Top;
        listHost.Children.Add(loading);
        Grid.SetRow(listHost, 2); left.Children.Add(listHost);
        Children.Add(left);

        // ----- правая колонка -----
        empty = new StackPanel { HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center, Spacing = 10 };
        var ic = T.Icon("\uE8BD", 44, T.Muted); ic.HorizontalAlignment = HorizontalAlignment.Center;
        empty.Children.Add(ic);
        var et = T.Txt("Выберите чат, чтобы начать переписку", 14, T.Muted); et.HorizontalAlignment = HorizontalAlignment.Center;
        empty.Children.Add(et);
        right.Children.Add(empty);
        Grid.SetColumn(right, 1);
        Children.Add(right);

        list.ItemClick += (_, e) => { if (e.ClickedItem is ChatRow r) Open(r.Id); };
        results.ItemClick += (_, e) => { if (e.ClickedItem is FrameworkElement fe && fe.Tag is SearchResult s) OpenResult(s); };
        search.TextChanged += (_, _) => OnSearch();
        search.KeyDown += (_, e) => { if (e.Key == Windows.System.VirtualKey.Escape) search.Text = ""; };

        Store.ChatsChanged += OnChats;
        Store.OnlineChanged += OnChats;
        Store.TypingChanged += OnTyping;
        Store.MeChanged += OnMe;
        KeyboardAccelerators.Add(Accel(Windows.System.VirtualKey.F, () => search.Focus(FocusState.Keyboard)));
        KeyboardAccelerators.Add(Accel(Windows.System.VirtualKey.K, () => search.Focus(FocusState.Keyboard)));
    }

    static KeyboardAccelerator Accel(Windows.System.VirtualKey k, Action a)
    {
        var x = new KeyboardAccelerator { Key = k, Modifiers = Windows.System.VirtualKeyModifiers.Control };
        x.Invoked += (_, e) => { e.Handled = true; a(); };
        return x;
    }

    public void Detach()
    {
        Store.ChatsChanged -= OnChats;
        Store.OnlineChanged -= OnChats;
        Store.TypingChanged -= OnTyping;
        Store.MeChanged -= OnMe;
        chat?.Detach();
    }

    void OnMe() { var m = Store.Me; if (m != null) meAv.Set(m.Name, m.AvatarUrl, m.Color); }

    void OnTyping(string id) { if (rows.TryGetValue(id, out var r) && Store.Chat(id) is { } c) r.Update(c); }

    void OnChats()
    {
        loading.IsActive = false; loading.Visibility = Visibility.Collapsed;
        var chats = Store.Chats;
        var seen = new HashSet<string>();
        for (int i = 0; i < chats.Count; i++)
        {
            var c = chats[i]; seen.Add(c.Id);
            if (!rows.TryGetValue(c.Id, out var r)) { r = new ChatRow(c.Id); rows[c.Id] = r; }
            r.Update(c);
            var cur = list.Items.IndexOf(r);
            if (cur != i)
            {
                if (cur >= 0) list.Items.RemoveAt(cur);
                list.Items.Insert(Math.Min(i, list.Items.Count), r);
            }
        }
        foreach (var k in rows.Keys.Where(k => !seen.Contains(k)).ToList()) { list.Items.Remove(rows[k]); rows.Remove(k); }
        if (openId != null && rows.TryGetValue(openId, out var sel) && list.SelectedItem != sel) list.SelectedItem = sel;
    }

    public async void Open(string chatId)
    {
        search.Text = "";
        if (openId == chatId && chat != null) return;
        openId = chatId;
        if (rows.TryGetValue(chatId, out var r)) list.SelectedItem = r;
        chat?.Detach();
        right.Children.Clear();
        chat = new ChatView(win, chatId);
        right.Children.Add(chat);
        Store.OpenChatId = chatId;
        Notifications.ClearChat(chatId);
        await chat.Load();
    }

    public void CloseChat()
    {
        chat?.Detach(); chat = null; openId = null; Store.OpenChatId = null;
        list.SelectedItem = null;
        right.Children.Clear(); right.Children.Add(empty);
    }

    CancellationTokenSource? searchCts;

    async void OnSearch()
    {
        var q = search.Text.Trim();
        searchCts?.Cancel();
        if (q.Length == 0) { results.Visibility = Visibility.Collapsed; list.Visibility = Visibility.Visible; return; }
        results.Visibility = Visibility.Visible; list.Visibility = Visibility.Collapsed;
        results.Items.Clear();
        // сначала — свои чаты по названию
        var low = q.TrimStart('@').ToLowerInvariant();
        foreach (var c in Store.Chats.Where(c => c.DisplayName.ToLowerInvariant().Contains(low) || (c.PeerUsername ?? c.Username ?? "").ToLowerInvariant().StartsWith(low)).Take(20))
            results.Items.Add(ResultRow(new SearchResult(c.Id, "chat", c.DisplayName, c.IsPrivate ? c.PeerUsername : c.Username, c.DisplayAvatar, c.DisplayColor, Store.Status(c))));
        var cts = new CancellationTokenSource(); searchCts = cts;
        try { await Task.Delay(300, cts.Token); } catch { return; }
        var found = await Store.Search(q);
        if (cts.IsCancellationRequested) return;
        var have = results.Items.OfType<FrameworkElement>().Select(x => (x.Tag as SearchResult)?.Id).ToHashSet();
        var add = found.Where(s => !have.Contains(s.Id) && !Store.Chats.Any(c => c.Id == s.Id || (s.Kind == "user" && c.PeerId == s.Id))).ToList();
        if (add.Count > 0)
        {
            var h = T.Txt("Глобальный поиск", 12, T.Muted); h.Margin = new Thickness(10, 10, 0, 4);
            results.Items.Add(new ListViewItem { Content = h, IsEnabled = false });
            foreach (var s in add) results.Items.Add(ResultRow(s));
        }
        if (results.Items.Count == 0)
        {
            var t = T.Txt(low.Length < 3 ? "Введите не меньше 3 символов юзернейма" : "Ничего не найдено", 13, T.Muted);
            t.Margin = new Thickness(10, 16, 10, 0); t.HorizontalAlignment = HorizontalAlignment.Center;
            results.Items.Add(new ListViewItem { Content = t, IsEnabled = false });
        }
    }

    FrameworkElement ResultRow(SearchResult s)
    {
        var g = new Grid { Tag = s, Padding = new Thickness(6, 8, 6, 8), ColumnSpacing = 12 };
        g.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        g.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        var av = new AvatarView(44); av.Set(s.Name, s.AvatarUrl, s.Color);
        g.Children.Add(av);
        var sp = new StackPanel { VerticalAlignment = VerticalAlignment.Center, Spacing = 2 };
        sp.Children.Add(T.Txt(s.Name, 15, bold: true, lines: 1));
        var sub = s.Kind == "chat" ? s.Extra ?? "" : (s.Username != null ? "@" + s.Username : "") + (s.Kind switch { "channel" => " · канал", "group" => " · группа", "bot" => " · бот", _ => "" });
        sp.Children.Add(T.Txt(sub, 13, T.Muted, lines: 1));
        Grid.SetColumn(sp, 1); g.Children.Add(sp);
        return g;
    }

    async void OpenResult(SearchResult s)
    {
        if (s.Kind == "chat") { Open(s.Id); return; }
        if (s.Kind is "user" or "bot")
        {
            var cid = await Store.OpenDm(s.Id);
            if (cid != null) Open(cid);
            return;
        }
        // группа или канал: вступить и открыть
        if (Store.Chat(s.Id) == null)
        {
            if (!await Dialogs.JoinChat(win, s)) return;
            await Store.Join(s.Id);
        }
        Open(s.Id);
    }
}

/// <summary>Строка списка чатов</summary>
public sealed class ChatRow : Grid
{
    public string Id { get; }
    readonly AvatarView av = new(50);
    readonly TextBlock name = T.Txt("", 15, bold: true, lines: 1);
    readonly TextBlock preview = T.Txt("", 13, T.Muted, lines: 1);
    readonly TextBlock time = T.Txt("", 12, T.Muted, lines: 1);
    readonly Border badge;
    readonly TextBlock badgeText = new() { FontSize = 12, Foreground = T.White, FontWeight = Microsoft.UI.Text.FontWeights.SemiBold, HorizontalAlignment = HorizontalAlignment.Center };
    readonly FontIcon verified = T.Icon("\uE930", 13, T.A2), muted = T.Icon("\uE74F", 12, T.Muted), pin = T.Icon("\uE718", 12, T.Muted),
        lockIc = T.Icon("\uE72E", 11, T.Muted);
    readonly CheckMark check = new();

    public ChatRow(string id)
    {
        Id = id;
        Padding = new Thickness(6, 8, 6, 8); ColumnSpacing = 12;
        ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        Children.Add(av);
        var mid = new Grid { VerticalAlignment = VerticalAlignment.Center, RowSpacing = 3 };
        mid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        mid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        mid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        mid.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        var top = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 5 };
        top.Children.Add(name); top.Children.Add(verified); top.Children.Add(muted);
        verified.VerticalAlignment = VerticalAlignment.Center; muted.VerticalAlignment = VerticalAlignment.Center;
        mid.Children.Add(top);
        var tr = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 4, HorizontalAlignment = HorizontalAlignment.Right };
        tr.Children.Add(check); tr.Children.Add(time);
        Grid.SetColumn(tr, 1); mid.Children.Add(tr);
        var bottom = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 4 };
        lockIc.VerticalAlignment = VerticalAlignment.Center;
        bottom.Children.Add(preview);
        Grid.SetRow(bottom, 1); mid.Children.Add(bottom);
        var br = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 6, HorizontalAlignment = HorizontalAlignment.Right };
        badge = new Border { MinWidth = 22, Height = 22, CornerRadius = new CornerRadius(11), Padding = new Thickness(6, 0, 6, 0), Child = badgeText };
        badgeText.VerticalAlignment = VerticalAlignment.Center;
        pin.VerticalAlignment = VerticalAlignment.Center;
        br.Children.Add(pin); br.Children.Add(badge);
        Grid.SetRow(br, 1); Grid.SetColumn(br, 1); mid.Children.Add(br);
        Grid.SetColumn(mid, 1);
        Children.Add(mid);
    }

    public void Update(ChatItem c)
    {
        var online = c.IsPrivate && c.PeerId != null && Store.Online.Contains(c.PeerId);
        if (c.IsPrivate && (c.PeerId == null || c.PeerId == Store.MyId)) av.SetIcon("\uE734", T.Accent);
        else av.Set(c.DisplayName, c.DisplayAvatar, c.DisplayColor, online);
        name.Text = c.PeerId == Store.MyId && c.IsPrivate ? "Избранное" : c.DisplayName;
        verified.Visibility = c.PeerVerified ? Visibility.Visible : Visibility.Collapsed;
        muted.Visibility = c.Muted ? Visibility.Visible : Visibility.Collapsed;
        var typing = Store.TypingText(c.Id);
        preview.Text = typing ?? c.Preview(Store.MyId, Store.ChatPreview.GetValueOrDefault(c.Id)).Replace('\n', ' ');
        preview.Foreground = typing != null ? T.A2 : T.Muted;
        time.Text = Fmt.ListTime(c.LastAt);
        var mine = c.LastSender == Store.MyId && c.LastId != null && c.LastKind != "system" && !c.IsChannel;
        check.Set(!mine ? 0 : c.OthersReadAt != null && c.LastAt != null && c.OthersReadAt >= c.LastAt ? 3 : 2, T.A2);
        badge.Visibility = c.Unread > 0 ? Visibility.Visible : Visibility.Collapsed;
        badgeText.Text = c.Unread > 999 ? "999+" : c.Unread.ToString();
        badge.Background = c.Muted ? T.B(0xFF4A4D72) : T.Accent;
        pin.Visibility = c.Pinned && c.Unread == 0 ? Visibility.Visible : Visibility.Collapsed;
    }
}
