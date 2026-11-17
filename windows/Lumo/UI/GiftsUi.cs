using System.Text.Json.Nodes;
using Lumo.Core;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Media.Imaging;

namespace Lumo.UI;

public record Gift(string Id, string Name, string Rarity, int Price, int Supply, int Sold) { public int Left => Math.Max(0, Supply - Sold); }
public record OwnedGift(int Id, string GiftId, string Name, string Rarity, int Serial, int Supply, string? From, string? At, bool Hidden, int? Price);

/// <summary>Коллекционные подарки: каталог, мои подарки, покупка себе или другу, скрыть, продать</summary>
public static class Gifts
{
    public static List<Gift> Catalog { get; private set; } = new();
    static readonly Dictionary<string, string> art = new();

    public static async Task LoadCatalog()
    {
        var a = await Api.Rpc("lm_gift_list") as JsonArray;
        Catalog = (a ?? new JsonArray()).OfType<JsonObject>().Select(j => new Gift(j.Str("id") ?? "", j.Str("name") ?? "", j.Str("rarity") ?? "", j.Int("price") ?? 0, j.Int("supply") ?? 0, j.Int("sold") ?? 0)).ToList();
        try
        {
            if (await Api.Rpc("lm_gift_art") is JsonObject o)
                foreach (var kv in o) if (kv.Value is JsonValue v && v.TryGetValue<string>(out var s) && s.Contains("<svg")) art[kv.Key] = s;
        }
        catch { }
    }

    public static async Task<List<OwnedGift>> Owned(string? user)
    {
        var p = new JsonObject(); if (user != null) p["p_user"] = user;
        var a = await Api.Rpc("lm_gift_mine", p) as JsonArray;
        return (a ?? new JsonArray()).OfType<JsonObject>().Select(j => new OwnedGift(j.Int("id") ?? 0, j.Str("gift_id") ?? "", j.Str("name") ?? "", j.Str("rarity") ?? "",
            j.Int("serial") ?? 0, j.Int("supply") ?? 0, j.Str("from_user"), j.Str("at"), j.Bool("hidden"), j.Int("price"))).ToList();
    }

    public static string RarityName(string r) => r switch { "rare" => "Редкий", "epic" => "Эпический", "legendary" => "Легендарный", "mythic" => "Мифический", "ultra" => "Божественный", _ => "Обычный" };
    public static Brush RarityBrush(string r) => r switch
    {
        "rare" => T.Grad(0xFF2D98DA, 0xFF45AAF2), "epic" => T.Grad(0xFF8854D0, 0xFFA66CFF), "legendary" => T.Grad(0xFFF7B731, 0xFFFA8231),
        "mythic" => T.Grad(0xFFEB3B5A, 0xFFFF6B9D), "ultra" => T.Grad(0xFF0FB9B1, 0xFF7C5CFF), _ => T.Grad(0xFF3B3F7A, 0xFF5A5F9A),
    };

    /// <summary>Картинка подарка: вшитая PNG или рисунок с сервера (SVG)</summary>
    public static FrameworkElement Art(string id, double size)
    {
        var img = new Image { Width = size, Height = size, Stretch = Stretch.Uniform };
        var png = Path.Combine(AppContext.BaseDirectory, "Assets", "gifts", "gift_" + id + ".png");
        if (File.Exists(png)) img.Source = new BitmapImage(new Uri(png));
        else if (art.TryGetValue(id, out var svg))
        {
            var src = new SvgImageSource { RasterizePixelWidth = size * 2, RasterizePixelHeight = size * 2 };
            _ = Load(src, svg);
            img.Source = src;
        }
        else return new Border { Width = size, Height = size, Child = T.Icon("", size * 0.5, T.White) };
        return img;
    }
    static async Task Load(SvgImageSource src, string svg)
    {
        try
        {
            using var ms = new Windows.Storage.Streams.InMemoryRandomAccessStream();
            using (var w = new Windows.Storage.Streams.DataWriter(ms)) { w.WriteString(svg); await w.StoreAsync(); w.DetachStream(); }
            ms.Seek(0);
            await src.SetSourceAsync(ms);
        }
        catch { }
    }

    public static async Task<long> Balance()
    {
        try { return (await Api.Rpc("lm_wallet_me")).Long("balance") ?? 0; } catch { return 0; }
    }

    /// <summary>Купить подарок (себе или другу)</summary>
    public static async Task<bool> Buy(Gift g, string? to)
    {
        try
        {
            var p = new JsonObject { ["p_gift"] = g.Id }; if (to != null) p["p_to"] = to;
            var r = await Api.Rpc("lm_gift_buy", p);
            Store.Say((to == null ? "Подарок куплен" : "Подарок отправлен") + $" · №{r.Int("serial") ?? 0}");
            return true;
        }
        catch (Exception e) { Store.Say(e.Message); return false; }
    }

