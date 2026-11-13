using System.Security.Cryptography;
using System.Text;
using Windows.Graphics.Imaging;
using Windows.Storage;

namespace Lumo.Core;

/// <summary>Файлы: размеры картинок, кэш скачанного, сохранение в «Загрузки»</summary>
public static class Media
{
    public static readonly string CacheDir = Path.Combine(Prefs.Dir, "cache");

    public static async Task<(int w, int h)> ImageSize(string path)
    {
        var f = await StorageFile.GetFileFromPathAsync(path);
        using var s = await f.OpenReadAsync();
        var d = await BitmapDecoder.CreateAsync(s);
        return ((int)d.OrientedPixelWidth, (int)d.OrientedPixelHeight);
    }

    static string Hash(string s) => Convert.ToHexString(SHA1.HashData(Encoding.UTF8.GetBytes(s)))[..16];

    static readonly Dictionary<string, Task<string?>> inflight = new();

    /// <summary>Скачать файл в кэш (с частями для больших файлов); путь к файлу на диске</summary>
    public static Task<string?> Cached(string url, string? name = null, List<string>? parts = null, IProgress<double>? progress = null)
    {
        var key = url + "|" + name;
        lock (inflight)
        {
            if (inflight.TryGetValue(key, out var t)) return t;
            t = Fetch(url, name, parts, progress);
            inflight[key] = t;
            return t;
        }
    }

    static async Task<string?> Fetch(string url, string? name, List<string>? parts, IProgress<double>? progress)
    {
        try
        {
            Directory.CreateDirectory(CacheDir);
            var ext = Path.GetExtension(name ?? new Uri(url).AbsolutePath);
            if (ext.Contains(".p")) ext = "";
            var dir = Path.Combine(CacheDir, Hash(url));
            Directory.CreateDirectory(dir);
            var file = Path.Combine(dir, Safe(name ?? ("file" + ext)));
            if (File.Exists(file)) return file;
            var tmp = file + ".part";
            await using (var os = File.Create(tmp))
            {
                var list = parts is { Count: > 0 } ? parts : new List<string> { url };
                for (int i = 0; i < list.Count; i++)
                {
                    using var r = await Api.Http.GetAsync(Net.Px(list[i]) ?? list[i], HttpCompletionOption.ResponseHeadersRead);
                    r.EnsureSuccessStatusCode();
                    await using var ins = await r.Content.ReadAsStreamAsync();
                    await ins.CopyToAsync(os);
                    progress?.Report((i + 1.0) / list.Count);
                }
            }
            File.Move(tmp, file, true);
            return file;
        }
        catch { return null; }
        finally { lock (inflight) inflight.Remove(url + "|" + name); }
    }

    public static string Safe(string n)
    {
        foreach (var c in Path.GetInvalidFileNameChars()) n = n.Replace(c, '_');
        return n.Length == 0 ? "file" : n;
    }

    /// <summary>Скопировать в «Загрузки» с неповторяющимся именем</summary>
    public static string SaveToDownloads(string src, string name)
    {
        var dir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), "Downloads");
        Directory.CreateDirectory(dir);
        var baseName = Path.GetFileNameWithoutExtension(Safe(name)); var ext = Path.GetExtension(name);
        var dst = Path.Combine(dir, baseName + ext);
        for (int i = 1; File.Exists(dst); i++) dst = Path.Combine(dir, $"{baseName} ({i}){ext}");
        File.Copy(src, dst);
        return dst;
    }
}
