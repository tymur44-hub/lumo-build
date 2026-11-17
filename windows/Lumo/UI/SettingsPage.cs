using Lumo.Core;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Media.Animation;

namespace Lumo.UI;

/// <summary>Раздел, который сам заполняет всю правую панель (веб-страница)</summary>
public interface IFillPage { }

/// <summary>
/// Настройки для ПК: слева — карточка профиля и разделы с цветными иконками (как в мобильной версии),
/// справа — содержимое выбранного раздела.
/// </summary>
public sealed class SettingsPage : Grid
{
    readonly MainWindow win;
    readonly ShellView shell;
    readonly TextBlock pageTitle = T.Txt("", 22, bold: true);

    readonly Dictionary<string, Grid> rows = new();
    readonly AvatarView heroAv = new(76);
    readonly TextBlock heroName = T.Txt("", 18, bold: true, lines: 1), heroUser = T.Txt("", 13, T.Muted, lines: 1);
    readonly StackPanel heroNameRow = new() { Orientation = Orientation.Horizontal, Spacing = 6, HorizontalAlignment = HorizontalAlignment.Center };
    readonly ContentControl heroEmoji = new() { VerticalAlignment = VerticalAlignment.Center };
    string? current;

    record Item(string Key, string Glyph, uint Color, string Title, string Sub, Func<Task<UIElement>>? Page, Action? Act = null);

    // раскладка: меню | разделитель | раздел
    readonly ColumnDefinition menuCol = new() { Width = new GridLength(1, GridUnitType.Star) };
    readonly ColumnDefinition splitCol = new() { Width = new GridLength(0) };
    readonly ColumnDefinition detailCol = new() { Width = new GridLength(0) };
    readonly Grid detail = new() { Background = T.ChatBg, Visibility = Visibility.Collapsed, Opacity = 0 };
    readonly Grid body = new();
    readonly SplitBar split;
    double menuW = Math.Clamp(Prefs.GetLong("settings_menu_w", 420), 300, 900);
    bool detailOpen;

    public SettingsPage(MainWindow w, ShellView s)
    {
        win = w; shell = s;
        Background = T.Panel;
        ColumnDefinitions.Add(menuCol); ColumnDefinitions.Add(splitCol); ColumnDefinitions.Add(detailCol);

        // ---- меню: профиль и разделы ----
        var menu = new StackPanel { Spacing = 12, Padding = new Thickness(18, 10, 18, 28), MaxWidth = 620, HorizontalAlignment = HorizontalAlignment.Stretch };
        var topBar = new Grid { Margin = new Thickness(0, 0, 0, 4) };
        var back = new Button { Background = T.Transparent, BorderThickness = new Thickness(0), Padding = new Thickness(8, 6, 12, 6), CornerRadius = new CornerRadius(12) };
        var bsp = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 8 };
        bsp.Children.Add(T.Icon("\uE72B", 14, T.A2)); bsp.Children.Add(T.Txt("Чаты", 14, T.A2, bold: true));
        back.Content = bsp; back.Click += (_, _) => shell.CloseSettings();
        ToolTipService.SetToolTip(back, "Вернуться к чатам (Esc)");
        topBar.Children.Add(back);
        var ttl = T.Txt("Настройки", 16, bold: true); ttl.HorizontalAlignment = HorizontalAlignment.Center; ttl.VerticalAlignment = VerticalAlignment.Center;
        topBar.Children.Add(ttl);
        menu.Children.Add(topBar);

