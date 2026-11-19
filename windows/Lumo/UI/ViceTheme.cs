using Lumo.Core;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Markup;
using Microsoft.UI.Xaml.Media;

namespace Lumo.UI;

/// <summary>
/// Временная тема «Vice Nights» (до 1 декабря): закат над океаном, неон, пальмы.
/// Основные формы и оформление Lumo остаются — тема только добавляет краски.
/// Срок задаёт сервер (lm_get_config → look.event), пользователь может отключить её в «Оформлении».
/// </summary>
public static class Vice
{
    public static event Action? Changed;
    public static bool Available
    {
        get
        {
            if (Environment.GetEnvironmentVariable("LUMO_DEMO") == "1") return true;   // скриншоты сборки
            if (Prefs.Get("vice_id") != "vice") return false;
            return DateTimeOffset.TryParse(Prefs.Get("vice_until"), out var u) ? u > DateTimeOffset.UtcNow : true;
        }
    }
    public static bool Off => Prefs.GetBool("vice_off");
    public static bool On => Available && !Off;
    public static void SetOff(bool v) { Prefs.Set("vice_off", v); Changed?.Invoke(); }

    /// <summary>Узнать у сервера, идёт ли тема (запоминается, работает и без сети)</summary>
    public static async Task Refresh()
    {
        try
        {
            var o = await Api.Rpc("lm_get_config");
            var e = o.Get("look").Get("event");
            var was = On;
            Prefs.Set("vice_id", e.Str("id") ?? "");
            Prefs.Set("vice_until", e.Str("until") ?? "");
            if (was != On) Changed?.Invoke();
        }
        catch { }
    }

    public static Brush OutBrush => T.Grad(0xFFFF4F8B, 0xFFFF8A3D);
    public static readonly FontFamily TitleFont = new("Bahnschrift SemiBold Condensed, Bahnschrift, Segoe UI");

    const string Ns = "xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'";

