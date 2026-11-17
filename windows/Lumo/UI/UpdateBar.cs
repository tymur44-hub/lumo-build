using Lumo.Core;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace Lumo.UI;

/// <summary>Плашка «Доступно обновление» с кнопкой «Обновить Lumo» и прогрессом скачивания</summary>
public sealed class UpdateBar : Grid
{
    readonly TextBlock text = T.Txt("Доступно обновление", 13.5, T.White, bold: true, lines: 1);
    readonly TextBlock sub = T.Txt("", 11.5, T.B(0xE6FFFFFF), lines: 1);
    readonly Button btn = new() { CornerRadius = new CornerRadius(14), Padding = new Thickness(14, 6, 14, 6), BorderThickness = new Thickness(0) };
    readonly ProgressBar bar = new() { Minimum = 0, Maximum = 1, Height = 3, VerticalAlignment = VerticalAlignment.Bottom, Visibility = Visibility.Collapsed, Foreground = T.White };

    public UpdateBar()
    {
        Margin = new Thickness(12, 0, 12, 8); CornerRadius = new CornerRadius(14);
        Background = T.Grad(0xFF6C5CE7, 0xFF2D98DA);
        Visibility = Visibility.Collapsed; Opacity = 0;
        var g = new Grid { Padding = new Thickness(12, 8, 8, 8), ColumnSpacing = 10 };
        g.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        g.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        g.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        var ic = T.Icon("", 18, T.White); ic.VerticalAlignment = VerticalAlignment.Center;
        g.Children.Add(ic);
        var sp = new StackPanel { VerticalAlignment = VerticalAlignment.Center };
        sp.Children.Add(text); sp.Children.Add(sub);
        Grid.SetColumn(sp, 1); g.Children.Add(sp);
        btn.Content = T.Txt("Обновить Lumo", 13, T.B(0xFF4B3FC4), bold: true);
        T.Fill(btn, T.White);
        btn.Click += async (_, _) => await Updater.Install();
        Grid.SetColumn(btn, 2); g.Children.Add(btn);
        Children.Add(g); Children.Add(bar);
        Loaded += (_, _) => { Updater.Changed += Upd; Upd(); };
        Unloaded += (_, _) => Updater.Changed -= Upd;
    }

    void Upd()
    {
        Music.Fade(this, Updater.Available);
        if (!Updater.Available) return;
        var s = Updater.State;
        if (s < 0) { text.Text = "Доступно обновление"; sub.Text = $"Версия 1.0.{Updater.Latest} · у вас {Updater.VersionText}"; btn.IsEnabled = true; bar.Visibility = Visibility.Collapsed; }
        else if (s <= 1) { text.Text = "Скачиваем обновление…"; sub.Text = $"{(int)(s * 100)}%"; btn.IsEnabled = false; bar.Visibility = Visibility.Visible; bar.Value = s; }
        else { text.Text = "Устанавливаем…"; sub.Text = "Lumo перезапустится сам"; btn.IsEnabled = false; bar.Visibility = Visibility.Collapsed; }
    }
}
