using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Markup;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Shapes;

namespace Lumo.UI;

/// <summary>Рисованные значки игр и бросков (как на телефонах), без эмодзи</summary>
public static class Art
{
    static Geometry G(string data) => (Geometry)XamlBindingHelper.ConvertValue(typeof(Geometry), data);

    static Microsoft.UI.Xaml.Shapes.Path P(string data, Brush? fill, Brush? stroke = null, double sw = 0) =>
        new() { Data = G(data), Fill = fill, Stroke = stroke, StrokeThickness = sw, Stretch = Stretch.Uniform, StrokeStartLineCap = PenLineCap.Round, StrokeEndLineCap = PenLineCap.Round };

    static Ellipse E(double s, Brush fill, Brush? stroke = null, double sw = 0) => new() { Width = s, Height = s, Fill = fill, Stroke = stroke, StrokeThickness = sw };

    /// <summary>Значок игры вдвоём на цветной плашке</summary>
    public static FrameworkElement Game(string k, double size)
    {
        var colors = k switch
        {
            "ttt" => (0xFF22C1FFu, 0xFF3A7BFFu), "checkers" => (0xFFA7743Fu, 0xFF6B4426u), "sea" => (0xFF2BB3FFu, 0xFF1460C8u), "chess" => (0xFF4A4F5Cu, 0xFF16181Du),
            _ => (0xFF7C5CFFu, 0xFF22C1FFu),
        };
        var g = new Grid { Width = size, Height = size, CornerRadius = new CornerRadius(size * 0.3), Background = T.Grad(colors.Item1, colors.Item2) };
        FrameworkElement icon;
        switch (k)
        {
            case "ttt":
            {
                var sp = new StackPanel { Orientation = Orientation.Horizontal, Spacing = size * 0.06 };
                var x = P("M0,0 L10,10 M10,0 L0,10", null, T.White, size * 0.07); x.Width = size * 0.26; x.Height = size * 0.26;
                var o = E(size * 0.26, T.Transparent, T.White, size * 0.07);
                sp.Children.Add(x); sp.Children.Add(o);
                icon = sp; break;
            }
            case "checkers":
            {
                var gg = new Grid { Width = size * 0.6, Height = size * 0.6 };
                var bottom = E(size * 0.56, T.B(0xFF2A1A10)); bottom.Margin = new Thickness(0, size * 0.1, 0, 0);
                var top = E(size * 0.56, T.B(0xFFF4EAD6)); top.Margin = new Thickness(0, 0, 0, size * 0.06);
                var ring = E(size * 0.32, T.Transparent, T.B(0xFFC9A46A), size * 0.03); ring.Margin = new Thickness(0, 0, 0, size * 0.06);
                gg.Children.Add(bottom); gg.Children.Add(top); gg.Children.Add(ring);
                icon = gg; break;
            }
            case "sea":
                icon = P("M1,12 L19,12 L16,17 L4,17 Z M9.2,2 L9.2,10.8 L3.5,10.8 Z M10.6,4 L10.6,10.8 L16,10.8 Z", T.White);
                icon.Width = size * 0.6; icon.Height = size * 0.55; break;
            case "chess":
                icon = P("M3,17 C3,13 4.5,11 7,9 C5.4,9 4,9.8 3,11 L1,9.4 C0.5,8.7 0.5,7.9 1,7.2 C2.8,4.4 5.3,2.2 8.3,1.4 L9,0 L10.2,2.3 C13,3.9 14.7,7.1 14.7,11.3 C14.7,13.3 14.4,14.9 13.9,17 Z M1,17.6 L15,17.6 L15,19.2 L1,19.2 Z", T.White);
                icon.Width = size * 0.5; icon.Height = size * 0.62; break;
            default:
                icon = T.Icon("\uE7FC", size * 0.46, T.White); break;
        }
        icon.HorizontalAlignment = HorizontalAlignment.Center; icon.VerticalAlignment = VerticalAlignment.Center;
        g.Children.Add(icon);
        return g;
    }

    /// <summary>Бросок: кубик (с точками), дартс, баскетбол, футбол, монетка</summary>
    public static FrameworkElement Throw(string k, int v, double s)
    {
        var g = new Grid { Width = s, Height = s };
        switch (k)
        {
            case "dice":
            {
                var face = new Border { Width = s * 0.8, Height = s * 0.8, CornerRadius = new CornerRadius(s * 0.18), Background = T.Grad(0xFFFFFFFF, 0xFFDCD8F4) };
                var c = new Canvas { Width = s * 0.8, Height = s * 0.8 };
                var pips = v switch
                {
                    1 => new[] { (.5, .5) }, 2 => new[] { (.28, .28), (.72, .72) }, 3 => new[] { (.25, .25), (.5, .5), (.75, .75) },
                    4 => new[] { (.28, .28), (.72, .28), (.28, .72), (.72, .72) }, 5 => new[] { (.25, .25), (.75, .25), (.5, .5), (.25, .75), (.75, .75) },
                    _ => new[] { (.28, .22), (.72, .22), (.28, .5), (.72, .5), (.28, .78), (.72, .78) },
                };
                var d = s * 0.14;
                foreach (var (x, y) in pips)
                {
                    var e = E(d, v == 1 ? T.B(0xFFE0284F) : T.B(0xFF25264A));
                    Canvas.SetLeft(e, x * s * 0.8 - d / 2); Canvas.SetTop(e, y * s * 0.8 - d / 2);
                    c.Children.Add(e);
                }
                face.Child = c;
                g.Children.Add(face);
                break;
            }
            case "darts":
                foreach (var (r, col) in new[] { (.84, 0xFF25264Au), (.68, 0xFFF2EFE4u), (.52, 0xFFE0284Fu), (.36, 0xFFF2EFE4u), (.2, 0xFF2BB673u), (.08, 0xFFE0284Fu) })
                    g.Children.Add(E(s * r, T.B(col)));
                break;
            case "basket":
                g.Children.Add(E(s * 0.8, T.Grad(0xFFFF9A3D, 0xFFE0602A)));
                var lines = P("M0,10 L20,10 M10,0 L10,20 M3,3 C7,7 7,13 3,17 M17,3 C13,7 13,13 17,17", null, T.B(0xFF5A2A10), 1.2);
                lines.Width = s * 0.8; lines.Height = s * 0.8; g.Children.Add(lines);
                break;
            case "football":
                g.Children.Add(E(s * 0.8, T.White, T.B(0xFF25264A), s * 0.03));
                var pent = P("M10,6 L14,9 L12.5,13.5 L7.5,13.5 L6,9 Z", T.B(0xFF25264A)); pent.Width = s * 0.32; pent.Height = s * 0.3; g.Children.Add(pent);
                break;
            default:
                g.Children.Add(E(s * 0.8, T.Grad(0xFFFFD34D, 0xFFE0A21A)));
                g.Children.Add(E(s * 0.6, T.Transparent, T.B(0xFFB07A10), s * 0.03));
                var t = new TextBlock { Text = v == 1 ? "О" : "Р", FontSize = s * 0.32, FontWeight = Microsoft.UI.Text.FontWeights.Bold, Foreground = T.B(0xFF8A5A00), HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
                g.Children.Add(t);
                break;
        }
        foreach (var ch in g.Children.OfType<FrameworkElement>()) { ch.HorizontalAlignment = HorizontalAlignment.Center; ch.VerticalAlignment = VerticalAlignment.Center; }
        return g;
    }
}
