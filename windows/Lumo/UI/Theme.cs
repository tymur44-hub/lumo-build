using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Media.Imaging;
using Lumo.Core;
using Windows.UI;

namespace Lumo.UI;

/// <summary>Цвета и мелкие помощники оформления (как в приложениях для телефона, тёмная тема)</summary>
public static class T
{
    public static Color C(uint argb) => Color.FromArgb((byte)(argb >> 24), (byte)(argb >> 16), (byte)(argb >> 8), (byte)argb);
    public static SolidColorBrush B(uint argb) => new(C(argb));

    public static readonly SolidColorBrush Bg = B(0xFF0C0D1A), Panel = B(0xFF13142A), Panel2 = B(0xFF1A1C36), ChatBg = B(0xFF0E0F22),
        Bubble = B(0xFF1D1F3D), Text = B(0xFFEEF0FF), Muted = B(0xFF8D90B8), Line = B(0x18FFFFFF), A1 = B(0xFF7C5CFF), A2 = B(0xFF22C1FF),
        Danger = B(0xFFFF5B7A), Ok = B(0xFF3EE0A0), White = B(0xFFFFFFFF), Transparent = B(0x00000000), Hover = B(0x14FFFFFF),
        Selected = B(0x307C5CFF), Dim = B(0xCC05060F), OutMuted = B(0xBFFFFFFF);

    public static LinearGradientBrush Grad(uint a, uint b, double angle = 1)
    {
        var g = new LinearGradientBrush { StartPoint = new Windows.Foundation.Point(0, 0), EndPoint = new Windows.Foundation.Point(1, angle) };
        g.GradientStops.Add(new GradientStop { Color = C(a), Offset = 0 });
        g.GradientStops.Add(new GradientStop { Color = C(b), Offset = 1 });
        return g;
    }

    public static Brush Accent => Grad(0xFF7C5CFF, 0xFF22C1FF);
    public static Brush Out => Grad(0xFF6A4CF5, 0xFF3A7BFF);

    static readonly (uint, uint)[] pairs =
    {
        (0xFFFF8A5B, 0xFFFF5B8A), (0xFF7C5CFF, 0xFFB05CFF), (0xFF22C1FF, 0xFF3A7BFF), (0xFF2EE6A6, 0xFF13B0A5),
        (0xFFFFC94A, 0xFFFF8A3D), (0xFFFF5B7A, 0xFFC44DFF), (0xFF5BD0FF, 0xFF7C5CFF), (0xFF9BE15D, 0xFF00C6A7),
    };
    static readonly uint[] names = { 0xFFFF7A6B, 0xFFA48BFF, 0xFF36B8FF, 0xFF25C99A, 0xFFF0A23A, 0xFFFF5B9A, 0xFF6AA8FF, 0xFF52C46E };
    public static Brush AvatarBrush(int c) { var p = pairs[((c % 8) + 8) % 8]; return Grad(p.Item1, p.Item2); }
    public static Brush NameBrush(int c) => B(names[((c % 8) + 8) % 8]);

    public static readonly FontFamily IconFont = new("Segoe Fluent Icons,Segoe MDL2 Assets");

    public static FontIcon Icon(string glyph, double size = 16, Brush? fg = null) =>
        new() { Glyph = glyph, FontFamily = IconFont, FontSize = size, Foreground = fg ?? Text };

    public static TextBlock Txt(string s, double size = 14, Brush? fg = null, bool bold = false, int lines = 0)
    {
        var t = new TextBlock { Text = s, FontSize = size, Foreground = fg ?? Text, TextTrimming = TextTrimming.CharacterEllipsis };
        if (bold) t.FontWeight = Microsoft.UI.Text.FontWeights.SemiBold;
        if (lines == 1) { t.TextWrapping = TextWrapping.NoWrap; t.MaxLines = 1; }
        else if (lines > 1) { t.TextWrapping = TextWrapping.Wrap; t.MaxLines = lines; }
        else t.TextWrapping = TextWrapping.Wrap;
        return t;
    }

    /// <summary>Круглая кнопка-иконка без рамки</summary>
    public static Button IconButton(string glyph, string tip, Action click, double size = 36, double icon = 16, Brush? fg = null)
    {
        var b = new Button
        {
            Content = Icon(glyph, icon, fg ?? Muted), Width = size, Height = size, Padding = new Thickness(0),
            Background = Transparent, BorderThickness = new Thickness(0), CornerRadius = new CornerRadius(size / 2),
        };
        ToolTipService.SetToolTip(b, tip);
        b.Click += (_, _) => click();
        return b;
    }

