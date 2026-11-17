using Lumo.Core;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Media.Imaging;
using Microsoft.UI.Xaml.Shapes;
using Windows.Graphics.Imaging;
using Windows.Storage.Streams;
using System.Runtime.InteropServices.WindowsRuntime;

namespace Lumo.UI;

/// <summary>Фото профиля, как в мобильной версии: выбрать фото → выбрать область (двигать, колесо — масштаб) → галочка</summary>
public static class AvatarCrop
{
    const double Side = 340;

    public static async Task<bool> PickAndSet(MainWindow win)
    {
        var p = new Windows.Storage.Pickers.FileOpenPicker();
        WinRT.Interop.InitializeWithWindow.Initialize(p, win.Hwnd);
        foreach (var e in new[] { ".jpg", ".jpeg", ".png", ".webp", ".bmp", ".heic" }) p.FileTypeFilter.Add(e);
        var f = await p.PickSingleFileAsync();
        if (f == null) return false;
        byte[]? jpg;
        try { jpg = await Crop(await File.ReadAllBytesAsync(f.Path)); }
        catch (Exception e) { Store.Say("Не удалось открыть фото: " + e.Message); return false; }
        if (jpg == null) return false;
        var err = await Store.SetAvatar(jpg, "jpg", "image/jpeg");
        if (err != null) { Store.Say(err); return false; }
        Store.Say("Фото обновлено");
        return true;
    }

    /// <summary>Окно выбора области; возвращает JPEG квадрата (до 1024×1024) или null</summary>
    static async Task<byte[]?> Crop(byte[] src)
    {
        var ras = new InMemoryRandomAccessStream();
        await ras.WriteAsync(src.AsBuffer()); ras.Seek(0);
        var dec = await BitmapDecoder.CreateAsync(ras);
        var sb = await dec.GetSoftwareBitmapAsync(BitmapPixelFormat.Bgra8, BitmapAlphaMode.Premultiplied, new BitmapTransform(), ExifOrientationMode.RespectExifOrientation, ColorManagementMode.ColorManageToSRgb);
        double W = sb.PixelWidth, H = sb.PixelHeight;
        var show = new SoftwareBitmapSource(); await show.SetBitmapAsync(sb);

        double baseK = Math.Max(Side / W, Side / H), scale = 1, ox = 0, oy = 0;
        var img = new Image { Source = show, Stretch = Stretch.Fill };
        var canvas = new Canvas { Width = Side, Height = Side, Background = T.B(0xFF000000) };
        canvas.Children.Add(img);
        // затемнение вокруг круга
        var mask = new Microsoft.UI.Xaml.Shapes.Path
        {
            Fill = T.B(0x99000000), IsHitTestVisible = false,
            Data = new GeometryGroup { FillRule = FillRule.EvenOdd, Children = { new RectangleGeometry { Rect = new Windows.Foundation.Rect(0, 0, Side, Side) }, new EllipseGeometry { Center = new Windows.Foundation.Point(Side / 2, Side / 2), RadiusX = Side / 2 - 2, RadiusY = Side / 2 - 2 } } },
        };
        canvas.Children.Add(mask);
        canvas.Children.Add(new Ellipse { Width = Side - 4, Height = Side - 4, Stroke = T.B(0xE6FFFFFF), StrokeThickness = 2, IsHitTestVisible = false, Margin = new Thickness(2) });
        Canvas.SetLeft(canvas.Children[^1], 2); Canvas.SetTop(canvas.Children[^1], 2);
        var holder = new Border { Width = Side, Height = Side, CornerRadius = new CornerRadius(18), Child = canvas, HorizontalAlignment = HorizontalAlignment.Center };

        void Clamp()
        {
            var w = W * baseK * scale; var h = H * baseK * scale;
            var mx = Math.Max(0, (w - Side) / 2); var my = Math.Max(0, (h - Side) / 2);
            ox = Math.Clamp(ox, -mx, mx); oy = Math.Clamp(oy, -my, my);
        }
        void Layout()
        {
            Clamp();
            var w = W * baseK * scale; var h = H * baseK * scale;
            img.Width = w; img.Height = h;
            Canvas.SetLeft(img, (Side - w) / 2 + ox); Canvas.SetTop(img, (Side - h) / 2 + oy);
        }
        Layout();

        var zoom = new Slider { Minimum = 1, Maximum = 5, StepFrequency = 0.01, Value = 1, Width = Side, HorizontalAlignment = HorizontalAlignment.Center };
        zoom.ValueChanged += (_, e) => { scale = e.NewValue; Layout(); };
        bool drag = false; Windows.Foundation.Point last = default;
        canvas.PointerPressed += (_, e) => { drag = true; last = e.GetCurrentPoint(canvas).Position; canvas.CapturePointer(e.Pointer); };
        canvas.PointerMoved += (_, e) => { if (!drag) return; var pt = e.GetCurrentPoint(canvas).Position; ox += pt.X - last.X; oy += pt.Y - last.Y; last = pt; Layout(); };
        canvas.PointerReleased += (_, e) => { drag = false; canvas.ReleasePointerCapture(e.Pointer); };
        canvas.PointerWheelChanged += (_, e) => { var d = e.GetCurrentPoint(canvas).Properties.MouseWheelDelta; zoom.Value = Math.Clamp(zoom.Value * (d > 0 ? 1.1 : 1 / 1.1), 1, 5); e.Handled = true; };

        var sp = new StackPanel { Spacing = 12 };
        sp.Children.Add(holder);
        var zr = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 10, HorizontalAlignment = HorizontalAlignment.Center };
        zr.Children.Add(T.Icon("", 14, T.Muted)); zr.Children.Add(zoom); zr.Children.Add(T.Icon("", 14, T.Muted));
        sp.Children.Add(zr);
        var hint = T.Txt("Перетащите фото и прокрутите колёсико, чтобы выбрать область", 12.5, T.Muted); hint.HorizontalAlignment = HorizontalAlignment.Center;
        sp.Children.Add(hint);
        var sheet = new Sheet { Title = "Выбор области", Content = sp, PrimaryButtonText = "Готово", CloseButtonText = "Отмена", Width = 420 };
        if (await sheet.ShowAsync() != ContentDialogResult.Primary) return null;

        // видимый квадрат в пикселях исходника
        var k = baseK * scale;
        var cx = W / 2 - ox / k; var cy = H / 2 - oy / k; var half = Side / 2 / k;
        var x = (uint)Math.Clamp(cx - half, 0, W - 1); var y = (uint)Math.Clamp(cy - half, 0, H - 1);
        var s = (uint)Math.Max(1, Math.Min(half * 2, Math.Min(W - x, H - y)));
        var outSide = Math.Min(s, 1024u);
        var ms = new InMemoryRandomAccessStream();
        var enc = await BitmapEncoder.CreateAsync(BitmapEncoder.JpegEncoderId, ms);
        enc.SetSoftwareBitmap(sb);
        enc.BitmapTransform.Bounds = new BitmapBounds { X = (uint)(x * outSide / (double)s), Y = (uint)(y * outSide / (double)s), Width = outSide, Height = outSide };
        enc.BitmapTransform.ScaledWidth = (uint)Math.Round(W * outSide / s);
        enc.BitmapTransform.ScaledHeight = (uint)Math.Round(H * outSide / s);
        enc.BitmapTransform.InterpolationMode = BitmapInterpolationMode.Fant;
        await enc.FlushAsync();
        var bytes = new byte[ms.Size];
        ms.Seek(0);
        await ms.ReadAsync(bytes.AsBuffer(), (uint)ms.Size, InputStreamOptions.None);
        return bytes;
    }
}
