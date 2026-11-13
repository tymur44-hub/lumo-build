using System.Security.Cryptography;
using System.Text;
using System.Text.Json.Nodes;

namespace Lumo.Core;

/// <summary>Настройки на компьютере: %LOCALAPPDATA%\Lumo\prefs.json. Секреты шифруются средствами Windows (DPAPI).</summary>
public static class Prefs
{
    public static readonly string Dir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Lumo");
    static readonly string FilePath = Path.Combine(Dir, "prefs.json");
    static JsonObject? data;
    static readonly object gate = new();

    static JsonObject D
    {
        get
        {
            if (data != null) return data;
            try { Directory.CreateDirectory(Dir); if (File.Exists(FilePath)) data = JsonNode.Parse(File.ReadAllText(FilePath)) as JsonObject; } catch { }
            return data ??= new JsonObject();
        }
    }

    public static string? Get(string k) { lock (gate) return D.Str(k); }
    public static long GetLong(string k, long def = 0) { lock (gate) return D.Long(k) ?? def; }
    public static bool GetBool(string k, bool def = false) { lock (gate) return D.Has(k) ? D.Bool(k) : def; }

    public static void Set(string k, object? v)
    {
        lock (gate)
        {
            if (v == null) D.Remove(k); else D[k] = J.ToNode(v);
            Save();
        }
    }

    public static void Remove(params string[] keys) { lock (gate) { foreach (var k in keys) D.Remove(k); Save(); } }

    static void Save()
    {
        try
        {
            Directory.CreateDirectory(Dir);
            var tmp = FilePath + ".tmp";
            File.WriteAllText(tmp, D.ToJsonString());
            File.Move(tmp, FilePath, true);
        }
        catch { }
    }

    /// <summary>Секрет: зашифрован ключом текущего пользователя Windows</summary>
    public static void SetSecret(string k, string? v)
    {
        if (v == null) { Set(k, null); return; }
        try { Set(k, "d:" + Convert.ToBase64String(ProtectedData.Protect(Encoding.UTF8.GetBytes(v), null, DataProtectionScope.CurrentUser))); }
        catch { Set(k, "p:" + v); }
    }

    public static string? GetSecret(string k)
    {
        var s = Get(k);
        if (s == null) return null;
        try
        {
            if (s.StartsWith("d:")) return Encoding.UTF8.GetString(ProtectedData.Unprotect(Convert.FromBase64String(s[2..]), null, DataProtectionScope.CurrentUser));
            if (s.StartsWith("p:")) return s[2..];
        }
        catch { }
        return null;
    }
}