    public static Button Primary(string text, Action click)
    {
        var b = new Button
        {
            Content = new TextBlock { Text = text, FontWeight = Microsoft.UI.Text.FontWeights.SemiBold, Foreground = White },
            Background = Accent, BorderThickness = new Thickness(0), CornerRadius = new CornerRadius(12), Height = 44,
            HorizontalAlignment = HorizontalAlignment.Stretch, HorizontalContentAlignment = HorizontalAlignment.Center,
        };
        b.Click += (_, _) => click();
        return b;
    }

    static readonly Dictionary<string, BitmapImage> imgCache = new();

    /// <summary>Картинка по ссылке (через выбранный адрес сервера), с кэшем на время работы</summary>
    public static BitmapImage? Bitmap(string? url, int decode = 0)
    {
        if (string.IsNullOrEmpty(url)) return null;
        var key = url + "#" + decode;
        if (imgCache.TryGetValue(key, out var b)) return b;
        try
        {
            var real = url.StartsWith("http") ? Net.Px(url)! : url;
            b = new BitmapImage();
            if (decode > 0) b.DecodePixelWidth = decode;
            b.UriSource = new Uri(real);
            if (imgCache.Count > 600) imgCache.Clear();
            imgCache[key] = b;
            return b;
        }
        catch { return null; }
    }
}

/// <summary>Аватар: градиент с инициалами, поверх — фото; точка «в сети»</summary>
public sealed class AvatarView : Grid
{
    readonly Microsoft.UI.Xaml.Shapes.Ellipse back = new(), photo = new();
    readonly TextBlock initials = new() { HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center, Foreground = T.White, FontWeight = Microsoft.UI.Text.FontWeights.Bold };
    readonly Border dot;
    string? url;

    public AvatarView(double size)
    {
        Width = size; Height = size;
        initials.FontSize = size * 0.36;
        Children.Add(back); Children.Add(initials); Children.Add(photo);
        var d = size * 0.28;
        dot = new Border
        {
            Width = d, Height = d, CornerRadius = new CornerRadius(d / 2), Background = T.Ok, BorderBrush = T.Panel, BorderThickness = new Thickness(Math.Max(2, size / 22)),
            HorizontalAlignment = HorizontalAlignment.Right, VerticalAlignment = VerticalAlignment.Bottom, Visibility = Visibility.Collapsed,
        };
        Children.Add(dot);
    }

    public void Set(string name, string? avatar, int color, bool online = false)
    {
        back.Fill = T.AvatarBrush(color);
        initials.Text = Fmt.Initials(name);
        if (avatar != url)
        {
            url = avatar;
            var bmp = T.Bitmap(avatar, (int)(Width * 2));
            photo.Fill = bmp == null ? null : new ImageBrush { ImageSource = bmp, Stretch = Stretch.UniformToFill };
        }
        dot.Visibility = online ? Visibility.Visible : Visibility.Collapsed;
    }

    public void SetIcon(string glyph, Brush bg)
    {
        back.Fill = bg; initials.Text = ""; photo.Fill = null; url = null;
        if (Children.OfType<FontIcon>().FirstOrDefault() is not { } fi) { fi = T.Icon(glyph, Width * 0.42, T.White); fi.HorizontalAlignment = HorizontalAlignment.Center; fi.VerticalAlignment = VerticalAlignment.Center; Children.Insert(2, fi); }
        else fi.Glyph = glyph;
    }
}

/// <summary>Отметка статуса своего сообщения: часики, одна галочка (доставлено), две (прочитано)</summary>
public sealed class CheckMark : Grid
{
    readonly FontIcon a = T.Icon("\uE73E", 12), b = T.Icon("\uE73E", 12), clock = T.Icon("\uE823", 11);
    public CheckMark(double size = 12)
    {
        a.FontSize = size; b.FontSize = size; clock.FontSize = size - 1;
        b.Margin = new Thickness(size * 0.42, 0, 0, 0);
        Children.Add(a); Children.Add(b); Children.Add(clock);
        VerticalAlignment = VerticalAlignment.Center;
    }
    /// <summary>0 — скрыть, 1 — отправляется, 2 — отправлено, 3 — прочитано</summary>
    public void Set(int state, Brush fg)
    {
        Visibility = state == 0 ? Visibility.Collapsed : Visibility.Visible;
        a.Foreground = b.Foreground = clock.Foreground = fg;
        clock.Visibility = state == 1 ? Visibility.Visible : Visibility.Collapsed;
        a.Visibility = state >= 2 ? Visibility.Visible : Visibility.Collapsed;
        b.Visibility = state == 3 ? Visibility.Visible : Visibility.Collapsed;
    }
}
