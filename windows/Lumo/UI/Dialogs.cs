using Lumo.Core;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Media.Imaging;

namespace Lumo.UI;

/// <summary>Окна: настройки и профиль, сведения о чате, пересылка, подтверждения, поиск по чату, ключи шифрования</summary>
public static class Dialogs
{
    static bool open;

    static ContentDialog Make(MainWindow w, string title, object content, string? primary = null, string? close = "Закрыть", string? secondary = null)
    {
        var d = new ContentDialog
        {
            XamlRoot = w.Root, Title = title, Content = content, RequestedTheme = ElementTheme.Dark,
            CloseButtonText = close ?? "", DefaultButton = primary != null ? ContentDialogButton.Primary : ContentDialogButton.Close,
        };
        if (primary != null) d.PrimaryButtonText = primary;
        if (secondary != null) d.SecondaryButtonText = secondary;
        return d;
    }

    static async Task<ContentDialogResult> Show(ContentDialog d)
    {
        if (open) return ContentDialogResult.None;
        open = true;
        try { return await d.ShowAsync(); }
        catch (Exception e) { App.Log("dialog: " + e.Message); return ContentDialogResult.None; }
        finally { open = false; }
    }

    public static async Task<bool> Confirm(MainWindow w, string text, string yes)
    {
        var d = Make(w, text, T.Txt("Это действие нельзя отменить.", 13, T.Muted), yes, "Отмена");
        return await Show(d) == ContentDialogResult.Primary;
    }

    // ---------- мой профиль и настройки ----------

    public static async Task Settings(MainWindow w)
    {
        var me = Store.Me;
        if (me == null) { await Store.LoadMe(); me = Store.Me; if (me == null) return; }
        var sp = new StackPanel { Spacing = 10, Width = 400 };
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
        sp.Children.Add(T.Txt("Lumo для Windows 1.0 · звонки, голосовые, каналы и игры — в следующих обновлениях", 12, T.Muted));
        var d = Make(w, "Мой профиль", new ScrollViewer { Content = sp, MaxHeight = 560 }, "Сохранить", "Закрыть", "Выйти из аккаунта");
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
        await Show(Make(w, "", sp));
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
        ContentDialog? d = null;
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
}