        var hero = new StackPanel { Spacing = 6, HorizontalAlignment = HorizontalAlignment.Center, Margin = new Thickness(0, 4, 0, 6) };
        heroAv.HorizontalAlignment = HorizontalAlignment.Center;
        hero.Children.Add(heroAv);
        heroUser.HorizontalAlignment = HorizontalAlignment.Center;
        heroNameRow.Children.Add(heroName); heroNameRow.Children.Add(heroEmoji);
        hero.Children.Add(heroNameRow); hero.Children.Add(heroUser);
        var heroBtns = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 8, HorizontalAlignment = HorizontalAlignment.Center, Margin = new Thickness(0, 6, 0, 0) };
        heroBtns.Children.Add(Pill("\uE722", "Фото", ChangePhoto));
        heroBtns.Children.Add(Pill("\uE70F", "Изменить", () => Select("profile")));
        heroBtns.Children.Add(Pill("\uED14", "QR-код", () => Select("qr")));
        hero.Children.Add(heroBtns);
        menu.Children.Add(hero);

        var groups = new List<Item[]>
        {
            new Item[]
            {
                new("profile", "\uE77B", 0xFF7C5CFF, "Мой профиль", "Имя, юзернейм, о себе", ProfilePanel),
                new("qr", "\uED14", 0xFF22A6FF, "QR-код", "Ваш код и ссылка на профиль", () => Task.FromResult<UIElement>(new QrWeb())),
                new("status", "\uE76E", 0xFFA35BFF, "Эмодзи-статус", "Значок рядом с вашим именем", null, async () => { await StatusPicker.Show(); RefreshHero(); }),
                new("saved", "\uE734", 0xFF3A7BFF, "Избранное", "Заметки и сохранённые сообщения", null, OpenSaved),
                new("calls", "\uE717", 0xFF2BD67B, "Недавние звонки", "Недавние и пропущенные", null, () => _ = CallsSheet.Show(id => { shell.CloseSettings(); shell.Open(id); })),
                new("devices", "\uE7F8", 0xFFFF9F1A, "Устройства", "Активные сеансы", Dialogs.DevicesPanel),
            },
            new Item[]
            {
                new("notify", "\uEA8F", 0xFFFF5B5B, "Уведомления и звуки", "Сообщения, текст, панель задач", () => Task.FromResult(Dialogs.NotifyPanel())),
                new("privacy", "\uE72E", 0xFF8E8EA8, "Конфиденциальность", "Время захода, звонки, блокировки", Dialogs.PrivacyPanel),
                new("data", "\uE8B7", 0xFF4CC764, "Данные и память", "Кэш файлов на этом компьютере", DataPanel),
            },
            new Item[]
            {
                new("wallet", "\uE8C7", 0xFFF5B942, "Люмены и Premium", "Баланс, ежедневный бонус", Dialogs.WalletPanel),
                new("gifts", "\uF133", 0xFF2BC4A8, "Подарки", "Коллекционные подарки за люмены", () => Task.FromResult<UIElement>(new GiftsWeb(null, () => Select("wallet")))),
            },
            new Item[]
            {
                new("about", "\uE946", 0xFF8E8EA8, "О Lumo", "Версия " + Updater.VersionText + ", обновления", AboutPanel),
                new("logout", "\uF3B1", 0xFFFF3B5C, "Выйти из аккаунта", "", null, Logout),
            },
        };
        foreach (var g in groups) menu.Children.Add(Group(g));
        var left = new ScrollViewer { Content = menu, VerticalScrollBarVisibility = ScrollBarVisibility.Auto };
        Children.Add(left);

        // ---- разделитель: тянем — меняем ширину ----
        split = new SplitBar(dx => { menuW = Math.Clamp(menuW + dx, 300, Math.Max(300, ActualWidth - 380)); menuCol.Width = new GridLength(menuW); },
                             () => Prefs.Set("settings_menu_w", (long)menuW)) { Visibility = Visibility.Collapsed };
        SetColumn(split, 1); Children.Add(split);

        // ---- раздел ----
        detail.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        detail.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
        var head = new Grid { Padding = new Thickness(28, 18, 16, 10) };

        head.Children.Add(pageTitle);
        var close = T.IconButton("\uE711", "Закрыть раздел (Esc)", CloseDetail);
        close.HorizontalAlignment = HorizontalAlignment.Right; head.Children.Add(close);
        detail.Children.Add(head);
        Grid.SetRow(body, 1); detail.Children.Add(body);
        detail.RenderTransform = new TranslateTransform();
        SetColumn(detail, 2); Children.Add(detail);

        SizeChanged += (_, _) => { if (detailOpen && !animating) { menuW = Math.Clamp(menuW, 300, Math.Max(300, ActualWidth - 380)); menuCol.Width = new GridLength(menuW); } };

        RefreshHero();
        Loaded += async (_, _) => { await Store.LoadMe(); RefreshHero(); };
    }

    // ---------- плавное открытие и закрытие раздела ----------
    bool animating;

    void AnimateMenu(double from, double to, Action? done)
    {
        animating = true;
        var sw = System.Diagnostics.Stopwatch.StartNew();
        const double dur = 300;
        EventHandler<object>? tick = null;
        tick = (_, _) =>
        {
            var t = Math.Min(1, sw.Elapsed.TotalMilliseconds / dur);
            var e = 1 - Math.Pow(1 - t, 3);
            menuCol.Width = new GridLength(Math.Max(0, from + (to - from) * e));
            if (t >= 1) { CompositionTarget.Rendering -= tick; animating = false; done?.Invoke(); }
        };
        CompositionTarget.Rendering += tick;
    }

    void Fade(UIElement el, bool show, double dx)
    {
        var sb = new Storyboard();
        var o = new DoubleAnimation { To = show ? 1 : 0, Duration = TimeSpan.FromMilliseconds(show ? 300 : 200), EasingFunction = new CubicEase { EasingMode = EasingMode.EaseOut } };
        Storyboard.SetTarget(o, el); Storyboard.SetTargetProperty(o, "Opacity"); sb.Children.Add(o);
        var x = new DoubleAnimation { From = show ? dx : 0, To = show ? 0 : dx, Duration = TimeSpan.FromMilliseconds(300), EasingFunction = new CubicEase { EasingMode = EasingMode.EaseOut } };
        Storyboard.SetTarget(x, el.RenderTransform); Storyboard.SetTargetProperty(x, "X"); sb.Children.Add(x);
        sb.Begin();
    }

    void OpenDetail()
    {
        if (detailOpen) return;
        detailOpen = true;
        var total = Math.Max(ActualWidth, 800);
        menuW = Math.Clamp(menuW, 300, Math.Max(300, total - 380));
        menuCol.Width = new GridLength(total);
        splitCol.Width = new GridLength(6); detailCol.Width = new GridLength(1, GridUnitType.Star);
        split.Visibility = Visibility.Visible; detail.Visibility = Visibility.Visible;
        Fade(detail, true, 60);
        AnimateMenu(total, menuW, null);
    }

    /// <summary>Esc: сначала закрываем раздел, потом сами настройки</summary>
    public void Back() { if (detailOpen) CloseDetail(); else shell.CloseSettings(); }

    public void CloseDetail()
    {
        if (!detailOpen || animating) return;
        detailOpen = false; current = null;
        foreach (var r in rows.Values) r.Background = T.Transparent;
        Fade(detail, false, 60);
        AnimateMenu(menuCol.ActualWidth, ActualWidth, () =>
        {
            if (detailOpen) return;
            menuCol.Width = new GridLength(1, GridUnitType.Star);
            splitCol.Width = new GridLength(0); detailCol.Width = new GridLength(0);
            split.Visibility = Visibility.Collapsed; detail.Visibility = Visibility.Collapsed;
            body.Children.Clear();
        });
    }

    void RefreshHero()
    {
        var me = Store.Me; if (me == null) return;
        heroAv.Set(me.Name, me.AvatarUrl, me.Color);
        heroName.Text = me.Name + (me.Premium ? "  ★" : "");
        heroName.Text = me.Name;
        heroUser.Text = "@" + me.Username;
        heroEmoji.Content = me.Premium && !string.IsNullOrEmpty(me.EmojiStatus) ? new StatusEmoji(me.EmojiStatus, 22) : null;
    }

    FrameworkElement Pill(string glyph, string text, Action act)
    {
        var sp = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 6 };
        sp.Children.Add(T.Icon(glyph, 13, T.A2)); sp.Children.Add(T.Txt(text, 12.5, T.Text, bold: true));
        var b = new Button { Content = sp, CornerRadius = new CornerRadius(14), Padding = new Thickness(12, 5, 12, 5), BorderThickness = new Thickness(0) };
        T.Fill(b, T.Panel2, T.B(0xFF24264A));
        b.Click += (_, _) => act();
        return b;
    }

    FrameworkElement Group(Item[] items)
    {
        var box = new StackPanel { Background = T.Panel2, CornerRadius = new CornerRadius(14) };
        for (int i = 0; i < items.Length; i++)
        {
            var it = items[i];
            var g = new Grid { ColumnSpacing = 12, Padding = new Thickness(12, 9, 12, 9), Background = T.Transparent, CornerRadius = new CornerRadius(14) };
            g.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            g.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            g.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            var ic = new Border { Width = 30, Height = 30, CornerRadius = new CornerRadius(8), Background = T.B(it.Color), Child = T.Icon(it.Glyph, 15, T.White) };
            g.Children.Add(ic);
            var tx = new StackPanel { VerticalAlignment = VerticalAlignment.Center };
            tx.Children.Add(T.Txt(it.Title, 14, it.Key == "logout" ? T.Danger : T.Text, bold: true, lines: 1));
            if (it.Sub.Length > 0) tx.Children.Add(T.Txt(it.Sub, 11.5, T.Muted, lines: 1));
            Grid.SetColumn(tx, 1); g.Children.Add(tx);
            if (it.Page != null) { var ch = T.Icon("", 11, T.Muted); ch.VerticalAlignment = VerticalAlignment.Center; Grid.SetColumn(ch, 2); g.Children.Add(ch); }
            g.PointerEntered += (_, _) => { if (current != it.Key) g.Background = T.Hover; };
            g.PointerExited += (_, _) => { if (current != it.Key) g.Background = T.Transparent; };
            g.Tapped += (_, _) => { if (it.Page != null) Select(it.Key); else it.Act?.Invoke(); };
            if (it.Page != null) { rows[it.Key] = g; pages[it.Key] = (it.Title, it.Page); }
            box.Children.Add(g);
            if (i < items.Length - 1) box.Children.Add(new Border { Height = 1, Background = T.Line, Margin = new Thickness(54, 0, 0, 0) });
        }
        return box;
    }

    readonly Dictionary<string, (string Title, Func<Task<UIElement>> Make)> pages = new();

    public async void Select(string key)
    {
        if (!pages.TryGetValue(key, out var p)) return;
        if (current == key && detailOpen) return;
        current = key;
        foreach (var (k, r) in rows) r.Background = k == key ? T.Selected : T.Transparent;
        pageTitle.Text = p.Title;
        var wasOpen = detailOpen;
        body.Children.Clear();
        body.Children.Add(new ProgressRing { IsActive = true, Width = 28, Height = 28, HorizontalAlignment = HorizontalAlignment.Left, VerticalAlignment = VerticalAlignment.Top, Margin = new Thickness(32, 20, 0, 0) });
        OpenDetail();
        UIElement el;
        try { el = await p.Make(); } catch (Exception e) { el = T.Txt(e.Message, 13, T.Danger); }
        if (current != key) return;
        if (el is FrameworkElement fe && fe.Parent is Panel pp) pp.Children.Remove(fe);
        body.Children.Clear();
        UIElement view = el is IFillPage ? el : new ScrollViewer
        {
            Content = new Border { Padding = new Thickness(28, 4, 28, 28), MaxWidth = 760, HorizontalAlignment = HorizontalAlignment.Stretch, Child = el },
            VerticalScrollBarVisibility = ScrollBarVisibility.Auto, HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled,
        };
        if (wasOpen) { view.Opacity = 0; view.RenderTransform = new TranslateTransform(); }
        body.Children.Add(view);
        if (wasOpen) Fade(view, true, 24);
    }

    // ---------- разделы ----------

    Task<UIElement> ProfilePanel()
    {
        var me = Store.Me!;
        var sp = new StackPanel { Spacing = 12 };
        var first = new TextBox { Header = "Имя", Text = me.FirstName };
        var last = new TextBox { Header = "Фамилия", Text = me.LastName };
        var user = new TextBox { Header = "Юзернейм", Text = me.Username };
        var bio = new TextBox { Header = "О себе", Text = me.Bio, AcceptsReturn = true, TextWrapping = TextWrapping.Wrap, Height = 90, MaxLength = 140 };
        sp.Children.Add(first); sp.Children.Add(last); sp.Children.Add(user); sp.Children.Add(bio);
        sp.Children.Add(T.Txt("Юзернейм — 5–32 символа: латиница, цифры и «_». По нему вас найдут в поиске.", 12, T.Muted));
        var save = T.Primary("Сохранить", () => { });
        save.HorizontalAlignment = HorizontalAlignment.Left;
        save.Click += async (_, _) =>
        {
            save.IsEnabled = false;
            var err = await Store.SaveProfile(first.Text, last.Text, bio.Text, user.Text);
            Store.Say(err ?? "Сохранено");
            save.IsEnabled = true;
            RefreshHero();
        };
        sp.Children.Add(save);
        var enc = E2E.Status == E2E.State.Ready ? "Сквозное шифрование включено: ключ сохранён на этом компьютере" : "Ключ шифрования не восстановлен — личные чаты не читаются";
        sp.Children.Add(T.Txt(enc, 12, E2E.Status == E2E.State.Ready ? T.Muted : T.Danger));
        return Task.FromResult<UIElement>(sp);
    }

    Task<UIElement> DataPanel()
    {
        var sp = new StackPanel { Spacing = 12 };
        long size = 0; int files = 0;
        try { foreach (var f in new DirectoryInfo(Media.CacheDir).EnumerateFiles("*", SearchOption.AllDirectories)) { size += f.Length; files++; } } catch { }
        var card = new Border { Background = T.Panel2, CornerRadius = new CornerRadius(14), Padding = new Thickness(16) };
        var cs = new StackPanel { Spacing = 4 };
        cs.Children.Add(T.Txt("Кэш на этом компьютере", 13, T.Muted));
        var sizeT = T.Txt(Fmt.Size(size), 28, T.Text, bold: true);
        cs.Children.Add(sizeT);
        cs.Children.Add(T.Txt($"Файлов: {files}. Фото, видео и документы из чатов, которые вы открывали.", 12.5, T.Muted));
        card.Child = cs; sp.Children.Add(card);
        var clear = T.Primary("Очистить кэш", () => { });
        clear.HorizontalAlignment = HorizontalAlignment.Left;
        clear.Click += async (_, _) =>
        {
            if (!await Dialogs.Confirm(win, "Очистить кэш?", "Очистить", "Файлы останутся в чатах и скачаются снова, когда понадобятся")) return;
            try { foreach (var f in new DirectoryInfo(Media.CacheDir).EnumerateFiles("*", SearchOption.AllDirectories)) try { f.Delete(); } catch { } } catch { }
            sizeT.Text = Fmt.Size(0); Store.Say("Кэш очищен");
        };
        sp.Children.Add(clear);
        var open = new HyperlinkButton { Content = "Открыть папку загрузок", Padding = new Thickness(0) };
        open.Click += (_, _) => Browser.Shell(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), "Downloads"));
        sp.Children.Add(open);
        return Task.FromResult<UIElement>(sp);
    }

    Task<UIElement> AboutPanel()
    {
        var sp = new StackPanel { Spacing = 12 };
        var logo = new Border { Width = 64, Height = 64, CornerRadius = new CornerRadius(18), Background = T.Accent, HorizontalAlignment = HorizontalAlignment.Left, Child = T.Txt("L", 30, T.White, bold: true) };
        ((TextBlock)logo.Child).HorizontalAlignment = HorizontalAlignment.Center; ((TextBlock)logo.Child).VerticalAlignment = VerticalAlignment.Center;
        sp.Children.Add(logo);
        sp.Children.Add(T.Txt("Lumo для Windows", 18, bold: true));
        sp.Children.Add(T.Txt("Версия " + Updater.VersionText, 13, T.Muted));
        var st = T.Txt(Updater.Available ? $"Доступна версия 1.0.{Updater.Latest}" : "", 13, T.A2);
        sp.Children.Add(st);
        var row = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 10 };
        var check = T.Primary(Updater.Available ? "Обновить Lumo" : "Проверить обновления", () => { });
        check.Click += async (_, _) =>
        {
            if (Updater.Available) { await Updater.Install(); return; }
            check.IsEnabled = false; st.Text = "Проверяем…";
            await Updater.Check();
            check.IsEnabled = true;
            if (Updater.Available) { st.Text = $"Доступна версия 1.0.{Updater.Latest}"; ((TextBlock)check.Content).Text = "Обновить Lumo"; }
            else st.Text = "У вас последняя версия";
        };
        row.Children.Add(check);
        sp.Children.Add(row);
        var docs = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 16 };
        var pol = new HyperlinkButton { Content = "Политика конфиденциальности", Padding = new Thickness(0) };
        pol.Click += async (_, _) => await Dialogs.Policy(win);
        var site = new HyperlinkButton { Content = "lumomess.ru", Padding = new Thickness(0) };
        site.Click += (_, _) => Browser.Open(new Uri("https://lumomess.ru"));
        docs.Children.Add(pol); docs.Children.Add(site);
        sp.Children.Add(docs);
        return Task.FromResult<UIElement>(sp);
    }

    // ---------- действия ----------

    async void ChangePhoto()
    {
        if (await AvatarCrop.PickAndSet(win)) RefreshHero();
    }

    void CopyLink()
    {
        var dp = new Windows.ApplicationModel.DataTransfer.DataPackage();
        dp.SetText("https://lumomess.ru/#@" + (Store.Me?.Username ?? ""));
        Windows.ApplicationModel.DataTransfer.Clipboard.SetContent(dp);
        Store.Say("Ссылка на профиль скопирована");
    }

    void OpenSaved()
    {
        var c = Store.Chats.FirstOrDefault(x => x.IsSaved);
        if (c != null) { shell.CloseSettings(); shell.Open(c.Id); } else Store.Say("Избранное появится после первого сохранённого сообщения");
    }

    async void Logout()
    {
        if (await Dialogs.Confirm(win, "Выйти из аккаунта на этом компьютере?", "Выйти")) await Api.SignOut();
    }
}


