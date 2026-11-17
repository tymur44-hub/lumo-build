using Lumo.Core;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Media.Animation;

namespace Lumo.UI;

/// <summary>
/// Настройки для ПК: слева — карточка профиля и разделы с цветными иконками (как в мобильной версии),
/// справа — содержимое выбранного раздела.
/// </summary>
public sealed class SettingsPage : Grid
{
    readonly MainWindow win;
    readonly ShellView shell;
    readonly Grid content = new() { Padding = new Thickness(28, 20, 28, 20) };
    readonly TextBlock pageTitle = T.Txt("", 22, bold: true);
    readonly ContentControl pageHost = new() { HorizontalContentAlignment = HorizontalAlignment.Stretch, VerticalContentAlignment = VerticalAlignment.Stretch };
    readonly Dictionary<string, Grid> rows = new();
    readonly AvatarView heroAv = new(76);
    readonly TextBlock heroName = T.Txt("", 18, bold: true, lines: 1), heroUser = T.Txt("", 13, T.Muted, lines: 1);
    string? current;

    record Item(string Key, string Glyph, uint Color, string Title, string Sub, Func<Task<UIElement>>? Page, Action? Act = null);

    public SettingsPage(MainWindow w, ShellView s)
    {
        win = w; shell = s;
        Background = T.ChatBg;
        ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(340) });
        ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

        // ---- левая колонка: профиль и меню ----
        var menu = new StackPanel { Spacing = 12, Padding = new Thickness(14, 16, 14, 24) };
        var hero = new StackPanel { Spacing = 6, HorizontalAlignment = HorizontalAlignment.Center, Margin = new Thickness(0, 4, 0, 6) };
        heroAv.HorizontalAlignment = HorizontalAlignment.Center;
        hero.Children.Add(heroAv);
        heroName.HorizontalAlignment = HorizontalAlignment.Center; heroUser.HorizontalAlignment = HorizontalAlignment.Center;
        hero.Children.Add(heroName); hero.Children.Add(heroUser);
        var heroBtns = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 8, HorizontalAlignment = HorizontalAlignment.Center, Margin = new Thickness(0, 6, 0, 0) };
        heroBtns.Children.Add(Pill("", "Фото", ChangePhoto));
        heroBtns.Children.Add(Pill("", "Изменить", () => Select("profile")));
        heroBtns.Children.Add(Pill("", "Ссылка", CopyLink));
        hero.Children.Add(heroBtns);
        menu.Children.Add(hero);

        var groups = new List<Item[]>
        {
            new Item[]
            {
                new("profile", "", 0xFF7C5CFF, "Мой профиль", "Имя, юзернейм, о себе", ProfilePanel),
                new("saved", "", 0xFF3A7BFF, "Избранное", "Заметки и сохранённые сообщения", null, OpenSaved),
                new("calls", "", 0xFF2BD67B, "Недавние звонки", "Недавние и пропущенные", null, () => _ = CallsSheet.Show(shell.Open)),
                new("devices", "", 0xFFFF9F1A, "Устройства", "Активные сеансы", Dialogs.DevicesPanel),
            },
            new Item[]
            {
                new("notify", "", 0xFFFF5B5B, "Уведомления и звуки", "Сообщения, текст, панель задач", () => Task.FromResult(Dialogs.NotifyPanel())),
                new("privacy", "", 0xFF8E8EA8, "Конфиденциальность", "Время захода, звонки, блокировки", Dialogs.PrivacyPanel),
                new("data", "", 0xFF4CC764, "Данные и память", "Кэш файлов на этом компьютере", DataPanel),
            },
            new Item[]
            {
                new("wallet", "", 0xFFF5B942, "Люмены и Premium", "Баланс, ежедневный бонус", Dialogs.WalletPanel),
                new("gifts", "", 0xFF2BC4A8, "Подарки", "Коллекционные подарки за люмены", GiftsPanel),
            },
            new Item[]
            {
                new("about", "", 0xFF8E8EA8, "О Lumo", "Версия " + Updater.VersionText + ", обновления", AboutPanel),
                new("logout", "", 0xFFFF3B5C, "Выйти из аккаунта", "", null, Logout),
            },
        };
        foreach (var g in groups) menu.Children.Add(Group(g));
        var left = new ScrollViewer { Content = menu, VerticalScrollBarVisibility = ScrollBarVisibility.Auto, Background = T.Panel, BorderBrush = T.Line, BorderThickness = new Thickness(0, 0, 1, 0) };
        Children.Add(left);

        // ---- правая колонка ----
        var rg = new Grid { RowSpacing = 14 };
        rg.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        rg.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
        var head = new Grid();
        head.Children.Add(pageTitle);
        var close = T.IconButton("", "Закрыть настройки (Esc)", () => shell.CloseChat());
        close.HorizontalAlignment = HorizontalAlignment.Right; head.Children.Add(close);
        rg.Children.Add(head);
        var sv = new ScrollViewer { Content = pageHost, VerticalScrollBarVisibility = ScrollBarVisibility.Auto, HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled };
        Grid.SetRow(sv, 1); rg.Children.Add(sv);
        content.Children.Add(rg);
        content.MaxWidth = 760; content.HorizontalAlignment = HorizontalAlignment.Left;
        SetColumn(content, 1); Children.Add(content);

        RefreshHero();
        Loaded += async (_, _) => { await Store.LoadMe(); RefreshHero(); };
        Select("profile");
    }

    void RefreshHero()
    {
        var me = Store.Me; if (me == null) return;
        heroAv.Set(me.Name, me.AvatarUrl, me.Color);
        heroName.Text = me.Name + (me.Premium ? "  ★" : "");
        heroName.Text = me.Name;
        heroUser.Text = "@" + me.Username;
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
        current = key;
        foreach (var (k, r) in rows) r.Background = k == key ? T.Selected : T.Transparent;
        pageTitle.Text = p.Title;
        pageHost.Content = new ProgressRing { IsActive = true, Width = 28, Height = 28, HorizontalAlignment = HorizontalAlignment.Left, Margin = new Thickness(4, 20, 0, 0) };
        UIElement el;
        try { el = await p.Make(); } catch (Exception e) { el = T.Txt(e.Message, 13, T.Danger); }
        if (current != key) return;
        if (el is FrameworkElement fe && fe.Parent is Panel pp) pp.Children.Remove(fe);
        el.Opacity = 0;
        el.Transitions = new TransitionCollection { new EntranceThemeTransition { FromHorizontalOffset = 24 } };
        pageHost.Content = el;
        el.Opacity = 1;
    }

    // ---------- разделы ----------

    Task<UIElement> ProfilePanel()
    {
        var me = Store.Me!;
        var sp = new StackPanel { Spacing = 12, MaxWidth = 520, HorizontalAlignment = HorizontalAlignment.Left };
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

    async Task<UIElement> GiftsPanel()
    {
        var sp = new StackPanel { Spacing = 14 };
        var top = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 10 };
        var shop = T.Primary("Магазин подарков", () => { });
        shop.Click += async (_, _) => { await Gifts.ShowShop(null); Select("gifts"); };
        top.Children.Add(shop);
        sp.Children.Add(top);
        sp.Children.Add(T.Txt("Мои подарки", 13, T.Muted, bold: true));
        sp.Children.Add(await Gifts.OwnedPanel(null, true));
        return sp;
    }

    Task<UIElement> DataPanel()
    {
        var sp = new StackPanel { Spacing = 12, MaxWidth = 520, HorizontalAlignment = HorizontalAlignment.Left };
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
        var sp = new StackPanel { Spacing = 12, MaxWidth = 520, HorizontalAlignment = HorizontalAlignment.Left };
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
        var p = new Windows.Storage.Pickers.FileOpenPicker();
        WinRT.Interop.InitializeWithWindow.Initialize(p, win.Hwnd);
        foreach (var e in new[] { ".jpg", ".jpeg", ".png", ".webp" }) p.FileTypeFilter.Add(e);
        var f = await p.PickSingleFileAsync();
        if (f == null) return;
        var ext = Path.GetExtension(f.Path).TrimStart('.').ToLowerInvariant();
        var err = await Store.SetAvatar(await File.ReadAllBytesAsync(f.Path), ext, Store.Mime(ext));
        if (err != null) Store.Say(err); else { RefreshHero(); Store.Say("Фото обновлено"); }
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
        if (c != null) shell.Open(c.Id); else Store.Say("Избранное появится после первого сохранённого сообщения");
    }

    async void Logout()
    {
        if (await Dialogs.Confirm(win, "Выйти из аккаунта на этом компьютере?", "Выйти")) await Api.SignOut();
    }
}
