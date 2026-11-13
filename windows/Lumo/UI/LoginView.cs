using Lumo.Core;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media.Imaging;

namespace Lumo.UI;

/// <summary>Вход и регистрация по юзернейму и паролю (как на телефоне и в веб-версии)</summary>
public sealed class LoginView : Grid
{
    bool register;
    readonly TextBox user = new() { PlaceholderText = "Юзернейм", Height = 40 };
    readonly TextBox name = new() { PlaceholderText = "Ваше имя", Height = 40, Visibility = Visibility.Collapsed };
    readonly PasswordBox pass = new() { PlaceholderText = "Пароль", Height = 40 };
    readonly TextBlock title = T.Txt("Вход в Lumo", 24, bold: true);
    readonly TextBlock sub = T.Txt("Введите юзернейм и пароль от аккаунта", 13, T.Muted);
    readonly TextBlock err = T.Txt("", 13, T.Danger);
    readonly Button go;
    readonly HyperlinkButton sw = new() { HorizontalAlignment = HorizontalAlignment.Center };
    readonly ProgressRing ring = new() { IsActive = false, Width = 22, Height = 22, Visibility = Visibility.Collapsed };

    public LoginView()
    {
        Background = T.Bg;
        var card = new StackPanel { Width = 360, Spacing = 12, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center };
        try
        {
            card.Children.Add(new Image { Source = new BitmapImage(new Uri(Path.Combine(AppContext.BaseDirectory, "Assets", "logo.png"))), Width = 84, Height = 84, Margin = new Thickness(0, 0, 0, 8) });
        }
        catch { }
        title.HorizontalAlignment = HorizontalAlignment.Center; title.TextAlignment = TextAlignment.Center;
        sub.HorizontalAlignment = HorizontalAlignment.Center; sub.TextAlignment = TextAlignment.Center;
        card.Children.Add(title);
        card.Children.Add(sub);
        card.Children.Add(new Border { Height = 6 });
        card.Children.Add(name);
        card.Children.Add(user);
        card.Children.Add(pass);
        card.Children.Add(err);
        go = T.Primary("Войти", Submit);
        card.Children.Add(go);
        ring.HorizontalAlignment = HorizontalAlignment.Center;
        card.Children.Add(ring);
        sw.Content = "Нет аккаунта? Зарегистрироваться";
        sw.Click += (_, _) => Toggle();
        card.Children.Add(sw);
        Children.Add(card);
        pass.KeyDown += (_, e) => { if (e.Key == Windows.System.VirtualKey.Enter) Submit(); };
        user.KeyDown += (_, e) => { if (e.Key == Windows.System.VirtualKey.Enter) pass.Focus(FocusState.Keyboard); };
    }

    void Toggle()
    {
        register = !register;
        title.Text = register ? "Регистрация" : "Вход в Lumo";
        sub.Text = register ? "Придумайте юзернейм (латиница, цифры, _) и пароль" : "Введите юзернейм и пароль от аккаунта";
        name.Visibility = register ? Visibility.Visible : Visibility.Collapsed;
        ((TextBlock)go.Content).Text = register ? "Создать аккаунт" : "Войти";
        sw.Content = register ? "Уже есть аккаунт? Войти" : "Нет аккаунта? Зарегистрироваться";
        err.Text = "";
    }

    async void Submit()
    {
        var u = user.Text.Trim().TrimStart('@').ToLowerInvariant();
        var p = pass.Password;
        if (u.Length < 3) { err.Text = "Юзернейм — не короче 3 символов"; return; }
        if (p.Length < 6) { err.Text = "Пароль — не короче 6 символов"; return; }
        if (register && name.Text.Trim().Length == 0) { err.Text = "Введите имя"; return; }
        err.Text = ""; go.IsEnabled = false; ring.IsActive = true; ring.Visibility = Visibility.Visible;
        try
        {
            await Net.Pick();
            if (register) await Api.Register(u, p, name.Text.Trim()); else await Api.SignIn(u, p);
        }
        catch (Exception e) { err.Text = e.Message; }
        finally { go.IsEnabled = true; ring.IsActive = false; ring.Visibility = Visibility.Collapsed; }
    }
}
