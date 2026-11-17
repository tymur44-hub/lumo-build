using System.Diagnostics;
using System.Reflection;
using System.Text.Json.Nodes;

namespace Lumo.Core;

/// <summary>
/// Обновления ПК-версии: раз в 20 минут смотрим релизы на GitHub (windows-native-N).
/// Нашли номер новее — показываем «Обновить Lumo»; по нажатию качаем установщик, ставим тихо и перезапускаемся.
/// </summary>
public static class Updater
{
    const string Repo = "tymur44-hub/lumo-build";
    static readonly HttpClient http = new() { Timeout = TimeSpan.FromSeconds(30) };

    /// <summary>номер сборки этой программы (из версии 1.0.N)</summary>
    public static int Build
    {
        get
        {
            var v = Assembly.GetExecutingAssembly().GetName().Version;
            return v?.Build ?? 0;
        }
    }
    public static string VersionText => "1.0." + Build;

    public static int Latest { get; private set; }
    public static string? SetupUrl { get; private set; }
    public static bool Available => Latest > Build && SetupUrl != null && Build > 0;
    /// <summary>-1 — не качаем, 0..1 — скачивание, 2 — запуск установщика</summary>
    public static double State { get; private set; } = -1;
    public static event Action? Changed;

    static Microsoft.UI.Dispatching.DispatcherQueue? ui;
    static Timer? timer;

    public static void Start()
    {
        ui = Microsoft.UI.Dispatching.DispatcherQueue.GetForCurrentThread();
        http.DefaultRequestHeaders.UserAgent.ParseAdd("Lumo-Windows/" + VersionText);
        timer = new Timer(_ => _ = Check(), null, TimeSpan.FromSeconds(8), TimeSpan.FromMinutes(20));
    }

    public static async Task Check()
    {
        try
        {
            var s = await http.GetStringAsync($"https://api.github.com/repos/{Repo}/releases?per_page=30");
            var arr = JsonNode.Parse(s) as JsonArray;
            int best = 0; string? url = null;
            foreach (var r in arr ?? new JsonArray())
            {
                var tag = r?["tag_name"]?.GetValue<string>() ?? "";
                if (!tag.StartsWith("windows-native-") || r?["draft"]?.GetValue<bool>() == true) continue;
                if (!int.TryParse(tag["windows-native-".Length..], out var n) || n <= best) continue;
                foreach (var a in r?["assets"]?.AsArray() ?? new JsonArray())
                    if (a?["name"]?.GetValue<string>() == "Lumo-Setup.exe") { best = n; url = a["browser_download_url"]?.GetValue<string>(); }
            }
            if (best > 0 && (best != Latest || url != SetupUrl))
            {
                Latest = best; SetupUrl = url;
                App.Log($"update: have {Build}, latest {best}");
                ui?.TryEnqueue(() => Changed?.Invoke());
            }
        }
        catch (Exception e) { App.Log("update check: " + e.Message); }
    }

    public static async Task Install()
    {
        if (!Available || State >= 0) return;
        var path = Path.Combine(Path.GetTempPath(), $"Lumo-Setup-{Latest}.exe");
        try
        {
            Set(0);
            using (var resp = await http.GetAsync(SetupUrl, HttpCompletionOption.ResponseHeadersRead))
            {
                resp.EnsureSuccessStatusCode();
                var total = resp.Content.Headers.ContentLength ?? 0;
                await using var src = await resp.Content.ReadAsStreamAsync();
                await using var dst = File.Create(path);
                var buf = new byte[1 << 16]; long done = 0; int n; double last = 0;
                while ((n = await src.ReadAsync(buf)) > 0)
                {
                    await dst.WriteAsync(buf.AsMemory(0, n)); done += n;
                    if (total > 0) { var f = (double)done / total; if (f - last > 0.01) { last = f; Set(f); } }
                }
            }
            Set(2);
            // тихая установка поверх, установщик сам закроет старую версию и запустит новую
            Process.Start(new ProcessStartInfo(path, "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS") { UseShellExecute = true });
            await Task.Delay(600);
            Environment.Exit(0);
        }
        catch (Exception e)
        {
            App.Log("update install: " + e);
            Set(-1);
            Store.Say("Не удалось скачать обновление: " + e.Message);
        }
    }

    static void Set(double v) { State = v; ui?.TryEnqueue(() => Changed?.Invoke()); }
}
