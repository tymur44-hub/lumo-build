using System.Text.Json.Nodes;
using Lumo.Core;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Controls.Primitives;

namespace Lumo.UI;

/// <summary>Конфиденциальность — все пункты, как в мобильной версии; строки всегда помещаются в панель</summary>
public static class PrivacyPage
{
    record Item(string Key, string Title, string Question, string Hint, bool NoneAllowed = true);

    static readonly Item[] items =
    {
        new("seen", "Время захода", "Кто видит время моего последнего входа?", "Если вы скрываете время захода, вы тоже не увидите его у других."),
        new("photo", "Фотографии профиля", "Кто видит фотографию моего профиля?", "Остальные увидят цветной кружок с инициалами."),
        new("bio", "Раздел «О себе»", "Кто видит раздел «О себе»?", "Текст из раздела «О себе» в вашем профиле."),
        new("phone", "Номер телефона", "Кто видит мой номер телефона?", "Если выбрать «Никто», друзья не найдут вас по номеру."),
        new("birthday", "День рождения", "Кто видит мой день рождения?", "Дата рождения в вашем профиле."),
        new("calls", "Звонки", "Кто может мне звонить?", "Остальные не смогут вам позвонить."),
        new("voice", "Голосовые сообщения", "Кто может присылать голосовые и видеосообщения?", "Остальные смогут писать только текстом."),
        new("messages", "Сообщения", "Кто может писать мне первым?", "Тем, с кем вы уже переписываетесь, ограничение не помешает.", false),
        new("invites", "Приглашения", "Кто может приглашать меня в группы и каналы?", "Кому вы разрешаете добавлять вас в группы и каналы."),
    };

    static string Label(string v) => v switch { "contacts" => "Мои контакты", "none" => "Никто", "premium" => "Контакты и Premium", _ => "Все" };

    static string Current(Profile me, string key)
    {
        if (key == "messages") return me.Privacy.Str("msg_prem") == "premium" ? "premium" : "all";
        if (me.Privacy.Str(key) is string v) return v;
        return key switch { "seen" => me.ShowSeen ? "all" : "none", "phone" => "contacts", _ => "all" };
    }

    public static async Task<UIElement> Make()
    {
        await Store.LoadMe();
        var me = Store.Me!;
        var sp = new StackPanel { Spacing = 10 };

        // ---- безопасность ----
        var sec = Card();
        var blockedCount = 0;
        List<string> blocked = new();
        try
        {
            var j = await Api.Rpc("lm_my_blocks");
            blocked = j.Arr("mine")?.Select(x => x is JsonValue v && v.TryGetValue<string>(out var s2) ? s2 : null).Where(x => x != null).Select(x => x!).ToList() ?? new();
            blockedCount = blocked.Count;
        }
        catch { }
        sec.Children.Add(Row("", 0xFFFF5B7A, "Заблокированные", blockedCount == 0 ? "Никого" : blockedCount.ToString(), async (_, _) => await Blocked(blocked)));
        sec.Children.Add(Sep());
        sec.Children.Add(Row("", 0xFF7C5CFF, "Сквозное шифрование", E2E.Status == E2E.State.Ready ? "Включено" : "Восстановить ключ", async (_, _) =>
        {
            if (E2E.Status == E2E.State.Ready) Plaque.Show("", "Сквозное шифрование", "Личные чаты зашифрованы. Ключ сохранён на этом компьютере.");
            else if (App.Win != null) await Dialogs.RestoreKeys(App.Win);
        }));
        sec.Children.Add(Sep());
        sec.Children.Add(Row("", 0xFFFF8A3D, "Двухэтапная защита", "На телефоне", (_, _) =>
            Plaque.Show("", "Двухэтапная защита", "Пароль для входа включается в приложении Lumo на телефоне: Настройки → Конфиденциальность.")));
        sp.Children.Add(sec);

        // ---- кто что видит ----
        sp.Children.Add(Section("Конфиденциальность"));
        var card = Card();
        for (int i = 0; i < items.Length; i++)
        {
            var it = items[i];
            TextBlock? valueT = null;
            var row = Row(null, 0, it.Title, Label(Current(me, it.Key)), null, t => valueT = t);
            row.Tapped += (_, _) =>
            {
                var cur = Current(Store.Me ?? me, it.Key);
                var opts = it.Key == "messages" ? new[] { "all", "premium" } : it.NoneAllowed ? new[] { "all", "contacts", "none" } : new[] { "all", "contacts" };
                var fl = new MenuFlyout { Placement = FlyoutPlacementMode.BottomEdgeAlignedRight };
                fl.Items.Add(new MenuFlyoutItem { Text = it.Question, IsEnabled = false });
                fl.Items.Add(new MenuFlyoutSeparator());
                foreach (var v in opts)
                {
                    var mi = new MenuFlyoutItem { Text = Label(v), Icon = v == cur ? new FontIcon { Glyph = "" } : null };
                    var vv = v;
                    mi.Click += async (_, _) =>
                    {
                        if (vv == "premium" && Store.Me?.Premium != true) { Plaque.Show("", "Lumo Premium", "Ограничить сообщения «Контакты и Premium» можно с подпиской Premium."); return; }
                        try
                        {
                            await Api.Rpc("lm_set_privacy", J.O(("p_key", it.Key == "messages" ? "msg_prem" : it.Key), ("p_value", vv)));
                            await Store.LoadMe();
                            if (valueT != null) valueT.Text = Label(vv);
                        }
                        catch (Exception e) { Store.Say(e.Message); }
                    };
                    fl.Items.Add(mi);
                }
                fl.Items.Add(new MenuFlyoutSeparator());
                fl.Items.Add(new MenuFlyoutItem { Text = it.Hint, IsEnabled = false });
                fl.ShowAt(row);
            };
            card.Children.Add(row);
            if (i < items.Length - 1) card.Children.Add(Sep(16));
        }
        sp.Children.Add(card);
        sp.Children.Add(T.Txt("Нажмите на пункт, чтобы выбрать, кто это видит или может делать.", 12, T.Muted));

        // ---- документы ----
        var docs = Card();
        docs.Children.Add(Row("", 0xFF13B0A5, "Политика конфиденциальности", "", async (_, _) => await Dialogs.Policy(App.Win)));
        docs.Children.Add(Sep());
        docs.Children.Add(Row("", 0xFFFF3B5C, "Удалить аккаунт", "", async (_, _) => { if (App.Win != null) await Dialogs.DeleteAccount(App.Win); }, danger: true));
        sp.Children.Add(docs);
        return sp;
    }