/// <summary>Разделитель между панелями: тянем мышью — меняем ширину</summary>
public sealed class SplitBar : Grid
{
    double lastX; bool drag;
    public SplitBar(Action<double> onDrag, Action onDone)
    {
        Background = T.Transparent; Width = 6;
        Children.Add(new Border { Width = 1, Background = T.Line, HorizontalAlignment = HorizontalAlignment.Center });
        var grip = new Border { Width = 4, Height = 44, CornerRadius = new CornerRadius(2), Background = T.B(0x33FFFFFF), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center, Opacity = 0 };
        Children.Add(grip);
        ProtectedCursor = Microsoft.UI.Input.InputSystemCursor.Create(Microsoft.UI.Input.InputSystemCursorShape.SizeWestEast);
        PointerEntered += (_, _) => grip.Opacity = 1;
        PointerExited += (_, _) => { if (!drag) grip.Opacity = 0; };
        PointerPressed += (_, e) => { drag = true; lastX = e.GetCurrentPoint(null).Position.X; CapturePointer(e.Pointer); e.Handled = true; };
        PointerMoved += (_, e) => { if (!drag) return; var x = e.GetCurrentPoint(null).Position.X; onDrag(x - lastX); lastX = x; };
        PointerReleased += (_, e) => { if (!drag) return; drag = false; ReleasePointerCapture(e.Pointer); grip.Opacity = 0; onDone(); };
        PointerCaptureLost += (_, _) => { if (drag) { drag = false; onDone(); } };
    }
}