    /// <summary>Небо на закате за шапкой списка чатов: солнце, город и пальмы, плавно уходит в фон</summary>
    public static UIElement Sky() => (UIElement)XamlReader.Load($@"
<Grid {Ns} Height='230' VerticalAlignment='Top' IsHitTestVisible='False'>
  <Grid.OpacityMask>
    <LinearGradientBrush StartPoint='0,0' EndPoint='0,1'><GradientStop Color='#FF000000' Offset='0.65'/><GradientStop Color='#00000000' Offset='1'/></LinearGradientBrush>
  </Grid.OpacityMask>
  <Rectangle>
    <Rectangle.Fill>
      <LinearGradientBrush StartPoint='0,0' EndPoint='0,1'>
        <GradientStop Color='#2A0F52' Offset='0'/><GradientStop Color='#8A2C8F' Offset='0.38'/><GradientStop Color='#FF4F8B' Offset='0.66'/>
        <GradientStop Color='#FF9A3D' Offset='0.86'/><GradientStop Color='#FFD36B' Offset='1'/>
      </LinearGradientBrush>
    </Rectangle.Fill>
  </Rectangle>
  <Viewbox Stretch='UniformToFill' VerticalAlignment='Bottom'>
    <Canvas Width='390' Height='230'>
      <Ellipse Canvas.Left='140' Canvas.Top='140' Width='110' Height='110'>
        <Ellipse.Fill><LinearGradientBrush StartPoint='0,0' EndPoint='0,1'><GradientStop Color='#FFE58A' Offset='0'/><GradientStop Color='#FF8A3D' Offset='1'/></LinearGradientBrush></Ellipse.Fill>
      </Ellipse>
      <Rectangle Canvas.Left='140' Canvas.Top='200' Width='110' Height='3' Fill='#D9FF4F8B'/>
      <Rectangle Canvas.Left='140' Canvas.Top='212' Width='110' Height='4' Fill='#D9FF4F8B'/>
      <Path Fill='#1A0B33' Data='M0 230 L0 194 L28 194 L28 176 L46 176 L46 190 L68 190 L68 152 L84 152 L84 190 L118 190 L118 182 L140 182 L140 202 L242 202 L242 160 L256 160 L256 138 L268 138 L268 160 L284 160 L284 186 L322 186 L322 170 L346 170 L346 192 L390 192 L390 230 Z'/>
      <Path Stroke='#120826' StrokeThickness='5' StrokeStartLineCap='Round' StrokeEndLineCap='Round' Data='M40 230 C42 196 44 150 52 112'/>
      <Path Stroke='#120826' StrokeThickness='4.5' StrokeStartLineCap='Round' StrokeEndLineCap='Round' Data='M52 112 C38 104 22 108 10 118 M52 112 C64 100 84 100 96 108 M52 112 C46 96 34 88 22 88 M52 112 C66 112 80 122 86 134 M52 112 C40 118 30 130 28 144'/>
      <Path Stroke='#120826' StrokeThickness='5' StrokeStartLineCap='Round' StrokeEndLineCap='Round' Data='M342 230 C340 200 336 168 328 134'/>
      <Path Stroke='#120826' StrokeThickness='4.5' StrokeStartLineCap='Round' StrokeEndLineCap='Round' Data='M328 134 C316 124 300 126 290 136 M328 134 C340 120 358 120 370 128 M328 134 C322 118 310 110 298 110 M328 134 C342 136 352 146 358 158'/>
    </Canvas>
  </Viewbox>
</Grid>");

    /// <summary>Ночная сцена для фона переписки: градиент, неоновая сетка и пальма</summary>
    public static UIElement NightWall() => (UIElement)XamlReader.Load($@"
<Grid {Ns} IsHitTestVisible='False'>
  <Rectangle>
    <Rectangle.Fill>
      <LinearGradientBrush StartPoint='0,0' EndPoint='0,1'>
        <GradientStop Color='#1A0B3A' Offset='0'/><GradientStop Color='#2B0F4F' Offset='0.45'/><GradientStop Color='#4A1559' Offset='0.72'/><GradientStop Color='#6B1D55' Offset='1'/>
      </LinearGradientBrush>
    </Rectangle.Fill>
  </Rectangle>
  <Viewbox Stretch='UniformToFill'>
    <Canvas Width='800' Height='800' Opacity='0.85'>
      <Path Stroke='#2E2FD6D0' StrokeThickness='1' Data='M0 500 L800 500 M0 520 L800 520 M0 550 L800 550 M0 590 L800 590 M0 640 L800 640 M0 700 L800 700 M0 770 L800 770'/>
      <Path Stroke='#29FF4F8B' StrokeThickness='1' Data='M400 500 L400 800 M370 500 L190 800 M340 500 L-20 800 M430 500 L610 800 M460 500 L820 800 M310 500 L-230 800 M490 500 L1030 800'/>
      <Path Stroke='#2EFF9A3D' StrokeThickness='7' StrokeStartLineCap='Round' StrokeEndLineCap='Round' Data='M640 500 C640 420 634 340 620 250'/>
      <Path Stroke='#2EFF9A3D' StrokeThickness='6' StrokeStartLineCap='Round' StrokeEndLineCap='Round' Data='M620 250 C600 236 572 240 556 258 M620 250 C640 228 672 228 692 242 M620 250 C610 222 590 210 570 212 M620 250 C646 254 662 274 668 296 M620 250 C602 262 588 284 586 306'/>
    </Canvas>
  </Viewbox>
</Grid>");

    /// <summary>Плашка-«стикер» для даты, как на загрузочных экранах: жёлтая, с обводкой и тенью</summary>
    public static UIElement Plaque(string text)
    {
        var g = new Grid { HorizontalAlignment = HorizontalAlignment.Center, Margin = new Thickness(0, 10, 0, 6), RenderTransformOrigin = new Windows.Foundation.Point(0.5, 0.5), RenderTransform = new RotateTransform { Angle = -2 } };
        g.Children.Add(new Border { Background = T.B(0xFF0C0620), CornerRadius = new CornerRadius(7), Margin = new Thickness(3, 3, -3, -3) });
        var tb = new TextBlock { Text = text.ToUpperInvariant(), FontFamily = TitleFont, FontSize = 14, Foreground = T.B(0xFF140A2E), CharacterSpacing = 60 };
        g.Children.Add(new Border { Background = T.B(0xFFFFD36B), CornerRadius = new CornerRadius(7), Padding = new Thickness(11, 3, 11, 4), Child = tb });
        return g;
    }
}