    static StackPanel Card() => new() { Background = T.Panel2, CornerRadius = new CornerRadius(14), Margin = new Thickness(0, 4, 0, 4) };
    static Border Sep(double left = 54) => new() { Height = 1, Background = T.Line, Margin = new Thickness(left, 0, 0, 0) };
    static TextBlock Section(string t) { var x = T.Txt(t.ToUpperInvariant(), 12, T.Muted, bold: true); x.Margin = new Thickness(4, 14, 0, 2); return x; }

    /// <summary>Строка: иконка, название (обрезается), значение (обрезается), стрелка — всегда помещается по ширине</summary>
    static Grid Row(string? glyph, uint color, string title, string value, Microsoft.UI.Xaml.Input.TappedEventHandler? tap, Action<TextBlock>? valueRef = null, bool danger = false)
    {
        var g = new Grid { ColumnSpacing = 10, Padding = new Thickness(14, 12, 12, 12), Background = T.Transparent, MinHeight = 48 };
        g.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        g.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        g.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Auto), MaxWidth = 220 });
        g.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        if (glyph != null) g.Children.Add(new Border { Width = 30, Height = 30, CornerRadius = new CornerRadius(8), Background = T.B(color), Child = T.Icon(glyph, 15, T.White) });
        var t = T.Txt(title, 14.5, danger ? T.Danger : T.Text, lines: 1); t.VerticalAlignment = VerticalAlignment.Center; t.TextTrimming = TextTrimming.CharacterEllipsis;
        Grid.SetColumn(t, 1); g.Children.Add(t);
        var v = T.Txt(value, 14, T.Muted, lines: 1); v.VerticalAlignment = VerticalAlignment.Center; v.TextTrimming = TextTrimming.CharacterEllipsis;
        Grid.SetColumn(v, 2); g.Children.Add(v);
        valueRef?.Invoke(v);
        var ch = T.Icon("", 11, T.Muted); ch.VerticalAlignment = VerticalAlignment.Center;
        Grid.SetColumn(ch, 3); g.Children.Add(ch);
        g.PointerEntered += (_, _) => g.Background = T.Hover;
        g.PointerExited += (_, _) => g.Background = T.Transparent;
        if (tap != null) g.Tapped += tap;
        return g;
    }

    static async Task Blocked(List<string> ids)
    {
        await Store.LoadProfiles(ids);
        var list = new StackPanel { Spacing = 6 };
        if (ids.Count == 0) list.Children.Add(T.Txt("Вы никого не блокировали", 13.5, T.Muted));
        foreach (var id in ids)
        {
            var row = new Grid { ColumnSpacing = 10 };
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            var p = Store.Profiles.GetValueOrDefault(id);
            var av = new AvatarView(34); av.Set(Store.DisplayName(id), p?.AvatarUrl, p?.Color ?? 0); row.Children.Add(av);
            var n = T.Txt(Store.DisplayName(id), 14, lines: 1); n.VerticalAlignment = VerticalAlignment.Center; n.TextTrimming = TextTrimming.CharacterEllipsis;
            Grid.SetColumn(n, 1); row.Children.Add(n);
            var ub = new HyperlinkButton { Content = "Разблокировать" };
            var uid = id;
            ub.Click += async (_, _) => { try { await Api.Rpc("lm_block", J.O(("p_user", uid), ("p_on", false))); list.Children.Remove(row); } catch (Exception e) { Store.Say(e.Message); } };
            Grid.SetColumn(ub, 2); row.Children.Add(ub);
            list.Children.Add(row);
        }
        await new Sheet { Title = "Заблокированные", Content = list, Width = 420 }.ShowAsync();
    }
}
