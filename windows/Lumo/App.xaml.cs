using Lumo.Core;
using Lumo.UI;
using Microsoft.UI.Xaml;
using Microsoft.Windows.AppNotifications;

namespace Lumo;

public partial class App : Application
{
    public static MainWindow? Win { get; private set; }

    public App()
    {
        InitializeComponent();
        UnhandledException += (_, e) => { e.Handled = true; Log("ui: " + e.Exception); try { Core.Store.Say("Ошибка: " + e.Message); } catch { } };
        AppDomain.CurrentDomain.UnhandledException += (_, e) => Log("domain: " + e.ExceptionObject);
        TaskScheduler.UnobservedTaskException += (_, e) => { e.SetObserved(); Log("task: " + e.Exception); };
    }

    public static void Log(string s)
    {
        try { Directory.CreateDirectory(Prefs.Dir); File.AppendAllText(Path.Combine(Prefs.Dir, "log.txt"), DateTime.Now.ToString("s") + " " + s + "\n"); } catch { }
    }

    protected override void OnLaunched(LaunchActivatedEventArgs args)
    {
        Api.Init();
        Win = new MainWindow();
        Notifications.Init(Win);
        Win.Activate();
    }
}