    /// <summary>Магазин подарков — сразу для конкретного человека (to) или для выбора получателя</summary>
    public static async Task ShowShop(string? to)
    {
        var root = new StackPanel { Spacing = 12 };
        var bal = T.Txt("", 13, T.B(0xFFF5B942), bold: true);
        var who = to != null ? Store.DisplayName(to) : null;
        root.Children.Add(T.Txt(who != null ? "Подарок для " + who : "Выберите подарок — себе или другу", 13, T.Muted));
        root.Children.Add(bal);
        var grid = new VariableSizedWrapGrid { Orientation = Orientation.Horizontal, ItemWidth = 150, ItemHeight = 200 };
        root.Children.Add(grid);
        var sheet = new Sheet { Title = "Подарки", Content = root, Width = 520 };
        async Task Fill()
        {
            grid.Children.Clear();
            grid.Children.Add(new ProgressRing { IsActive = true, Width = 26, Height = 26 });
            if (Catalog.Count == 0) { try { await LoadCatalog(); } catch (Exception e) { Store.Say(e.Message); } }
            var money = await Balance();
            bal.Text = "Ваш баланс: " + money.ToString("N0", new System.Globalization.CultureInfo("ru-RU")) + " люменов";
            grid.Children.Clear();
            foreach (var g in Catalog) grid.Children.Add(Card(g, money, async () =>
            {
                var target = to;
                if (target == null) { sheet.Hide(); await Task.Delay(200); target = await PickRecipient(); if (target == null) return; }
                if (target == "") target = null;
                if (await Buy(g, target)) { Catalog = new(); if (to != null) sheet.Hide(); else await ShowShop(null); }
                else if (to != null) await Fill();
            }));
        }
        _ = Fill();
        await sheet.ShowAsync();
    }

    static FrameworkElement Card(Gift g, long money, Func<Task> buy)
    {
        var sp = new StackPanel { Spacing = 4, HorizontalAlignment = HorizontalAlignment.Center };
        var pic = new Border { Width = 120, Height = 100, CornerRadius = new CornerRadius(16), Background = RarityBrush(g.Rarity), Child = Art(g.Id, 80) };
        sp.Children.Add(pic);
        var n = T.Txt(g.Name, 13.5, bold: true, lines: 1); n.HorizontalAlignment = HorizontalAlignment.Center; sp.Children.Add(n);
        var r = T.Txt(RarityName(g.Rarity) + (g.Supply > 0 ? $" · осталось {g.Left}" : ""), 11, T.Muted, lines: 1); r.HorizontalAlignment = HorizontalAlignment.Center; sp.Children.Add(r);
        var can = money >= g.Price && (g.Supply == 0 || g.Left > 0);
        var b = new Button { HorizontalAlignment = HorizontalAlignment.Center, CornerRadius = new CornerRadius(14), Padding = new Thickness(14, 4, 14, 4), BorderThickness = new Thickness(0), IsEnabled = can,
            Content = T.Txt(g.Supply > 0 && g.Left == 0 ? "Раскуплено" : g.Price.ToString("N0", new System.Globalization.CultureInfo("ru-RU")) + " люм.", 12.5, T.White, bold: true) };
        T.Fill(b, can ? T.Accent : T.Panel2);
        b.Click += async (_, _) => { b.IsEnabled = false; await buy(); };
        sp.Children.Add(b);
        return new Border { Margin = new Thickness(4), Padding = new Thickness(6, 8, 6, 8), CornerRadius = new CornerRadius(16), Background = T.Panel2, Child = sp };
    }

