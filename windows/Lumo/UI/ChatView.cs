using Lumo.Core;
using Microsoft.UI.Input;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Controls.Primitives;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using Windows.ApplicationModel.DataTransfer;
using Windows.Storage;
using Windows.System;
using Windows.UI.Core;

namespace Lumo.UI;

/// <summary>Открытый чат: шапка, закреп, переписка, строка ввода</summary>
public sealed class ChatView : Grid
{
    readonly MainWindow win;
    public string ChatId { get; }
    readonly AvatarView av = new(40);
    readonly TextBlock title = T.Txt("", 16, bold: true, lines: 1);
    readonly TextBlock status = T.Txt("", 12.5, T.Muted, lines: 1);
    readonly FontIcon verified = T.Icon("\uE930", 14, T.A2);
    readonly ScrollViewer sv = new() { HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled, VerticalScrollBarVisibility = ScrollBarVisibility.Auto };
    readonly StackPanel msgs = new() { Padding = new Thickness(0, 10, 0, 12) };
    readonly Dictionary<int, BubbleView> bubbles = new();
    readonly TextBox input = new()
    {
        PlaceholderText = "Сообщение", AcceptsReturn = true, TextWrapping = TextWrapping.Wrap, MaxHeight = 200, MinHeight = 40,
        CornerRadius = new CornerRadius(20), Padding = new Thickness(14, 9, 14, 9), VerticalAlignment = VerticalAlignment.Center,
    };
    readonly Border replyBar = new() { Visibility = Visibility.Collapsed, Padding = new Thickness(16, 8, 10, 8), Background = T.Panel, BorderBrush = T.Line, BorderThickness = new Thickness(0, 1, 0, 0) };
    readonly TextBlock replyTitle = T.Txt("", 13, T.A2, bold: true, lines: 1), replyText = T.Txt("", 13, T.Muted, lines: 1);
    readonly FontIcon replyIcon = T.Icon("\uE97A", 18, T.A2);
    readonly Border pinBar = new() { Visibility = Visibility.Collapsed, Padding = new Thickness(16, 6, 10, 6), Background = T.Panel, BorderBrush = T.Line, BorderThickness = new Thickness(0, 0, 0, 1) };
    readonly TextBlock pinText = T.Txt("", 13, T.Text, lines: 1);
    readonly Grid composer = new() { Padding = new Thickness(10, 8, 10, 10), ColumnSpacing = 6, Background = T.Panel };
    readonly Border readOnlyBar = new() { Visibility = Visibility.Collapsed, Background = T.Panel, Padding = new Thickness(10), BorderBrush = T.Line, BorderThickness = new Thickness(0, 1, 0, 0) };
    readonly Button down;
    readonly Grid overlay = new() { Visibility = Visibility.Collapsed, Background = T.Dim };
    readonly ProgressRing loading = new() { IsActive = true, Width = 32, Height = 32, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
    Message? replyTo, editing;
    bool loadingOlder, firstLoad = true;

    public ChatView(MainWindow w, string chatId)
    {
        win = w; ChatId = chatId;
        RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });            // шапка
        RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });            // закреп
        RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) }); // переписка
        RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });            // ответ
        RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });            // ввод

        // ----- шапка -----
        var head = new Grid { Padding = new Thickness(14, 8, 8, 8), ColumnSpacing = 12, Background = T.Panel, BorderBrush = T.Line, BorderThickness = new Thickness(0, 0, 0, 1) };
        head.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        head.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        head.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        head.Children.Add(av);
        var info = new StackPanel { VerticalAlignment = VerticalAlignment.Center, Spacing = 1, Background = T.Transparent };
        var tr = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 6 };
        tr.Children.Add(title); verified.VerticalAlignment = VerticalAlignment.Center; tr.Children.Add(verified);
        info.Children.Add(tr); info.Children.Add(status);
        Grid.SetColumn(info, 1); head.Children.Add(info);
        info.Tapped += (_, _) => ShowInfo();
        av.Tapped += (_, _) => ShowInfo();
        var tools = new StackPanel { Orientation = Orientation.Horizontal };
        tools.Children.Add(T.IconButton("\uE721", "Поиск по чату (Ctrl+F)", () => _ = Dialogs.SearchInChat(win, this)));
        tools.Children.Add(T.IconButton("\uE946", "Информация", ShowInfo));
        var more = T.IconButton("\uE712", "Ещё", () => { });
        more.Click += (_, _) => MoreMenu().ShowAt(more);
        tools.Children.Add(more);
        Grid.SetColumn(tools, 2); head.Children.Add(tools);
        Children.Add(head);

        // ----- закреплённое -----
        var pg = new Grid { ColumnSpacing = 10 };
        pg.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(3) });
        pg.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        pg.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        pg.Children.Add(new Border { Background = T.Accent, CornerRadius = new CornerRadius(2) });
        var ps = new StackPanel { VerticalAlignment = VerticalAlignment.Center, Background = T.Transparent };
        ps.Children.Add(T.Txt("Закреплённое сообщение", 12, T.A2, bold: true));
        ps.Children.Add(pinText);
        ps.Tapped += (_, _) => { if (Store.Chat(ChatId)?.PinnedMessageId is int id) JumpTo(id); };
        Grid.SetColumn(ps, 1); pg.Children.Add(ps);
        var unpin = T.IconButton("\uE711", "Открепить", async () => await Store.Pin(null, ChatId), 30, 12);
        Grid.SetColumn(unpin, 2); pg.Children.Add(unpin);
        pinBar.Child = pg;
        Grid.SetRow(pinBar, 1); Children.Add(pinBar);

        // ----- переписка -----
        var area = new Grid { AllowDrop = true, Background = T.ChatBg };
        sv.Content = msgs;
        area.Children.Add(sv);
        area.Children.Add(loading);
        down = new Button
        {
            Width = 44, Height = 44, CornerRadius = new CornerRadius(22), Padding = new Thickness(0), Background = T.Panel2, BorderBrush = T.Line, BorderThickness = new Thickness(1),
            HorizontalAlignment = HorizontalAlignment.Right, VerticalAlignment = VerticalAlignment.Bottom, Margin = new Thickness(0, 0, 18, 14),
            Content = T.Icon("\uE70D", 16), Visibility = Visibility.Collapsed,
        };
        down.Click += (_, _) => ScrollBottom(false);
        area.Children.Add(down);
        area.DragOver += (_, e) =>
        {
            if (!e.DataView.Contains(StandardDataFormats.StorageItems)) return;
            e.AcceptedOperation = DataPackageOperation.Copy;
            e.DragUIOverride.Caption = "Отправить";
        };
        area.Drop += async (_, e) =>
        {
            if (!e.DataView.Contains(StandardDataFormats.StorageItems)) return;
            var items = await e.DataView.GetStorageItemsAsync();
            await SendFiles(items.OfType<StorageFile>().Select(f => f.Path).ToList());
        };
        Grid.SetRow(area, 2); Children.Add(area);
        sv.ViewChanged += (_, _) => OnScroll();

        // ----- ответ / изменение -----
        var rg = new Grid { ColumnSpacing = 12 };
        rg.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        rg.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        rg.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        replyIcon.VerticalAlignment = VerticalAlignment.Center;
        rg.Children.Add(replyIcon);
        var rs = new StackPanel(); rs.Children.Add(replyTitle); rs.Children.Add(replyText);
        Grid.SetColumn(rs, 1); rg.Children.Add(rs);
        var rc = T.IconButton("\uE711", "Отмена (Esc)", CancelReply, 30, 12);
        Grid.SetColumn(rc, 2); rg.Children.Add(rc);
        replyBar.Child = rg;
        Grid.SetRow(replyBar, 3); Children.Add(replyBar);

        // ----- ввод -----
        composer.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        composer.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        composer.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        var attach = T.IconButton("\uE723", "Прикрепить файл", async () => await PickFiles(), 40, 18);
        attach.VerticalAlignment = VerticalAlignment.Bottom;
        composer.Children.Add(attach);
        Grid.SetColumn(input, 1); composer.Children.Add(input);
        var send = new Button { Width = 40, Height = 40, CornerRadius = new CornerRadius(20), Padding = new Thickness(0), BorderThickness = new Thickness(0), Background = T.Accent, Content = T.Icon("\uE724", 16, T.White), VerticalAlignment = VerticalAlignment.Bottom };
        ToolTipService.SetToolTip(send, "Отправить (Enter)");
        send.Click += (_, _) => SendText();
        Grid.SetColumn(send, 2); composer.Children.Add(send);
        Grid.SetRow(composer, 4); Children.Add(composer);
        Grid.SetRow(readOnlyBar, 4); Children.Add(readOnlyBar);

        input.PreviewKeyDown += OnKey;
        input.TextChanged += (_, _) => { if (input.Text.Length > 0 && editing == null) Store.UserTyping(ChatId); Drafts[ChatId] = input.Text; };
        input.Paste += OnPaste;
        input.Text = Drafts.GetValueOrDefault(ChatId) ?? "";

        // просмотр фото и видео — поверх чата
        Grid.SetRowSpan(overlay, 5);
        Children.Add(overlay);

        var f = new KeyboardAccelerator { Key = VirtualKey.F, Modifiers = VirtualKeyModifiers.Control };
        f.Invoked += (_, e) => { e.Handled = true; _ = Dialogs.SearchInChat(win, this); };
        KeyboardAccelerators.Add(f);

        Store.MessagesChanged += OnMessages;
        Store.ReactionsChanged += OnReaction;
        Store.ChatsChanged += OnChats;
        Store.TypingChanged += OnTyping;
        Store.OnlineChanged += Header;
        Header();
    }

    public static readonly Dictionary<string, string> Drafts = new();

    public void Detach()
    {
        Store.MessagesChanged -= OnMessages;
        Store.ReactionsChanged -= OnReaction;
        Store.ChatsChanged -= OnChats;
        Store.TypingChanged -= OnTyping;
        Store.OnlineChanged -= Header;
        if (Store.OpenChatId == ChatId) Store.UserTyping(ChatId, "stop");
    }

    public async Task Load()
    {
        if (Store.Msgs(ChatId).Count > 0) Render();
        await Store.LoadMessages(ChatId);
        loading.IsActive = false; loading.Visibility = Visibility.Collapsed;
        Render();
        Store.MarkRead(ChatId);
        input.Focus(FocusState.Programmatic);
    }

    void Header()
    {
        var c = Store.Chat(ChatId);
        if (c == null)
        {
            title.Text = "Чат"; status.Text = "вы не участник";
            composer.Visibility = Visibility.Collapsed;
            readOnlyBar.Visibility = Visibility.Visible;
            readOnlyBar.Child = T.Primary("Вступить", async () => { await Store.Join(ChatId); Header(); });
            return;
        }
        var self = c.IsPrivate && (c.PeerId == null || c.PeerId == Store.MyId);
        if (self) av.SetIcon("\uE734", T.Accent); else av.Set(c.DisplayName, c.DisplayAvatar, c.DisplayColor, c.PeerId != null && Store.Online.Contains(c.PeerId));
        title.Text = self ? "Избранное" : c.DisplayName;
        verified.Visibility = c.PeerVerified ? Visibility.Visible : Visibility.Collapsed;
        status.Text = Store.Status(c);
        status.Foreground = Store.TypingText(ChatId) != null || status.Text == "в сети" ? T.A2 : T.Muted;
        if (!c.CanPost)
        {
            composer.Visibility = Visibility.Collapsed; readOnlyBar.Visibility = Visibility.Visible;
            readOnlyBar.Child = T.Primary(c.Muted ? "Включить уведомления" : "Выключить уведомления", async () => { await Store.SetMuted(ChatId, !c.Muted); Header(); });
        }
        else { composer.Visibility = Visibility.Visible; readOnlyBar.Visibility = Visibility.Collapsed; }
        var pin = c.PinnedMessageId is int pid ? Store.Find(pid, ChatId) : null;
        pinBar.Visibility = pin != null ? Visibility.Visible : Visibility.Collapsed;
        if (pin != null) pinText.Text = pin.Preview.Replace('\n', ' ');
    }

    void OnChats() { Header(); foreach (var b in bubbles.Values) b.UpdateStatus(); }
    void OnTyping(string id) { if (id == ChatId) Header(); }
    void OnReaction(int id) { if (bubbles.TryGetValue(id, out var b)) b.UpdateReactions(); }

    void OnMessages(string id)
    {
        if (id != ChatId) return;
        var atBottom = sv.VerticalOffset >= sv.ScrollableHeight - 80;
        var list = Store.Msgs(ChatId);
        var lastMine = list.LastOrDefault()?.SenderId == Store.MyId;
        Render();
        if (atBottom || lastMine) ScrollBottom(true);
        if (Store.WindowActive) Store.MarkRead(ChatId);
    }

    void Render()
    {
        var list = Store.Msgs(ChatId);
        var keep = new Dictionary<int, BubbleView>();
        var children = new List<UIElement>();
        DateTimeOffset? prevDay = null;
        Message? prev = null;
        for (int i = 0; i < list.Count; i++)
        {
            var m = list[i];
            var day = m.CreatedAt.LocalDateTime.Date;
            if (prevDay == null || prevDay.Value.LocalDateTime.Date != day)
            {
                var pill = new Border { Background = T.B(0x26FFFFFF), CornerRadius = new CornerRadius(12), Padding = new Thickness(12, 4, 12, 4), HorizontalAlignment = HorizontalAlignment.Center, Margin = new Thickness(0, 10, 0, 6) };
                pill.Child = T.Txt(Fmt.Day(m.CreatedAt), 12.5);
                children.Add(pill);
                prev = null;
            }
            prevDay = m.CreatedAt;
            var showName = prev == null || prev.SenderId != m.SenderId || prev.Kind == "system";
            var next = i + 1 < list.Count ? list[i + 1] : null;
            var tail = next == null || next.SenderId != m.SenderId || next.CreatedAt.LocalDateTime.Date != day || next.Kind == "system";
            var sig = BubbleView.Signature(m) + "|" + showName + tail;
            BubbleView b;
            if (bubbles.TryGetValue(m.Id, out var old) && old.Sig == sig) b = old;
            else b = new BubbleView(m, this, showName, tail);
            keep[m.Id] = b;
            children.Add(b);
            prev = m;
        }
        bubbles.Clear();
        foreach (var kv in keep) bubbles[kv.Key] = kv.Value;
        msgs.Children.Clear();
        foreach (var c in children) msgs.Children.Add(c);
        if (firstLoad && list.Count > 0) { firstLoad = false; ScrollBottom(true); }
    }

    public void ScrollBottom(bool instant)
    {
        DispatcherQueue.TryEnqueue(Microsoft.UI.Dispatching.DispatcherQueuePriority.Low, () =>
        {
            sv.UpdateLayout();
            sv.ChangeView(null, sv.ScrollableHeight, null, instant);
        });
    }

    async void OnScroll()
    {
        down.Visibility = sv.VerticalOffset < sv.ScrollableHeight - 400 ? Visibility.Visible : Visibility.Collapsed;
        if (loadingOlder || sv.VerticalOffset > 300 || !Store.HasMore.GetValueOrDefault(ChatId)) return;
        loadingOlder = true;
        var before = sv.ExtentHeight; var off = sv.VerticalOffset;
        await Store.LoadMessages(ChatId, older: true);
        sv.UpdateLayout();
        sv.ChangeView(null, off + (sv.ExtentHeight - before), null, true);
        loadingOlder = false;
    }

    /// <summary>Догрузить историю до нужного сообщения и показать его</summary>
    public async Task JumpToLoading(int id)
    {
        for (int i = 0; i < 20 && !bubbles.ContainsKey(id) && Store.HasMore.GetValueOrDefault(ChatId); i++)
        {
            loadingOlder = true;
            await Store.LoadMessages(ChatId, older: true);
            loadingOlder = false;
        }
        sv.UpdateLayout();
        JumpTo(id);
    }

    public void JumpTo(int id)
    {
        if (!bubbles.TryGetValue(id, out var b)) { Store.Say("Сообщение не загружено"); return; }
        b.StartBringIntoView(new BringIntoViewOptions { VerticalAlignmentRatio = 0.4, AnimationDesired = true });
        var old = b.Background;
        b.Background = T.Selected;
        _ = Task.Delay(1200).ContinueWith(_ => DispatcherQueue.TryEnqueue(() => b.Background = old));
    }

    // ----- ввод -----

    void OnKey(object sender, KeyRoutedEventArgs e)
    {
        var shift = InputKeyboardSource.GetKeyStateForCurrentThread(VirtualKey.Shift).HasFlag(CoreVirtualKeyStates.Down);
        if (e.Key == VirtualKey.Enter && !shift) { e.Handled = true; SendText(); }
        else if (e.Key == VirtualKey.Escape && (replyTo != null || editing != null)) { e.Handled = true; CancelReply(); }
        else if (e.Key == VirtualKey.Up && input.Text.Length == 0)
        {
            var last = Store.Msgs(ChatId).LastOrDefault(m => m.SenderId == Store.MyId && m.Kind == "text" && m.Id > 0);
            if (last != null) { e.Handled = true; Edit(last); }
        }
    }

    async void SendText()
    {
        var text = input.Text.Trim();
        if (text.Length == 0) return;
        if (editing != null)
        {
            var m = editing; CancelReply(); input.Text = "";
            if (text != m.Body) await Store.Edit(m, text);
            return;
        }
        var r = replyTo?.Id;
        input.Text = ""; Drafts.Remove(ChatId);
        CancelReply();
        Store.UserTyping(ChatId, "stop");
        // длинный текст — частями по 4000 символов
        for (int i = 0; i < text.Length; i += 4000)
            await Store.Send(ChatId, "text", text.Substring(i, Math.Min(4000, text.Length - i)), replyTo: i == 0 ? r : null);
    }

    public void Reply(Message m)
    {
        if (m.Id <= 0 || Store.Chat(ChatId)?.CanPost != true) return;
        editing = null; replyTo = m;
        replyIcon.Glyph = "\uE97A";
        replyTitle.Text = "Ответ: " + Store.DisplayName(m.SenderId);
        replyText.Text = m.Preview.Replace('\n', ' ');
        replyBar.Visibility = Visibility.Visible;
        input.Focus(FocusState.Programmatic);
    }

    public void Edit(Message m)
    {
        replyTo = null; editing = m;
        replyIcon.Glyph = "\uE70F";
        replyTitle.Text = "Изменение сообщения";
        replyText.Text = m.Preview.Replace('\n', ' ');
        replyBar.Visibility = Visibility.Visible;
        input.Text = m.Body ?? "";
        input.SelectionStart = input.Text.Length;
        input.Focus(FocusState.Programmatic);
    }

    void CancelReply()
    {
        if (editing != null) input.Text = "";
        replyTo = null; editing = null;
        replyBar.Visibility = Visibility.Collapsed;
    }

    async Task PickFiles()
    {
        var p = new Windows.Storage.Pickers.FileOpenPicker();
        WinRT.Interop.InitializeWithWindow.Initialize(p, win.Hwnd);
        p.FileTypeFilter.Add("*");
        var files = await p.PickMultipleFilesAsync();
        if (files == null || files.Count == 0) return;
        await SendFiles(files.Select(f => f.Path).ToList());
    }

    async Task SendFiles(List<string> paths)
    {
        if (paths.Count == 0) return;
        if (Store.Chat(ChatId)?.CanPost != true) return;
        var caption = await Dialogs.ConfirmFiles(win, paths, input.Text.Trim());
        if (caption == null) return;
        if (caption.Length > 0) { input.Text = ""; Drafts.Remove(ChatId); }
        var r = replyTo?.Id; CancelReply();
        for (int i = 0; i < paths.Count; i++)
            await Store.SendFile(ChatId, paths[i], i == 0 && caption.Length > 0 ? caption : null, i == 0 ? r : null);
    }

    async void OnPaste(object sender, TextControlPasteEventArgs e)
    {
        try
        {
            var dp = Clipboard.GetContent();
            if (dp.Contains(StandardDataFormats.StorageItems))
            {
                e.Handled = true;
                var items = await dp.GetStorageItemsAsync();
                await SendFiles(items.OfType<StorageFile>().Select(f => f.Path).ToList());
            }
            else if (dp.Contains(StandardDataFormats.Bitmap) && !dp.Contains(StandardDataFormats.Text))
            {
                e.Handled = true;
                var rs = await dp.GetBitmapAsync();
                using var s = await rs.OpenReadAsync();
                var dec = await Windows.Graphics.Imaging.BitmapDecoder.CreateAsync(s);
                var bmp = await dec.GetSoftwareBitmapAsync();
                var tmp = Path.Combine(Path.GetTempPath(), "lumo-paste-" + DateTime.Now.ToString("yyyyMMdd-HHmmss") + ".png");
                var folder = await StorageFolder.GetFolderFromPathAsync(Path.GetTempPath());
                var file = await folder.CreateFileAsync(Path.GetFileName(tmp), CreationCollisionOption.ReplaceExisting);
                using (var os = await file.OpenAsync(FileAccessMode.ReadWrite))
                {
                    var enc = await Windows.Graphics.Imaging.BitmapEncoder.CreateAsync(Windows.Graphics.Imaging.BitmapEncoder.PngEncoderId, os);
                    enc.SetSoftwareBitmap(bmp);
                    await enc.FlushAsync();
                }
                await SendFiles(new List<string> { file.Path });
            }
        }
        catch (Exception ex) { App.Log("paste: " + ex.Message); }
    }

    // ----- меню сообщения -----

    static readonly string[] quick = { "\U0001F44D", "❤️", "\U0001F602", "\U0001F62E", "\U0001F622", "\U0001F525", "\U0001F44F", "\U0001F389" };

    public void Menu(BubbleView b, FrameworkElement target, Windows.Foundation.Point at)
    {
        var m = b.M;
        var c = Store.Chat(ChatId);
        var mine = m.SenderId == Store.MyId;
        var fl = new MenuFlyout();
        if (m.Id > 0)
        {
            var rx = new MenuFlyoutSubItem { Text = "Реакция", Icon = Fi("\uE76E") };
            foreach (var e in quick)
            {
                var it = new MenuFlyoutItem { Text = e, FontSize = 18 };
                var emoji = e;
                it.Click += async (_, _) => await Store.React(m, emoji);
                rx.Items.Add(it);
            }
            fl.Items.Add(rx);
            if (c?.CanPost == true) fl.Items.Add(Item("Ответить", "\uE97A", () => Reply(m)));
        }
        if (!string.IsNullOrEmpty(m.Body) && m.Body != E2E.LOCKED)
            fl.Items.Add(Item("Копировать текст", "\uE8C8", () => { var d = new DataPackage(); d.SetText(m.Body); Clipboard.SetContent(d); Store.Say("Скопировано"); }));
        if (m.Kind is "image" or "video" or "file" or "voice" or "video_note" && m.MediaUrl != null)
            fl.Items.Add(Item("Сохранить в «Загрузки»", "\uE896", async () => await SaveMedia(m)));
        if (m.Id > 0)
        {
            fl.Items.Add(Item("Переслать", "\uE72A", async () => await Dialogs.Forward(win, new List<Message> { m })));
            if (c != null && (c.IsPrivate || c.IsAdmin))
                fl.Items.Add(Item(c.PinnedMessageId == m.Id ? "Открепить" : "Закрепить", "\uE718", async () => await Store.Pin(c.PinnedMessageId == m.Id ? null : m, ChatId)));
            if (mine && m.Kind == "text" && m.Body != E2E.LOCKED) fl.Items.Add(Item("Изменить", "\uE70F", () => Edit(m)));
            if (m.Enc && c?.PeerId != null)
                fl.Items.Add(Item("Запросить ключ заново", "\uE72E", async () => { await E2E.ForceRefresh(ChatId, c.PeerId); await Store.LoadMessages(ChatId); }));
            fl.Items.Add(new MenuFlyoutSeparator());
            var canAll = mine || c?.IsAdmin == true;
            if (canAll) fl.Items.Add(Item("Удалить у всех", "\uE74D", async () => { if (await Dialogs.Confirm(win, "Удалить сообщение у всех?", "Удалить")) await Store.Delete(new List<Message> { m }, true); }, true));
            fl.Items.Add(Item("Удалить у меня", "\uE74D", async () => await Store.Delete(new List<Message> { m }, false), true));
        }
        fl.ShowAt(target, new FlyoutShowOptions { Position = at });
    }

    static FontIcon Fi(string g) => new() { Glyph = g, FontFamily = T.IconFont };

    static MenuFlyoutItem Item(string text, string glyph, Action a, bool danger = false)
    {
        var it = new MenuFlyoutItem { Text = text, Icon = Fi(glyph) };
        if (danger) it.Foreground = T.Danger;
        it.Click += (_, _) => a();
        return it;
    }

    MenuFlyout MoreMenu()
    {
        var c = Store.Chat(ChatId);
        var fl = new MenuFlyout();
        if (c == null) return fl;
        fl.Items.Add(Item(c.Muted ? "Включить уведомления" : "Выключить уведомления", c.Muted ? "\uE767" : "\uE74F", async () => { await Store.SetMuted(ChatId, !c.Muted); Header(); }));
        fl.Items.Add(Item(c.Pinned ? "Открепить чат" : "Закрепить чат", "\uE718", async () => await Store.SetPinned(ChatId, !c.Pinned)));
        if (c.IsPrivate && c.PeerId != null && c.PeerId != Store.MyId)
            fl.Items.Add(Item("Код шифрования", "\uE72E", async () => await Dialogs.Safety(win, c)));
        fl.Items.Add(Item("Закрыть чат", "\uE711", () => this.FindParent<ShellView>()?.CloseChat()));
        return fl;
    }

    void ShowInfo() { var c = Store.Chat(ChatId); if (c != null) _ = Dialogs.ChatInfo(win, c); }

    async Task SaveMedia(Message m)
    {
        if (m.MediaUrl == null) return;
        var ext = Path.GetExtension(new Uri(m.MediaUrl).AbsolutePath);
        var name = m.Kind == "file" ? m.FileName : "lumo-" + m.CreatedAt.LocalDateTime.ToString("yyyyMMdd-HHmmss") + ext;
        var path = await Media.Cached(m.MediaUrl, name, m.Parts);
        if (path == null) { Store.Say("Не удалось скачать"); return; }
        try { var dst = Media.SaveToDownloads(path, name); Store.Say("Сохранено: " + Path.GetFileName(dst)); }
        catch (Exception e) { Store.Say(e.Message); }
    }

    // ----- просмотр фото и видео -----

    public void ShowImage(Message m)
    {
        overlay.Children.Clear();
        var src = m.MediaUrl != null ? T.Bitmap(m.MediaUrl) : null;
        var img = new Image { Source = src, Stretch = Stretch.Uniform, Margin = new Thickness(40) };
        overlay.Children.Add(img);
        AddOverlayTools(m);
        overlay.Visibility = Visibility.Visible;
        overlay.Tapped += CloseOverlayTap;
    }

    public void ShowVideo(Message m, bool round)
    {
        if (m.MediaUrl == null) return;
        overlay.Children.Clear();
        var pe = new MediaPlayerElement { AreTransportControlsEnabled = !round, AutoPlay = true, Margin = new Thickness(40) };
        pe.Source = Windows.Media.Core.MediaSource.CreateFromUri(new Uri(Net.Px(m.MediaUrl)!));
        if (round)
        {
            var g = new Grid { Width = 380, Height = 380, CornerRadius = new CornerRadius(190), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
            pe.Margin = new Thickness(0); pe.Stretch = Stretch.UniformToFill;
            g.Children.Add(pe);
            overlay.Children.Add(g);
        }
        else overlay.Children.Add(pe);
        AddOverlayTools(m);
        overlay.Visibility = Visibility.Visible;
        overlay.Tapped += CloseOverlayTap;
    }

    void AddOverlayTools(Message m)
    {
        var bar = new StackPanel { Orientation = Orientation.Horizontal, HorizontalAlignment = HorizontalAlignment.Right, VerticalAlignment = VerticalAlignment.Top, Margin = new Thickness(10), Spacing = 4 };
        bar.Children.Add(T.IconButton("\uE896", "Сохранить в «Загрузки»", async () => await SaveMedia(m), 40, 16, T.White));
        bar.Children.Add(T.IconButton("\uE711", "Закрыть (Esc)", CloseOverlay, 40, 16, T.White));
        overlay.Children.Add(bar);
        var esc = new KeyboardAccelerator { Key = VirtualKey.Escape };
        esc.Invoked += (_, e) => { e.Handled = true; CloseOverlay(); };
        overlay.KeyboardAccelerators.Clear();
        overlay.KeyboardAccelerators.Add(esc);
    }

    void CloseOverlayTap(object s, TappedRoutedEventArgs e)
    {
        if (e.OriginalSource is FrameworkElement fe && (fe is Image || fe.FindParent<MediaPlayerElement>() != null || fe is MediaPlayerElement)) return;
        CloseOverlay();
    }

    void CloseOverlay()
    {
        overlay.Tapped -= CloseOverlayTap;
        foreach (var pe in overlay.Children.OfType<MediaPlayerElement>().Concat(overlay.Children.OfType<Grid>().SelectMany(g => g.Children.OfType<MediaPlayerElement>())))
            try { pe.MediaPlayer?.Pause(); pe.Source = null; } catch { }
        overlay.Children.Clear();
        overlay.Visibility = Visibility.Collapsed;
    }

    public List<BubbleView> Bubbles => bubbles.Values.ToList();
}

public static class VisualExt
{
    public static T? FindParent<T>(this DependencyObject d) where T : DependencyObject
    {
        var p = VisualTreeHelper.GetParent(d);
        while (p != null && p is not T) p = VisualTreeHelper.GetParent(p);
        return p as T;
    }
}
