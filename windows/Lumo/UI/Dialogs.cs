using Lumo.Core;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Media.Imaging;

namespace Lumo.UI;

/// <summary>Окна: настройки и профиль, сведения о чате, пересылка, подтверждения, поиск по чату, ключи шифрования</summary>
public static class Dialogs
{
    
    static Sheet Make(MainWindow w, string title, object content, string? primary = null, string? close = "Закрыть", string? secondary = null, bool danger = false)
    {
        var d = new Sheet { Title = title, Content = content, CloseButtonText = close ?? "", DangerSecondary = danger };
        if (primary != null) d.PrimaryButtonText = primary;
        if (secondary != null) d.SecondaryButtonText = secondary;
        if (content is FrameworkElement fe && fe.Width > 0 && !double.IsNaN(fe.Width)) d.Width = fe.Width + 46;
        return d;
    }

    static async Task<ContentDialogResult> Show(Sheet d)
    {
        try { return await d.ShowAsync(); }
        catch (Exception e) { App.Log("sheet: " + e.Message); return ContentDialogResult.None; }
    }

    public static async Task<bool> Confirm(MainWindow w, string text, string yes, string? sub = null)
    {
        var d = Make(w, text, T.Txt(sub ?? "Это действие нельзя отменить.", 13, T.Muted), yes, "Отмена");
        return await Show(d) == ContentDialogResult.Primary;
    }

    // ---------- мой профиль и настройки ----------

    public static async Task Settings(MainWindow w)
    {
        var me = Store.Me;
        if (me == null) { await Store.LoadMe(); me = Store.Me; if (me == null) return; }
        var sp = new StackPanel { Spacing = 10 };
        var top = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 16 };
        var av = new AvatarView(84); av.Set(me.Name, me.AvatarUrl, me.Color);
        top.Children.Add(av);
        var ts = new StackPanel { VerticalAlignment = VerticalAlignment.Center, Spacing = 4 };
        ts.Children.Add(T.Txt(me.Name, 18, bold: true, lines: 1));
        ts.Children.Add(T.Txt("@" + me.Username, 13, T.Muted));
        var photo = new HyperlinkButton { Content = "Изменить фото", Padding = new Thickness(0) };
        photo.Click += async (_, _) =>
        {
            var p = new Windows.Storage.Pickers.FileOpenPicker();
            WinRT.Interop.InitializeWithWindow.Initialize(p, w.Hwnd);
            foreach (var e in new[] { ".jpg", ".jpeg", ".png", ".webp" }) p.FileTypeFilter.Add(e);
            var f = await p.PickSingleFileAsync();
            if (f == null) return;
            var ext = Path.GetExtension(f.Path).TrimStart('.').ToLowerInvariant();
            var err = await Store.SetAvatar(await File.ReadAllBytesAsync(f.Path), ext, Store.Mime(ext));
            if (err != null) Store.Say(err); else { av.Set(Store.Me!.Name, Store.Me.AvatarUrl, Store.Me.Color); Store.Say("Фото обновлено"); }
        };
        ts.Children.Add(photo);
        top.Children.Add(ts);
        sp.Children.Add(top);
        var first = new TextBox { Header = "Имя", Text = me.FirstName };
        var last = new TextBox { Header = "Фамилия", Text = me.LastName };
        var user = new TextBox { Header = "Юзернейм", Text = me.Username };
        var bio = new TextBox { Header = "О себе", Text = me.Bio, AcceptsReturn = true, TextWrapping = TextWrapping.Wrap, Height = 80 };
        sp.Children.Add(first); sp.Children.Add(last); sp.Children.Add(user); sp.Children.Add(bio);
        var enc = E2E.Status == E2E.State.Ready ? "Сквозное шифрование включено: ключ сохранён на этом компьютере" : "Ключ шифрования не восстановлен — личные чаты не читаются";
        sp.Children.Add(T.Txt(enc, 12, E2E.Status == E2E.State.Ready ? T.Muted : T.Danger));
        sp.Children.Add(T.Txt("Lumo для Windows 1.0", 12, T.Muted));