    /// <summary>Кому подарить: себе или собеседнику из личных чатов. "" — себе, null — отмена</summary>
    static async Task<string?> PickRecipient()
    {
        string? res = null;
        var list = new StackPanel { Spacing = 2 };
        var search = new TextBox { PlaceholderText = "Поиск" };
        var root = new StackPanel { Spacing = 8 }; root.Children.Add(search); root.Children.Add(list);
        var sheet = new Sheet { Title = "Кому подарить", Content = root, Width = 420 };
        void Render()
        {
            list.Children.Clear();
            Row("Себе", Store.Me?.AvatarUrl, Store.Me?.Color ?? 0, "");
            foreach (var c in Store.Chats.Where(c => c.IsPrivate && c.PeerId != null && c.PeerId != Store.MyId && !c.PeerBot && (search.Text.Length == 0 || c.DisplayName.Contains(search.Text, StringComparison.OrdinalIgnoreCase))).Take(60))
                Row(c.DisplayName, c.DisplayAvatar, c.DisplayColor, c.PeerId!);
        }
        void Row(string name, string? av0, int color, string id)
        {
            var b = new Button { HorizontalAlignment = HorizontalAlignment.Stretch, HorizontalContentAlignment = HorizontalAlignment.Left, Background = T.Transparent, BorderThickness = new Thickness(0), Padding = new Thickness(6) };
            var sp = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 10 };
            var av = new AvatarView(36); av.Set(name, av0, color); sp.Children.Add(av);
            var t = T.Txt(name, 14, lines: 1); t.VerticalAlignment = VerticalAlignment.Center; sp.Children.Add(t);
            b.Content = sp;
            b.Click += (_, _) => { res = id; sheet.Hide(); };
            list.Children.Add(b);
        }
        search.TextChanged += (_, _) => Render();
        Render();
        await sheet.ShowAsync();
        return res;
    }

    /// <summary>Мои подарки (или подарки пользователя) — сетка с номерами</summary>
    public static async Task<UIElement> OwnedPanel(string? user, bool manage)
    {
        var sp = new StackPanel { Spacing = 10 };
        List<OwnedGift> l;
        try { l = await Owned(user); if (Catalog.Count == 0) await LoadCatalog(); }
        catch (Exception e) { sp.Children.Add(T.Txt(e.Message, 13, T.Danger)); return sp; }
        if (l.Count == 0) { sp.Children.Add(T.Txt(manage ? "У вас пока нет подарков. Купите первый в магазине." : "Подарков пока нет", 13.5, T.Muted)); return sp; }
        await Store.LoadProfiles(l.Where(x => x.From != null).Select(x => x.From!).Distinct().ToList());
        var grid = new VariableSizedWrapGrid { Orientation = Orientation.Horizontal, ItemWidth = 150, ItemHeight = 190 };
        foreach (var g in l)
        {
            var c = new StackPanel { Spacing = 3, HorizontalAlignment = HorizontalAlignment.Center };
            var pic = new Grid { Width = 120, Height = 100, CornerRadius = new CornerRadius(16), Background = RarityBrush(g.Rarity), Opacity = g.Hidden ? 0.45 : 1 };
            pic.Children.Add(Art(g.GiftId, 80));
            var num = new Border { Background = T.B(0x66000000), CornerRadius = new CornerRadius(8), Padding = new Thickness(6, 1, 6, 1), HorizontalAlignment = HorizontalAlignment.Right, VerticalAlignment = VerticalAlignment.Top, Margin = new Thickness(6),
                Child = T.Txt("№" + g.Serial, 10.5, T.White, bold: true) };
            pic.Children.Add(num);
            c.Children.Add(pic);
            var n = T.Txt(g.Name, 13, bold: true, lines: 1); n.HorizontalAlignment = HorizontalAlignment.Center; c.Children.Add(n);
            var f = T.Txt(g.From != null ? "от " + Store.DisplayName(g.From) : RarityName(g.Rarity), 11, T.Muted, lines: 1); f.HorizontalAlignment = HorizontalAlignment.Center; c.Children.Add(f);
            var card = new Border { Margin = new Thickness(4), Padding = new Thickness(6, 8, 6, 8), CornerRadius = new CornerRadius(16), Background = T.Panel2, Child = c };
            if (manage)
            {
                var menu = new MenuFlyout();
                var hide = new MenuFlyoutItem { Text = g.Hidden ? "Показывать в профиле" : "Скрыть из профиля", Icon = new FontIcon { Glyph = g.Hidden ? "" : "" } };
                var gg = g;
                hide.Click += async (_, _) => { try { await Api.Rpc("lm_gift_hide", new JsonObject { ["p_owned_id"] = gg.Id, ["p_hidden"] = !gg.Hidden }); card.Opacity = 0.5; Store.Say(gg.Hidden ? "Подарок снова в профиле" : "Подарок скрыт"); } catch (Exception e) { Store.Say(e.Message); } };
                menu.Items.Add(hide);
                var sell = new MenuFlyoutItem { Text = "Продать" + (g.Price is int pr ? $" за {pr} люм." : ""), Icon = new FontIcon { Glyph = "" } };
                sell.Click += async (_, _) =>
                {
                    if (App.Win == null || !await Dialogs.Confirm(App.Win, "Продать «" + gg.Name + "» №" + gg.Serial + "?", "Продать")) return;
                    try { var r = await Api.Rpc("lm_gift_sell", new JsonObject { ["p_owned_id"] = gg.Id }); Store.Say("Продано · +" + (r.Int("refund") ?? 0) + " люменов"); grid.Children.Remove(card); }
                    catch (Exception e) { Store.Say(e.Message); }
                };
                menu.Items.Add(sell);
                card.ContextFlyout = menu;
                card.Tapped += (_, _) => menu.ShowAt(card);
            }
            grid.Children.Add(card);
        }
        sp.Children.Add(grid);
        if (manage) sp.Children.Add(T.Txt("Нажмите на подарок, чтобы скрыть его из профиля или продать.", 12, T.Muted));
        return sp;
    }
}
