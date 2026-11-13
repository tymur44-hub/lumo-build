using System.Text.Json.Nodes;

namespace Lumo.Core;

/// <summary>Папки чатов и архив — хранятся на этом компьютере (как на телефонах — на устройстве)</summary>
public static class Folders
{
    public record Folder(string Id, string Name, List<string> Chats, string Kind = "custom");

    public static List<Folder> List { get; private set; } = new();
    public static HashSet<string> Archive { get; private set; } = new();
    public static event Action? Changed;
    static string Key => "folders_" + (Store.MyId ?? "");
    static string AKey => "archive_" + (Store.MyId ?? "");

    public static void Load()
    {
        List = new();
        try
        {
            if (JsonNode.Parse(Prefs.Get(Key) ?? "[]") is JsonArray a)
                foreach (var x in a.Objects())
                    List.Add(new Folder(x.Str("id") ?? Guid.NewGuid().ToString("N")[..8], x.Str("name") ?? "Папка",
                        x.Arr("chats")?.Select(c => c is JsonValue v && v.TryGetValue<string>(out var s) ? s : "").Where(s => s.Length > 0).ToList() ?? new(), x.Str("kind") ?? "custom"));
        }
        catch { }
        Archive = new();
        try { if (JsonNode.Parse(Prefs.Get(AKey) ?? "[]") is JsonArray b) foreach (var x in b) if (x is JsonValue v && v.TryGetValue<string>(out var s)) Archive.Add(s); } catch { }
        Changed?.Invoke();
    }

    static void Save()
    {
        var a = new JsonArray();
        foreach (var f in List) a.Add(J.O(("id", f.Id), ("name", f.Name), ("kind", f.Kind), ("chats", f.Chats)));
        Prefs.Set(Key, a.ToJsonString());
        Prefs.Set(AKey, J.ToNode(Archive.ToList())!.ToJsonString());
        Changed?.Invoke();
    }

    public static void Upsert(Folder f)
    {
        var i = List.FindIndex(x => x.Id == f.Id);
        if (i >= 0) List[i] = f; else List.Add(f);
        Save();
    }

    public static void Remove(string id) { List.RemoveAll(x => x.Id == id); Save(); }

    public static void Toggle(string folderId, string chatId)
    {
        var f = List.FirstOrDefault(x => x.Id == folderId); if (f == null) return;
        if (!f.Chats.Remove(chatId)) f.Chats.Add(chatId);
        Save();
    }

    public static void SetArchived(string chatId, bool on) { if (on) Archive.Add(chatId); else Archive.Remove(chatId); Save(); }

    /// <summary>Чаты вкладки: "all" — все без архива, "archive" — архив, "unread", "personal", "groups", "channels" или id своей папки</summary>
    public static IEnumerable<ChatItem> Filter(IEnumerable<ChatItem> chats, string tab) => tab switch
    {
        "all" => chats.Where(c => !Archive.Contains(c.Id)),
        "archive" => chats.Where(c => Archive.Contains(c.Id)),
        "unread" => chats.Where(c => c.Unread > 0 && !Archive.Contains(c.Id)),
        "personal" => chats.Where(c => c.IsPrivate && !Archive.Contains(c.Id)),
        "groups" => chats.Where(c => c.Type == "group" && !Archive.Contains(c.Id)),
        "channels" => chats.Where(c => c.IsChannel && !Archive.Contains(c.Id)),
        _ => List.FirstOrDefault(f => f.Id == tab) is { } f ? chats.Where(c => f.Chats.Contains(c.Id)) : chats,
    };
}
