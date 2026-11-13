using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Media.Animation;

namespace Lumo.UI;

/// <summary>
/// Окно внутри приложения (вместо системного ContentDialog): затемнение, карточка в цветах Lumo,
/// свои кнопки. Результат — как у ContentDialog, чтобы не менять остальной код.
/// </summary>
public sealed class Sheet
{
    public static Grid? Layer;
    static readonly List<Sheet> stack = new();

    public string Title { get; set; } = "";
    public object? Content { get; set; }
    public string PrimaryButtonText { get; set; } = "";
    public string SecondaryButtonText { get; set; } = "";
    public string CloseButtonText { get; set; } = "";
    public bool DangerSecondary { get; set; }
    public double Width { get; set; } = 440;

    Grid? root;
    TaskCompletionSource<ContentDialogResult>? tcs;

    public static bool IsOpen => stack.Count > 0;

    public Task<ContentDialogResult> ShowAsync()
    {
        tcs = new TaskCompletionSource<ContentDialogResult>();
        if (Layer == null) { tcs.SetResult(ContentDialogResult.None); return tcs.Task; }
        root = new Grid { Background = T.Dim };
        root.Tapped += (_, e) => { if (e.OriginalSource == root) Finish(ContentDialogResult.None); };

        var card = new Border
        {
            Background = T.Panel, CornerRadius = new CornerRadius(22), BorderBrush = T.B(0x22FFFFFF), BorderThickness = new Thickness(1),
            Width = Width, MaxHeight = 720, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center,
            Translation = new System.Numerics.Vector3(0, 0, 40), Shadow = new ThemeShadow(),
        };
        var g = new Grid { Padding = new Thickness(22, 16, 22, 18), RowSpacing = 14 };
        g.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
        g.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
        g.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

        var head = new Grid();
        head.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        head.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        var t = T.Txt(Title, 18, bold: true, lines: 1); t.VerticalAlignment = VerticalAlignment.Center;
        head.Children.Add(t);
        var x = T.IconButton("", "Закрыть (Esc)", () => Finish(ContentDialogResult.None), 32, 12);
        Grid.SetColumn(x, 1); head.Children.Add(x);
        g.Children.Add(head);

        var body = new ScrollViewer { Content = Content, VerticalScrollBarVisibility = ScrollBarVisibility.Auto, HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled };
        Grid.SetRow(body, 1); g.Children.Add(body);

        var foot = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 8, HorizontalAlignment = HorizontalAlignment.Right };
        if (SecondaryButtonText.Length > 0) foot.Children.Add(Btn(SecondaryButtonText, DangerSecondary ? 2 : 0, ContentDialogResult.Secondary));
        if (CloseButtonText.Length > 0) foot.Children.Add(Btn(CloseButtonText, 0, ContentDialogResult.None));
        if (PrimaryButtonText.Length > 0) foot.Children.Add(Btn(PrimaryButtonText, 1, ContentDialogResult.Primary));
        if (foot.Children.Count > 0) { Grid.SetRow(foot, 2); g.Children.Add(foot); }
        card.Child = g;
        root.Children.Add(card);

        var esc = new KeyboardAccelerator { Key = Windows.System.VirtualKey.Escape };
        esc.Invoked += (_, e) => { e.Handled = true; Finish(ContentDialogResult.None); };
        root.KeyboardAccelerators.Add(esc);
        if (PrimaryButtonText.Length > 0)
        {
            var enter = new KeyboardAccelerator { Key = Windows.System.VirtualKey.Enter, Modifiers = Windows.System.VirtualKeyModifiers.Control };
            enter.Invoked += (_, e) => { e.Handled = true; Finish(ContentDialogResult.Primary); };
            root.KeyboardAccelerators.Add(enter);
        }

        // плавное появление
        root.Opacity = 0;
        card.Scale = new System.Numerics.Vector3(0.96f, 0.96f, 1);
        card.ScaleTransition = new Vector3Transition { Duration = TimeSpan.FromMilliseconds(180) };
        root.OpacityTransition = new ScalarTransition { Duration = TimeSpan.FromMilliseconds(160) };
        card.Loaded += (_, _) => { card.CenterPoint = new System.Numerics.Vector3((float)(card.ActualWidth / 2), (float)(card.ActualHeight / 2), 0); root.Opacity = 1; card.Scale = new System.Numerics.Vector3(1, 1, 1); };

        Layer.Children.Add(root);
        Layer.Visibility = Visibility.Visible;
        stack.Add(this);
        return tcs.Task;
    }

    Button Btn(string text, int kind, ContentDialogResult r)
    {
        var b = new Button
        {
            Content = new TextBlock { Text = text, FontWeight = Microsoft.UI.Text.FontWeights.SemiBold, Foreground = kind == 1 ? T.White : kind == 2 ? T.Danger : T.Text },
            BorderThickness = new Thickness(0), CornerRadius = new CornerRadius(12),
            Height = 40, Padding = new Thickness(18, 0, 18, 0),
        };
        T.Fill(b, kind == 1 ? T.Accent : T.Panel2, kind == 1 ? T.Grad(0xFF8C70FF, 0xFF45CCFF) : T.B(0xFF24264A));
        b.Click += (_, _) => Finish(r);
        return b;
    }

    public void Hide() => Finish(ContentDialogResult.None);

    public static void CloseTop() { if (stack.Count > 0) stack[^1].Hide(); }

    async void Finish(ContentDialogResult r)
    {
        if (root == null || tcs == null || tcs.Task.IsCompleted) return;
        stack.Remove(this);
        tcs.TrySetResult(r);
        var rr = root;
        rr.IsHitTestVisible = false;
        rr.Opacity = 0;
        await Task.Delay(170);
        Layer?.Children.Remove(rr);
        if (Layer != null && Layer.Children.Count == 0) Layer.Visibility = Visibility.Collapsed;
    }
}