        // разделы настроек
        var root = new StackPanel { Spacing = 14, Width = 500 };
        var seg = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 4 };
        var host = new Grid { MinHeight = 420 };
        var sections = new (string name, Func<Task<UIElement>> make)[]
        {
            ("Профиль", () => Task.FromResult<UIElement>(sp)),
            ("Приватность", () => PrivacyPanel()),
            ("Устройства", () => DevicesPanel()),
            ("Люмены", () => WalletPanel()),
            ("Уведомления", () => Task.FromResult(NotifyPanel())),
        };
        var segBtns = new List<Button>();
        async Task Select(int i)
        {
            for (int k = 0; k < segBtns.Count; k++) { T.Fill(segBtns[k], k == i ? T.Accent : T.Panel2, k == i ? T.Accent : T.B(0xFF24264A)); ((TextBlock)segBtns[k].Content).Foreground = k == i ? T.White : T.Muted; }
            host.Children.Clear();
            host.Children.Add(new ProgressRing { IsActive = true, Width = 26, Height = 26, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Top, Margin = new Thickness(0, 30, 0, 0) });
            UIElement el;
            try { el = await sections[i].make(); } catch (Exception ex) { el = T.Txt(ex.Message, 13, T.Danger); }
            host.Children.Clear();
            if (el is FrameworkElement fe && fe.Parent is Panel pp) pp.Children.Remove(fe);
            host.Children.Add(el);
        }
        for (int i = 0; i < sections.Length; i++)
        {
            var b = new Button { Content = new TextBlock { Text = sections[i].name, FontSize = 13, FontWeight = Microsoft.UI.Text.FontWeights.SemiBold }, Height = 32, Padding = new Thickness(10, 0, 10, 0), CornerRadius = new CornerRadius(16), BorderThickness = new Thickness(0) };
            var idx = i;
            b.Click += async (_, _) => await Select(idx);
            segBtns.Add(b); seg.Children.Add(b);
        }
        root.Children.Add(new ScrollViewer { Content = seg, HorizontalScrollBarVisibility = ScrollBarVisibility.Hidden, HorizontalScrollMode = ScrollMode.Enabled, VerticalScrollBarVisibility = ScrollBarVisibility.Disabled, VerticalScrollMode = ScrollMode.Disabled });
        root.Children.Add(host);
        _ = Select(0);
        var d = Make(w, "Настройки", root, "Сохранить", "Закрыть", "Выйти из аккаунта", true);
        var r = await Show(d);
        if (r == ContentDialogResult.Primary)
        {
            var err = await Store.SaveProfile(first.Text, last.Text, bio.Text, user.Text);
            Store.Say(err ?? "Сохранено");
        }
        else if (r == ContentDialogResult.Secondary)
        {
            if (await Confirm(w, "Выйти из аккаунта на этом компьютере?", "Выйти")) await Api.SignOut();
        }
    }


    static string PrivName(string v) => v switch { "contacts" => "Мои контакты", "none" => "Никто", _ => "Все" };

    static async Task<UIElement> PrivacyPanel()
    {
        await Store.LoadMe();
        var me = Store.Me!;
        var sp = new StackPanel { Spacing = 12 };
        sp.Children.Add(T.Txt("Кто может видеть и делать", 12, T.Muted, bold: true));
        var keys = new[] { ("seen", "Время захода и «в сети»"), ("calls", "Звонить мне"), ("birthday", "День рождения"), ("phone", "Номер телефона") };
        foreach (var (k, label) in keys)
        {
            var cur = me.Privacy.Str(k) ?? (k == "seen" ? (me.ShowSeen ? "all" : "none") : k == "phone" ? "contacts" : "all");
            var cb = new ComboBox { Header = label, HorizontalAlignment = HorizontalAlignment.Stretch };
            var vals = new[] { "all", "contacts", "none" };
            foreach (var v in vals) cb.Items.Add(PrivName(v));
            cb.SelectedIndex = Math.Max(0, Array.IndexOf(vals, cur));
            var key = k;
            cb.SelectionChanged += async (_, _) =>
            {
                try { await Api.Rpc("lm_set_privacy", J.O(("p_key", key), ("p_value", vals[cb.SelectedIndex]))); await Store.LoadMe(); }
                catch (Exception e) { Store.Say(e.Message); }
            };
            sp.Children.Add(cb);
        }
        var docs = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 16 };
        var pol = new HyperlinkButton { Content = "Политика конфиденциальности", Padding = new Thickness(0) };
        pol.Click += async (_, _) => { Sheet.CloseTop(); await Task.Delay(250); await Policy(App.Win); };
        var del = new HyperlinkButton { Content = "Удалить аккаунт", Padding = new Thickness(0), Foreground = T.Danger };
        del.Click += async (_, _) => { Sheet.CloseTop(); await Task.Delay(250); if (App.Win != null) await DeleteAccount(App.Win); };
        docs.Children.Add(pol); docs.Children.Add(del);
        sp.Children.Add(docs);
        sp.Children.Add(T.Txt("Чёрный список", 12, T.Muted, bold: true));
        var blocked = new StackPanel { Spacing = 6 };
        sp.Children.Add(blocked);
        try
        {
            var j = await Api.Rpc("lm_my_blocks");
            var ids = j.Arr("mine")?.Select(x => x is System.Text.Json.Nodes.JsonValue v && v.TryGetValue<string>(out var s2) ? s2 : null).Where(x => x != null).Select(x => x!).ToList() ?? new();
            await Store.LoadProfiles(ids);
            if (ids.Count == 0) blocked.Children.Add(T.Txt("Никого нет", 13, T.Muted));
            foreach (var id in ids)
            {
                var row = new Grid { ColumnSpacing = 10 };
                row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
                row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
                var n = T.Txt(Store.DisplayName(id), 14, lines: 1); n.VerticalAlignment = VerticalAlignment.Center; row.Children.Add(n);
                var ub = new HyperlinkButton { Content = "Разблокировать" };
                var uid = id;
                ub.Click += async (_, _) => { try { await Api.Rpc("lm_block", J.O(("p_user", uid), ("p_on", false))); blocked.Children.Remove(row); } catch (Exception e) { Store.Say(e.Message); } };
                Grid.SetColumn(ub, 1); row.Children.Add(ub);
                blocked.Children.Add(row);
            }
        }
        catch { blocked.Children.Add(T.Txt("Не удалось загрузить", 13, T.Muted)); }
        return sp;
    }

    static async Task<UIElement> DevicesPanel()
    {
        var sp = new StackPanel { Spacing = 8 };
        sp.Children.Add(T.Txt("Где выполнен вход в ваш аккаунт", 12, T.Muted, bold: true));
        var mine = Prefs.Get("device_id");
        List<System.Text.Json.Nodes.JsonObject> rows;
        try { rows = await Api.Select("lm_sessions", Api.Q(("select", "id,device_id,name,platform,app_version,last_active,revoked"), ("order", "last_active.desc"))); }
        catch (Exception e) { sp.Children.Add(T.Txt(e.Message, 13, T.Danger)); return sp; }
        foreach (var r in rows.Where(x => !x.Bool("revoked")))
        {
            var g = new Grid { ColumnSpacing = 12, Padding = new Thickness(12, 10, 12, 10), CornerRadius = new CornerRadius(14), Background = T.Panel2 };
            g.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            g.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            g.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            var plat = r.Str("platform") ?? "";
            var ic = T.Icon(plat switch { "windows" or "web" or "desktop" => "\uE7F8", _ => "\uE8EA" }, 20, T.A2); ic.VerticalAlignment = VerticalAlignment.Center;
            g.Children.Add(ic);
            var tx = new StackPanel();
            var current = r.Str("device_id") == mine;
            tx.Children.Add(T.Txt((r.Str("name") ?? plat) + (current ? " · это устройство" : ""), 14, bold: true, lines: 1));
            tx.Children.Add(T.Txt(plat + " " + (r.Str("app_version") ?? "") + " · " + Fmt.ListTime(r.Date("last_active")), 12, T.Muted, lines: 1));
            Grid.SetColumn(tx, 1); g.Children.Add(tx);
            if (!current)
            {
                var kill = new HyperlinkButton { Content = "Завершить", VerticalAlignment = VerticalAlignment.Center, Foreground = T.Danger };
                var sid = r.Str("id");
                kill.Click += async (_, _) => { try { await Api.Rpc("lm_session_kill", J.O(("p_id", sid))); sp.Children.Remove(g); Store.Say("Сеанс завершён"); } catch (Exception e) { Store.Say(e.Message); } };
                Grid.SetColumn(kill, 2); g.Children.Add(kill);
            }
            sp.Children.Add(g);
        }
        return sp;
    }

    static async Task<UIElement> WalletPanel()
    {
        var sp = new StackPanel { Spacing = 12 };
        var me = Store.Me;
        var prem = new Border { CornerRadius = new CornerRadius(16), Padding = new Thickness(16), Background = me?.Premium == true ? T.Grad(0xFF7C5CFF, 0xFFFF5B8A) : T.Panel2 };
        var ps = new StackPanel { Spacing = 4 };
        ps.Children.Add(T.Txt("Lumo Premium", 16, T.White, bold: true));
        ps.Children.Add(T.Txt(me?.Premium == true ? "Подписка активна: 3 реакции, файлы до 200 МБ, эксклюзивные цвета и многое другое" : "Оформить подписку можно в приложении Lumo на телефоне", 12.5, me?.Premium == true ? T.White : T.Muted));
        prem.Child = ps;
        sp.Children.Add(prem);
        try
        {
            var j = await Api.Rpc("lm_wallet_me");
            var bal = j.Long("balance") ?? 0; var streak = j.Int("streak") ?? 0; var can = j.Bool("can_claim");
            var card = new Border { CornerRadius = new CornerRadius(16), Padding = new Thickness(16), Background = T.Panel2 };
            var cs = new StackPanel { Spacing = 6 };
            cs.Children.Add(T.Txt("Люмены", 13, T.Muted));
            var balT = T.Txt(bal.ToString("N0", new System.Globalization.CultureInfo("ru-RU")), 30, T.B(0xFFF5B942), bold: true);
            cs.Children.Add(balT);
            cs.Children.Add(T.Txt("Серия ежедневных бонусов: " + streak + " " + Fmt.Plural(streak, "день", "дня", "дней"), 12.5, T.Muted));
            if (can)
            {
                var b = T.Primary("Получить ежедневный бонус", () => { });
                b.Click += async (_, _) =>
                {
                    try { var r = await Api.Rpc("lm_wallet_daily"); Store.Say("Получено люменов: " + (r.Int("amount") ?? 0)); b.Visibility = Visibility.Collapsed;
                        var j2 = await Api.Rpc("lm_wallet_me"); balT.Text = (j2.Long("balance") ?? bal).ToString("N0", new System.Globalization.CultureInfo("ru-RU")); }
                    catch (Exception e) { Store.Say(e.Message); }
                };
                cs.Children.Add(b);
            }
            card.Child = cs;
            sp.Children.Add(card);
            sp.Children.Add(T.Txt("Люмены можно дарить за посты, ставить в играх и получать за приглашённых друзей.", 12, T.Muted));
        }
        catch { sp.Children.Add(T.Txt("Не удалось загрузить кошелёк", 13, T.Muted)); }
        return sp;
    }

    static UIElement NotifyPanel()
    {
        var sp = new StackPanel { Spacing = 10 };
        var on = new ToggleSwitch { Header = "Уведомления о новых сообщениях", IsOn = Prefs.GetBool("notify_on", true), OnContent = "Включены", OffContent = "Выключены" };
        on.Toggled += (_, _) => Prefs.Set("notify_on", on.IsOn);
        var prev = new ToggleSwitch { Header = "Показывать текст сообщения", IsOn = Prefs.GetBool("notify_preview", true), OnContent = "Да", OffContent = "Нет" };
        prev.Toggled += (_, _) => Prefs.Set("notify_preview", prev.IsOn);
        var flash = new ToggleSwitch { Header = "Мигать кнопкой на панели задач", IsOn = Prefs.GetBool("notify_flash", true), OnContent = "Да", OffContent = "Нет" };
        flash.Toggled += (_, _) => Prefs.Set("notify_flash", flash.IsOn);
        sp.Children.Add(on); sp.Children.Add(prev); sp.Children.Add(flash);
        sp.Children.Add(T.Txt("Звук и «Не беспокоить» настраиваются в Параметрах Windows → Система → Уведомления.", 12, T.Muted));
        return sp;
    }

    // ---------- сведения о чате ----------

    public static async Task ChatInfo(MainWindow w, ChatItem c)
    {
        var sp = new StackPanel { Spacing = 8, Width = 380, HorizontalAlignment = HorizontalAlignment.Center };
        var av = new AvatarView(96) { HorizontalAlignment = HorizontalAlignment.Center };
        var name = T.Txt(c.DisplayName, 20, bold: true); name.HorizontalAlignment = HorizontalAlignment.Center; name.TextAlignment = TextAlignment.Center;
        var stat = T.Txt(Store.Status(c), 13, T.Muted); stat.HorizontalAlignment = HorizontalAlignment.Center;
        sp.Children.Add(av); sp.Children.Add(name); sp.Children.Add(stat);
        av.Set(c.DisplayName, c.DisplayAvatar, c.DisplayColor);
        var details = new StackPanel { Spacing = 10, Margin = new Thickness(0, 12, 0, 0) };
        sp.Children.Add(details);
        void Row(string label, string value)
        {
            var r = new StackPanel { Spacing = 1 };
            var v = T.Txt(value, 14); v.IsTextSelectionEnabled = true;
            r.Children.Add(v); r.Children.Add(T.Txt(label, 12, T.Muted));
            details.Children.Add(r);
        }
        if (c.IsPrivate && c.PeerId != null)
        {
            var p = await Store.GetProfile(c.PeerId);
            if (p != null)
            {
                av.Set(p.Name, p.AvatarUrl, p.Color, Store.Online.Contains(p.Id));
                if (p.Verified) name.Text = p.Name + "  ·  подтверждён";
                if (p.Username.Length > 0) Row("Юзернейм", "@" + p.Username);
                if (p.Bio.Length > 0) Row("О себе", p.Bio);
                if (p.Birthday is { Length: >= 10 } bd && DateTime.TryParse(bd[..10], out var b)) Row("День рождения", b.ToString("d MMMM yyyy", new System.Globalization.CultureInfo("ru-RU")));
            }
        }
        else
        {
            if (!string.IsNullOrEmpty(c.Username)) Row("Ссылка", Config.SITE + c.Username);
            if (!string.IsNullOrEmpty(c.Description)) Row("Описание", c.Description);
        }
        var mute = new ToggleSwitch { Header = "Уведомления", IsOn = !c.Muted, OnContent = "Включены", OffContent = "Выключены" };
        mute.Toggled += async (_, _) => await Store.SetMuted(c.Id, !mute.IsOn);
        details.Children.Add(mute);
        Sheet? sheet = null;

        // действия
        var acts = new StackPanel { Spacing = 2, Margin = new Thickness(0, 6, 0, 0) };
        void Act(string text, string glyph, Func<Task> fn, bool danger = false)
        {
            var row = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 12 };
            row.Children.Add(T.Icon(glyph, 16, danger ? T.Danger : T.A2));
            row.Children.Add(new TextBlock { Text = text, FontSize = 14, Foreground = danger ? T.Danger : T.Text });
            var b = new Button { Content = row, HorizontalAlignment = HorizontalAlignment.Stretch, HorizontalContentAlignment = HorizontalAlignment.Left, Padding = new Thickness(12, 10, 12, 10), CornerRadius = new CornerRadius(12), BorderThickness = new Thickness(0) };
            T.Fill(b, T.Transparent, T.B(0x14FFFFFF));
            b.Click += async (_, _) => await fn();
            acts.Children.Add(b);
        }
        if (c.IsPrivate && c.PeerId != null && c.PeerId != Store.MyId)
        {
            var peer = c.PeerId;
            var contacts = await Store.ContactIds();
            if (!contacts.Contains(peer))
                Act("Добавить в контакты", "\uE8FA", async () => { try { await Api.InsertQuiet("lm_contacts", J.O(("contact_id", peer))); await Store.ContactIds(true); Store.Say("Добавлено в контакты"); } catch (Exception e2) { Store.Say(e2.Message); } });
            Act("Код шифрования", "\uE72E", async () => { sheet?.Hide(); await Task.Delay(200); await Safety(w, c); });
            Act("Заблокировать", "\uE8F8", async () =>
            {
                if (!await Confirm(w, "Заблокировать " + c.DisplayName + "?", "Заблокировать", "Человек не сможет писать вам и звонить.")) return;
                try { await Api.Rpc("lm_block", J.O(("p_user", peer), ("p_on", true))); Store.Say("Пользователь заблокирован"); } catch (Exception e2) { Store.Say(e2.Message); }
            }, true);
        }
        if (!c.IsPrivate)
        {
            Act(c.IsChannel ? "Подписчики" : "Участники", "\uE716", async () => { sheet?.Hide(); await Task.Delay(200); await Members(w, c); });
            if (c.IsAdmin) Act(c.IsChannel ? "Добавить подписчиков" : "Добавить участников", "\uE8FA", async () => { sheet?.Hide(); await Task.Delay(200); await AddMembers(w, c); });
            if (c.IsAdmin) Act("Ссылка-приглашение", "\uE71B", async () =>
            {
                try
                {
                    var code = (await Api.Rpc("lm_chat_invite", J.O(("p_chat", c.Id), ("p_reset", false))))?.GetValue<string>();
                    if (code == null) return;
                    var link = Config.SITE + "+" + code;
                    var dp = new Windows.ApplicationModel.DataTransfer.DataPackage(); dp.SetText(link);
                    Windows.ApplicationModel.DataTransfer.Clipboard.SetContent(dp);
                    Store.Say("Ссылка скопирована: " + link);
                }
                catch (Exception e2) { Store.Say(e2.Message); }
            });
        }
        Act(c.IsPrivate ? "Удалить чат" : c.IsChannel ? "Отписаться" : "Покинуть группу", "\uE74D", async () =>
        {
            var everyone = false;
            if (c.Role == "owner" && !c.IsPrivate)
            {
                if (!await Confirm(w, "Удалить " + (c.IsChannel ? "канал" : "группу") + " для всех?", "Удалить")) return;
                everyone = true;
            }
            else if (!await Confirm(w, c.IsPrivate ? "Удалить чат у себя?" : "Выйти из " + (c.IsChannel ? "канала" : "группы") + "?", c.IsPrivate ? "Удалить" : "Выйти")) return;
            sheet?.Hide();
            await Store.DeleteChat(c.Id, everyone);
            App.Win?.CloseChatView();
        }, true);
        sp.Children.Add(acts);
        sheet = Make(w, "", sp);
        await Show(sheet);
    }

    // ---------- участники ----------

    public static async Task Members(MainWindow w, ChatItem c)
    {
        var sp = new StackPanel { Spacing = 4, Width = 400 };
        sp.Children.Add(new ProgressRing { IsActive = true, Width = 24, Height = 24 });
        var sheet = Make(w, c.IsChannel ? "Подписчики" : "Участники", sp);
        var t = Show(sheet);
        try
        {
            var rows = await Api.Select("lm_members", Api.Q(("select", "user_id,role"), ("chat_id", "eq." + c.Id), ("limit", "500")));
            var list = rows.Select(r => (id: r.Str("user_id") ?? "", role: r.Str("role") ?? "member")).Where(x => x.id.Length > 0).ToList();
            await Store.LoadProfiles(list.Select(x => x.id));
            var order = new Dictionary<string, int> { ["owner"] = 0, ["admin"] = 1 };
            sp.Children.Clear();
            sp.Children.Add(T.Txt(list.Count + " " + Fmt.Plural(list.Count, "человек", "человека", "человек"), 12, T.Muted));
            foreach (var (id, role) in list.OrderBy(x => order.GetValueOrDefault(x.role, 2)).ThenBy(x => Store.DisplayName(x.id)))
            {
                var p = Store.Profiles.GetValueOrDefault(id);
                var g = new Grid { ColumnSpacing = 10, Padding = new Thickness(4, 6, 4, 6) };
                g.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
                g.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
                g.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
                var av = new AvatarView(36); av.Set(p?.Name ?? "?", p?.AvatarUrl, p?.Color ?? 0, Store.Online.Contains(id));
                g.Children.Add(av);
                var tx = new StackPanel { VerticalAlignment = VerticalAlignment.Center };
                tx.Children.Add(T.Txt(id == Store.MyId ? "Вы" : Store.DisplayName(id), 14, bold: true, lines: 1));
                tx.Children.Add(T.Txt(Store.Online.Contains(id) ? "в сети" : Fmt.LastSeen(p?.LastSeen, p?.ShowSeen ?? true), 12, T.Muted, lines: 1));
                Grid.SetColumn(tx, 1); g.Children.Add(tx);
                if (role is "owner" or "admin") { var r = T.Txt(role == "owner" ? "владелец" : "админ", 12, T.A2); r.VerticalAlignment = VerticalAlignment.Center; Grid.SetColumn(r, 2); g.Children.Add(r); }
                if (id != Store.MyId)
                {
                    g.Background = T.Transparent;
                    var uid = id;
                    g.Tapped += async (_, _) => { sheet.Hide(); var cid = await Store.OpenDm(uid); if (cid != null) w.OpenChat(cid); };
                }
                sp.Children.Add(g);
            }
        }
        catch (Exception e) { sp.Children.Clear(); sp.Children.Add(T.Txt(e.Message, 13, T.Danger)); }
        await t;
    }

    public static async Task AddMembers(MainWindow w, ChatItem c)
    {
        var sp = new StackPanel { Spacing = 8, Width = 400 };
        sp.Children.Add(T.Txt("Выберите из своих личных чатов", 12, T.Muted));
        var lv = ChatPicker(Store.Chats.Where(x => x.IsPrivate && x.PeerId != null && x.PeerId != Store.MyId && !x.PeerBot), Array.Empty<string>(), 340);
        sp.Children.Add(lv);
        if (await Show(Make(w, c.IsChannel ? "Добавить подписчиков" : "Добавить участников", sp, "Добавить", "Отмена")) != ContentDialogResult.Primary) return;
        var ids = Picked(lv).Select(id => Store.Chat(id)?.PeerId).Where(x => x != null).Select(x => x!).ToList();
        if (ids.Count == 0) return;
        try { await Api.Rpc("lm_add_members", J.O(("p_chat", c.Id), ("p_members", ids))); await Store.LoadChats(); Store.Say("Добавлено: " + ids.Count); }
        catch (Exception e) { Store.Say(e.Message); }
    }

    public static async Task Safety(MainWindow w, ChatItem c)
    {
        if (c.PeerId == null) return;
        await E2E.Prepare(c.Id, c.PeerId);
        var code = E2E.Safety(c.PeerId);
        var sp = new StackPanel { Spacing = 10, Width = 360 };
        sp.Children.Add(T.Txt("Сравните код с собеседником при встрече или по звонку. Если коды совпадают — переписку никто не перехватывает.", 13, T.Muted));
        var t = T.Txt(code ?? "Ключ собеседника ещё не получен", 22, T.Text, bold: true);
        t.FontFamily = new FontFamily("Consolas"); t.IsTextSelectionEnabled = true; t.TextAlignment = TextAlignment.Center;
        sp.Children.Add(t);
        if (E2E.KeyChanged.Contains(c.PeerId)) sp.Children.Add(T.Txt("Ключ собеседника менялся (новое устройство или сброс).", 12, T.Danger));
        await Show(Make(w, "Код шифрования", sp));
    }

    // ---------- пересылка ----------

    public static async Task Forward(MainWindow w, List<Message> msgs)
    {
        var lv = new ListView { SelectionMode = ListViewSelectionMode.Multiple, Height = 380, Width = 380 };
        var filter = new TextBox { PlaceholderText = "Поиск чата" };
        var hide = new CheckBox { Content = "Скрыть автора" };
        void Fill()
        {
            lv.Items.Clear();
            var q = filter.Text.Trim().ToLowerInvariant();
            foreach (var c in Store.Chats.Where(c => c.CanPost && (q.Length == 0 || c.DisplayName.ToLowerInvariant().Contains(q))))
            {
                var g = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 10, Tag = c.Id, Padding = new Thickness(0, 4, 0, 4) };
                var av = new AvatarView(34); av.Set(c.DisplayName, c.DisplayAvatar, c.DisplayColor);
                g.Children.Add(av);
                var n = T.Txt(c.PeerId == Store.MyId && c.IsPrivate ? "Избранное" : c.DisplayName, 14, lines: 1); n.VerticalAlignment = VerticalAlignment.Center;
                g.Children.Add(n);
                lv.Items.Add(g);
            }
        }
        filter.TextChanged += (_, _) => Fill();
        Fill();
        var sp = new StackPanel { Spacing = 8 };
        sp.Children.Add(filter); sp.Children.Add(lv); sp.Children.Add(hide);
        if (await Show(Make(w, "Переслать", sp, "Переслать", "Отмена")) != ContentDialogResult.Primary) return;
        var to = lv.SelectedItems.OfType<FrameworkElement>().Select(x => x.Tag as string).Where(x => x != null).ToList();
        foreach (var id in to) foreach (var m in msgs) await Store.Forward(m, id!, hide.IsChecked == true);
        if (to.Count > 0) Store.Say(to.Count == 1 ? "Переслано" : $"Переслано в {to.Count} {Fmt.Plural(to.Count, "чат", "чата", "чатов")}");
    }

    // ---------- отправка файлов ----------

    /// <summary>Подтвердить отправку файлов; подпись или null — отмена</summary>
    public static async Task<string?> ConfirmFiles(MainWindow w, List<string> paths, string caption)
    {
        var sp = new StackPanel { Spacing = 10, Width = 380 };
        var imgExt = new[] { ".jpg", ".jpeg", ".png", ".webp", ".gif", ".bmp" };
        if (paths.Count == 1 && imgExt.Contains(Path.GetExtension(paths[0]).ToLowerInvariant()))
        {
            try { sp.Children.Add(new Image { Source = new BitmapImage(new Uri(paths[0])), MaxHeight = 300, Stretch = Stretch.Uniform }); } catch { }
        }
        else
        {
            foreach (var p in paths.Take(8))
            {
                var row = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 10 };
                row.Children.Add(T.Icon("\uE8A5", 18, T.A2));
                long size = 0; try { size = new FileInfo(p).Length; } catch { }
                row.Children.Add(T.Txt(Path.GetFileName(p) + "  ·  " + Fmt.Size(size), 13, lines: 1));
                sp.Children.Add(row);
            }
            if (paths.Count > 8) sp.Children.Add(T.Txt($"и ещё {paths.Count - 8}", 12, T.Muted));
        }
        var cap = new TextBox { PlaceholderText = "Подпись", Text = caption, AcceptsReturn = true, TextWrapping = TextWrapping.Wrap, MaxHeight = 120 };
        sp.Children.Add(cap);
        var title = paths.Count == 1 ? "Отправить файл" : $"Отправить {paths.Count} {Fmt.Plural(paths.Count, "файл", "файла", "файлов")}";
        return await Show(Make(w, title, sp, "Отправить", "Отмена")) == ContentDialogResult.Primary ? cap.Text.Trim() : null;
    }

    // ---------- поиск по чату ----------

    public static async Task SearchInChat(MainWindow w, ChatView view)
    {
        var box = new TextBox { PlaceholderText = "Текст для поиска" };
        var lv = new ListView { Height = 380, Width = 420, IsItemClickEnabled = true, SelectionMode = ListViewSelectionMode.None };
        var info = T.Txt("", 12, T.Muted);
        Sheet? d = null;
        CancellationTokenSource? cts = null;
        box.TextChanged += async (_, _) =>
        {
            cts?.Cancel(); var c = new CancellationTokenSource(); cts = c;
            var q = box.Text.Trim();
            lv.Items.Clear();
            if (q.Length < 2) { info.Text = ""; return; }
            try { await Task.Delay(350, c.Token); } catch { return; }
            info.Text = "Ищу…";
            var found = await Store.SearchMessages(view.ChatId, q);
            if (c.IsCancellationRequested) return;
            info.Text = found.Count == 0 ? "Ничего не найдено" : $"Найдено: {found.Count}";
            foreach (var m in found)
            {
                var sp = new StackPanel { Tag = m.Id, Padding = new Thickness(0, 4, 0, 4) };
                sp.Children.Add(T.Txt(Store.DisplayName(m.SenderId) + " · " + Fmt.ListTime(m.CreatedAt), 12, T.A2));
                sp.Children.Add(T.Txt((m.Body ?? "").Replace('\n', ' '), 13.5, lines: 2));
                lv.Items.Add(sp);
            }
        };
        lv.ItemClick += async (_, e) =>
        {
            if (e.ClickedItem is FrameworkElement fe && fe.Tag is int id) { d?.Hide(); await view.JumpToLoading(id); }
        };
        var root = new StackPanel { Spacing = 8 };
        root.Children.Add(box); root.Children.Add(info); root.Children.Add(lv);
        d = Make(w, "Поиск по чату", root);
        await Show(d);
    }

    // ---------- ключи шифрования на новом устройстве ----------

    public static async Task RestoreKeys(MainWindow w)
    {
        while (E2E.Status == E2E.State.NeedRestore)
        {
            var sp = new StackPanel { Spacing = 10, Width = 400 };
            sp.Children.Add(T.Txt("Личные чаты защищены сквозным шифрованием. Чтобы читать их на этом компьютере, введите пароль резервной копии ключа (его задавали на телефоне).", 13, T.Muted));
            var pw = new PasswordBox { PlaceholderText = "Пароль резервной копии" };
            sp.Children.Add(pw);
            sp.Children.Add(T.Txt("«Новые ключи» — если пароль забыт: старые зашифрованные сообщения прочитать будет нельзя, на телефоне ключ тоже сменится.", 12, T.Danger));
            var r = await Show(Make(w, "Восстановление ключа", sp, "Восстановить", "Позже", "Новые ключи"));
            if (r == ContentDialogResult.Primary)
            {
                if (await E2E.Restore(pw.Password)) { Store.Say("Ключ восстановлен"); await Store.LoadChats(); return; }
                Store.Say("Неверный пароль");
            }
            else if (r == ContentDialogResult.Secondary)
            {
                if (await Confirm(w, "Создать новые ключи шифрования?", "Создать") && await E2E.Reset()) { Store.Say("Созданы новые ключи"); await Store.LoadChats(); }
                return;
            }
            else return;
        }
    }

    public static async Task<bool> JoinChat(MainWindow w, SearchResult s)
    {
        var sp = new StackPanel { Spacing = 10, Width = 340 };
        var av = new AvatarView(72) { HorizontalAlignment = HorizontalAlignment.Center }; av.Set(s.Name, s.AvatarUrl, s.Color);
        sp.Children.Add(av);
        var n = T.Txt(s.Name, 18, bold: true); n.HorizontalAlignment = HorizontalAlignment.Center; sp.Children.Add(n);
        if (s.Username != null) { var u = T.Txt("@" + s.Username, 13, T.Muted); u.HorizontalAlignment = HorizontalAlignment.Center; sp.Children.Add(u); }
        if (!string.IsNullOrEmpty(s.Extra)) { var e = T.Txt(s.Extra, 13, T.Muted); e.TextAlignment = TextAlignment.Center; sp.Children.Add(e); }
        var yes = s.Kind == "channel" ? "Подписаться" : "Вступить";
        return await Show(Make(w, "", sp, yes, "Отмена")) == ContentDialogResult.Primary;
    }

    // ---------- кружок ----------

    /// <summary>Записать видеосообщение: предпросмотр в круге, «Начать» → «Отправить»</summary>
    public static async Task<(string path, double dur)?> RecordRound(MainWindow w, string chatId)
    {
        var rec = new VideoNoteRecorder();
        var err = await rec.Open();
        if (err != null) { Store.Say(err); return null; }
        var sp = new StackPanel { Spacing = 14, Width = 340 };
        var circle = new Grid { Width = 300, Height = 300, CornerRadius = new CornerRadius(150), Background = T.B(0xFF000000), HorizontalAlignment = HorizontalAlignment.Center };
        var pe = new MediaPlayerElement { Stretch = Stretch.UniformToFill, AutoPlay = true, AreTransportControlsEnabled = false };
        if (rec.Preview != null) pe.Source = rec.Preview;
        circle.Children.Add(pe);
        sp.Children.Add(circle);
        var time = T.Txt("Нажмите «Начать»", 14, T.Muted); time.HorizontalAlignment = HorizontalAlignment.Center;
        sp.Children.Add(time);
        var sheet = new Sheet { Title = "Видеосообщение", Content = sp, PrimaryButtonText = "Начать", CloseButtonText = "Отмена", Width = 386 };
        bool recording = false;
        DispatcherTimer? timer = null;
        (string, double)? result = null;
        var task = sheet.ShowAsync();
        // первая «Начать» запускает запись, вторая — отправляет
        while (true)
        {
            var r = await task;
            if (r != ContentDialogResult.Primary) break;
            if (!recording)
            {
                var e2 = await rec.Start();
                if (e2 != null) { Store.Say(e2); break; }
                recording = true;
                Store.UserTyping(chatId, "video");
                sheet = new Sheet { Title = "Идёт запись", Content = Detach(sp), PrimaryButtonText = "Отправить", CloseButtonText = "Отмена", Width = 386 };
                timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(300) };
                timer.Tick += async (_, _) =>
                {
                    time.Text = Fmt.Duration(rec.Seconds) + " / 1:00";
                    Store.UserTyping(chatId, "video");
                    if (rec.Seconds >= 60) sheet.Hide2(ContentDialogResult.Primary);
                };
                timer.Start();
                task = sheet.ShowAsync();
                continue;
            }
            timer?.Stop();
            result = await rec.Stop();
            Store.UserTyping(chatId, "stop");
            pe.Source = null;
            return result;
        }
        timer?.Stop();
        pe.Source = null;
        if (recording) { var x = await rec.Stop(); if (x != null) try { File.Delete(x.Value.path); } catch { } }
        else rec.Close();
        Store.UserTyping(chatId, "stop");
        return null;
    }

    static UIElement Detach(UIElement e)
    {
        if (e is FrameworkElement fe && fe.Parent is ScrollViewer sv) sv.Content = null;
        return e;
    }

    // ---------- папки ----------

    static ListView ChatPicker(IEnumerable<ChatItem> chats, ICollection<string> selected, double height = 320)
    {
        var lv = new ListView { SelectionMode = ListViewSelectionMode.Multiple, Height = height };
        foreach (var c in chats)
        {
            var g = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 10, Tag = c.Id, Padding = new Thickness(0, 4, 0, 4) };
            var av = new AvatarView(32); av.Set(c.DisplayName, c.DisplayAvatar, c.DisplayColor);
            g.Children.Add(av);
            var n = T.Txt(c.IsPrivate && c.PeerId == Store.MyId ? "Избранное" : c.DisplayName, 14, lines: 1); n.VerticalAlignment = VerticalAlignment.Center;
            g.Children.Add(n);
            lv.Items.Add(g);
            if (selected.Contains(c.Id)) lv.SelectedItems.Add(g);
        }
        return lv;
    }

    static List<string> Picked(ListView lv) => lv.SelectedItems.OfType<FrameworkElement>().Select(x => x.Tag as string).Where(x => x != null).Select(x => x!).ToList();

    public static async Task EditFolder(MainWindow w, Folders.Folder? f)
    {
        var name = new TextBox { Header = "Название папки", Text = f?.Name ?? "", MaxLength = 24 };
        var sp = new StackPanel { Spacing = 10, Width = 400 };
        sp.Children.Add(name);
        sp.Children.Add(T.Txt("Чаты в папке", 12, T.Muted));
        var lv = ChatPicker(Store.Chats, f?.Chats ?? new List<string>());
        sp.Children.Add(lv);
        if (await Show(Make(w, f == null ? "Новая папка" : "Изменить папку", sp, f == null ? "Создать" : "Сохранить", "Отмена")) != ContentDialogResult.Primary) return;
        var n = name.Text.Trim();
        if (n.Length == 0) { Store.Say("Введите название папки"); return; }
        Folders.Upsert(new Folders.Folder(f?.Id ?? Guid.NewGuid().ToString("N")[..8], n, Picked(lv)));
    }

    // ---------- новая группа или канал ----------

    public static async Task<string?> CreateChat(MainWindow w, string type)
    {
        var channel = type == "channel";
        var sp = new StackPanel { Spacing = 10, Width = 420 };
        byte[]? photo = null;
        var top = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 14 };
        var av = new AvatarView(64); av.SetIcon(channel ? "\uE789" : "\uE716", T.Accent);
        var pick = new Button { Content = av, Padding = new Thickness(0), CornerRadius = new CornerRadius(32), BorderThickness = new Thickness(0) };
        T.Fill(pick, T.Transparent);
        ToolTipService.SetToolTip(pick, "Выбрать фото");
        pick.Click += async (_, _) =>
        {
            var p = new Windows.Storage.Pickers.FileOpenPicker();
            WinRT.Interop.InitializeWithWindow.Initialize(p, w.Hwnd);
            foreach (var e in new[] { ".jpg", ".jpeg", ".png" }) p.FileTypeFilter.Add(e);
            var f = await p.PickSingleFileAsync(); if (f == null) return;
            photo = await File.ReadAllBytesAsync(f.Path);
            av.Set("", f.Path, 0);
        };
        top.Children.Add(pick);
        var title = new TextBox { Header = channel ? "Название канала" : "Название группы", Width = 330, MaxLength = 64 };
        top.Children.Add(title);
        sp.Children.Add(top);
        var desc = new TextBox { Header = "Описание (необязательно)", AcceptsReturn = true, TextWrapping = TextWrapping.Wrap, Height = 70 };
        sp.Children.Add(desc);
        TextBox? uname = null;
        if (channel)
        {
            uname = new TextBox { Header = "Публичная ссылка (необязательно)", PlaceholderText = "имя_канала" };
            sp.Children.Add(uname);
        }
        sp.Children.Add(T.Txt(channel ? "Подписчики (можно добавить позже)" : "Участники", 12, T.Muted));
        var lv = ChatPicker(Store.Chats.Where(c => c.IsPrivate && c.PeerId != null && c.PeerId != Store.MyId && !c.PeerBot), Array.Empty<string>(), 240);
        sp.Children.Add(lv);
        if (await Show(Make(w, channel ? "Новый канал" : "Новая группа", sp, "Создать", "Отмена")) != ContentDialogResult.Primary) return null;
        var t = title.Text.Trim();
        if (t.Length == 0) { Store.Say("Введите название"); return null; }
        var members = Picked(lv).Select(id => Store.Chat(id)?.PeerId).Where(x => x != null).Select(x => x!).ToList();
        return await Store.CreateChat(type, t, desc.Text.Trim(), members, uname?.Text, photo);
    }

    // ---------- игры ----------

    public static async Task Games(MainWindow w, string chatId)
    {
        var sp = new StackPanel { Spacing = 12, Width = 460 };
        Sheet? sheet = null;
        sp.Children.Add(T.Txt("БРОСИТЬ В ЧАТ", 12, T.Muted, bold: true));
        var tg = new Grid { ColumnSpacing = 8 };
        var throws = new[] { ("dice", "Кубик", "\uE8EC"), ("darts", "Дартс", "\uE879"), ("basket", "Баскетбол", "\uE805"), ("football", "Футбол", "\uEA8F"), ("coin", "Монетка", "\uE8C7") };
        for (int i = 0; i < throws.Length; i++)
        {
            var (k, name, glyph) = throws[i];
            tg.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            var c = new StackPanel { Spacing = 6, HorizontalAlignment = HorizontalAlignment.Center };
            var ic = Art.Throw(k, k switch { "dice" => 5, "coin" => 1, "darts" => 6, _ => 5 }, 34); ic.HorizontalAlignment = HorizontalAlignment.Center; c.Children.Add(ic);
            c.Children.Add(new TextBlock { Text = name, FontSize = 12, Foreground = T.Text, HorizontalAlignment = HorizontalAlignment.Center });
            var b = new Button { Content = c, HorizontalAlignment = HorizontalAlignment.Stretch, Height = 72, CornerRadius = new CornerRadius(14), BorderThickness = new Thickness(0) };
            T.Fill(b, T.Panel2, T.B(0xFF24264A));
            var kind = k;
            b.Click += async (_, _) =>
            {
                sheet?.Hide();
                try { await Api.Rpc("lm_throw", J.O(("p_chat", chatId), ("p_kind", kind))); } catch (Exception e) { Store.Say(e.Message); }
            };
            Grid.SetColumn(b, i); tg.Children.Add(b);
        }
        sp.Children.Add(tg);

        sp.Children.Add(T.Txt("СЫГРАТЬ ВДВОЁМ", 12, T.Muted, bold: true));
        var game = "ttt";
        var gl = new StackPanel { Spacing = 6 };
        var games = new[] { ("ttt", "Крестики-нолики", "Три в ряд на поле 3×3"), ("checkers", "Шашки", "Русские шашки, взятие обязательно"), ("sea", "Морской бой", "Флот 10 кораблей, поле 10×10"), ("chess", "Шахматы", "Классические шахматы по всем правилам") };
        var clockRow = new StackPanel { Spacing = 6 };
        var gButtons = new List<(string, Button)>();
        void Mark() { foreach (var (k, b) in gButtons) T.Fill(b, k == game ? T.B(0x407C5CFF) : T.Panel2, k == game ? T.B(0x557C5CFF) : T.B(0xFF24264A)); clockRow.Visibility = game is "chess" or "checkers" ? Visibility.Visible : Visibility.Collapsed; }
        foreach (var (k, name, desc) in games)
        {
            var row = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 12 };
            row.Children.Add(BubbleView.GameIcon(k, 40));
            var tx = new StackPanel { VerticalAlignment = VerticalAlignment.Center };
            tx.Children.Add(T.Txt(name, 14.5, bold: true)); tx.Children.Add(T.Txt(desc, 12, T.Muted));
            row.Children.Add(tx);
            var b = new Button { Content = row, HorizontalAlignment = HorizontalAlignment.Stretch, HorizontalContentAlignment = HorizontalAlignment.Left, Padding = new Thickness(10), CornerRadius = new CornerRadius(14), BorderThickness = new Thickness(0) };
            var kk = k;
            b.Click += (_, _) => { game = kk; Mark(); };
            gButtons.Add((k, b));
            gl.Children.Add(b);
        }
        sp.Children.Add(gl);
        clockRow.Children.Add(T.Txt("Таймер партии", 12, T.Muted));
        var clocks = new[] { (0, 0, "Без таймера"), (1, 0, "1 мин"), (3, 2, "3 + 2"), (5, 0, "5 мин"), (10, 0, "10 мин"), (15, 10, "15 + 10"), (30, 0, "30 мин") };
        var clock = new ComboBox { HorizontalAlignment = HorizontalAlignment.Stretch };
        foreach (var c in clocks) clock.Items.Add(c.Item3);
        clock.SelectedIndex = 0;
        clockRow.Children.Add(clock);
        sp.Children.Add(clockRow);
        var stake = new NumberBox { Header = "Ставка в люменах (необязательно, до 1000)", Minimum = 0, Maximum = 1000, Value = 0, SpinButtonPlacementMode = NumberBoxSpinButtonPlacementMode.Compact };
        sp.Children.Add(stake);
        sp.Children.Add(T.Txt("Ставку вносят оба игрока, победитель забирает обе. При ничьей ставки возвращаются.", 12, T.Muted));
        Mark();
        sheet = Make(w, "Игры", sp, "Пригласить", "Отмена");
        if (await Show(sheet) != ContentDialogResult.Primary) return;
        try
        {
            var req = J.O(("action", "new"), ("chat_id", chatId), ("kind", game), ("stake", (int)(double.IsNaN(stake.Value) ? 0 : stake.Value)));
            var ci = clock.SelectedIndex;
            if (game is "chess" or "checkers" && ci > 0) { req["clock_min"] = clocks[ci].Item1; req["clock_inc"] = clocks[ci].Item2; }
            var g = await WebOverlay.GamesCall(req);
            Store.Say("Приглашение отправлено");
            var id = g.Str("id");
            if (id != null) { await Task.Delay(300); WebOverlay.I?.OpenGame(id); }
        }
        catch (Exception e) { Store.Say(e.Message); }
    }

    // ---------- политика конфиденциальности ----------

    /// <summary>Текст политики (Assets/privacy.md) в оформлении приложения</summary>
    public static UIElement PolicyView()
    {
        var sp = new StackPanel { Spacing = 8 };
        string md;
        try { md = File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "Assets", "privacy.md")); } catch { md = "Политика доступна на lumomess.ru/?privacy"; }
        foreach (var raw in md.Replace("\r", "").Split('\n'))
        {
            var line = raw.TrimEnd();
            if (line.Length == 0) continue;
            if (line.StartsWith("# ")) continue;   // заголовок — в шапке окна
            if (line.StartsWith("## ")) { var h = T.Txt(line[3..], 15.5, bold: true); h.Margin = new Thickness(0, 8, 0, 0); sp.Children.Add(h); continue; }
            var bullet = line.StartsWith("- ");
            var text = bullet ? line[2..] : line;
            var rtb = BubbleView.RichText(text, T.Text);
            rtb.FontSize = 13.5;
            if (bullet)
            {
                var g = new Grid { ColumnSpacing = 8 };
                g.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(10) });
                g.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
                g.Children.Add(new Border { Width = 5, Height = 5, CornerRadius = new CornerRadius(3), Background = T.A2, VerticalAlignment = VerticalAlignment.Top, Margin = new Thickness(0, 8, 0, 0) });
                Grid.SetColumn(rtb, 1); g.Children.Add(rtb);
                sp.Children.Add(g);
            }
            else sp.Children.Add(rtb);
        }
        return sp;
    }

    public static async Task Policy(MainWindow? w)
    {
        var sp = new StackPanel { Width = 560 };
        sp.Children.Add(PolicyView());
        await Show(new Sheet { Title = "Политика конфиденциальности", Content = sp, CloseButtonText = "Закрыть", Width = 606 });
    }

    public static async Task DeleteAccount(MainWindow w)
    {
        if (!await Confirm(w, "Удалить аккаунт навсегда?", "Удалить", "Профиль, ваши файлы и личные чаты будут удалены без возможности восстановления.")) return;
        if (!await Confirm(w, "Точно удалить аккаунт @" + (Store.Me?.Username ?? "") + "?", "Да, удалить")) return;
        try
        {
            var r = await Api.Function("/account", J.O(("action", "delete")));
            if (r.Has("error")) { Store.Say(r.Str("error") ?? "Ошибка"); return; }
            Store.Say("Аккаунт удалён");
            Api.Forget();
        }
        catch (Exception e) { Store.Say(e.Message); }
    }
}
