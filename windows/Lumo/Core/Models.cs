using System.Globalization;
using System.Text.Json.Nodes;

namespace Lumo.Core;

public static class Fmt
{
    static readonly CultureInfo ru = new("ru-RU");
    static DateTime L(DateTimeOffset d) => d.LocalDateTime;

    public static string Clock(DateTimeOffset? d) => d == null ? "" : L(d.Value).ToString("HH:mm", ru);

    public static string ListTime(DateTimeOffset? d)
    {
        if (d == null) return "";
        var t = L(d.Value); var now = DateTime.Now;
        if (t.Date == now.Date) return t.ToString("HH:mm", ru);
        if (t.Date == now.Date.AddDays(-1)) return "вчера";
        if ((now - t).TotalDays < 7) return t.ToString("ddd", ru);
        return t.Year == now.Year ? t.ToString("d MMM", ru) : t.ToString("dd.MM.yy", ru);
    }

    public static string Day(DateTimeOffset d)
    {
        var t = L(d); var now = DateTime.Now;
        if (t.Date == now.Date) return "Сегодня";
        if (t.Date == now.Date.AddDays(-1)) return "Вчера";
        return t.ToString(t.Year == now.Year ? "d MMMM" : "d MMMM yyyy", ru);
    }

    public static string Duration(double s) { var t = Math.Max(0, (int)Math.Round(s)); return $"{t / 60}:{t % 60:00}"; }

    public static string Size(long b)
    {
        double v = b; string[] u = { "Б", "КБ", "МБ", "ГБ" }; int i = 0;
        while (v >= 1024 && i < 3) { v /= 1024; i++; }
        return i == 0 ? $"{(int)v} {u[i]}" : v.ToString("0.0", CultureInfo.InvariantCulture) + " " + u[i];
    }

    public static string LastSeen(DateTimeOffset? d, bool show = true)
    {
        if (!show || d == null) return "был(а) недавно";
        var m = (DateTimeOffset.Now - d.Value).TotalMinutes;
        if (m < 1.5) return "был(а) только что";
        if (m < 60) return $"был(а) {Math.Round(m)} мин. назад";
        if (L(d.Value).Date == DateTime.Now.Date) return "был(а) сегодня в " + Clock(d);
        return "был(а) " + Day(d.Value).ToLower(ru) + " в " + Clock(d);
    }

    public static string Initials(string name)
    {
        var p = name.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        if (p.Length == 0) return "?";
        return p.Length > 1 ? (char.ToString(p[0][0]) + p[1][0]).ToUpper(ru) : new string(p[0].Take(2).ToArray()).ToUpper(ru);
    }

    public static string Plural(int n, string one, string few, string many)
    {
        var a = Math.Abs(n) % 100; var b = a % 10;
        if (a is >= 11 and <= 14) return many;
        return b == 1 ? one : b is >= 2 and <= 4 ? few : many;
    }
}

public record Profile(
    string Id, string Username, string Name, string Bio, string? AvatarUrl, int Color, DateTimeOffset? LastSeen, bool ShowSeen,
    bool Banned, bool Verified, string LastName, string? Birthday, bool Premium, bool IsBot, string? EmojiStatus, JsonObject Privacy)
{
    public static Profile From(JsonObject j) => new(
        j.Str("id") ?? "", j.Str("username") ?? "", j.Str("name") ?? "", j.Str("bio") ?? "", j.Str("avatar_url"), j.Int("color") ?? 0,
        j.Date("last_seen"), !j.Has("show_seen") || j.Bool("show_seen"), j.Bool("banned"), j.Bool("verified"), j.Str("last_name") ?? "",
        j.Str("birthday"), j.Bool("premium"), j.Bool("is_bot"), j.Str("emoji_status"), j.Get("privacy") as JsonObject ?? new JsonObject());

    public string FirstName => LastName.Length > 0 && Name.EndsWith(" " + LastName) ? Name[..^(LastName.Length + 1)] : Name;
}

public record ChatItem(
    string Id, string Type, string? Title, string? AvatarUrl, int Color,
    string? PeerId, string? PeerName, string? PeerUsername, string? PeerAvatar, int PeerColor, DateTimeOffset? PeerLastSeen,
    string? Role, bool Muted, bool Pinned, DateTimeOffset? LastReadAt, int MembersCount, int? LastId, string? LastKind, string? LastBody,
    string? LastSender, string? LastSenderName, DateTimeOffset? LastAt, bool LastDeleted, int Unread, DateTimeOffset? OthersReadAt,
    int? PinnedMessageId, string? Description, string? Username, bool PeerBot, bool PeerPremium, bool PeerVerified)
{
    public bool IsPrivate => Type == "private";
    public bool IsChannel => Type == "channel";
    public bool IsSaved => IsPrivate && PeerId == null;
    public string DisplayName => IsPrivate ? (PeerId == null ? "Избранное" : PeerName ?? PeerUsername ?? "Пользователь") : Title ?? (IsChannel ? "Канал" : "Группа");
    public string? DisplayAvatar => IsPrivate ? PeerAvatar : AvatarUrl;
    public int DisplayColor => IsPrivate ? PeerColor : Color;
    public bool CanPost => !IsChannel || Role is "owner" or "admin";
    public bool IsAdmin => Role is "owner" or "admin";

    public string Preview(string? myId, string? decrypted = null)
    {
        if (LastId == null) return IsChannel ? "Канал создан" : "Нет сообщений";
        if (LastDeleted) return "Сообщение удалено";
        var text = Message.PreviewText(LastKind ?? "text", decrypted ?? LastBody);
        if (Type == "group" && LastSenderName != null && LastKind != "system") return (LastSender == myId ? "Вы" : LastSenderName) + ": " + text;
        if (LastSender == myId && LastKind != "system" && LastKind != "call") return "Вы: " + text;
        return text;
    }

    public static ChatItem From(JsonObject j) => new(
        j.Str("chat_id") ?? "", j.Str("type") ?? "private", j.Str("title"), j.Str("avatar_url"), j.Int("color") ?? 0,
        j.Str("peer_id"), j.Str("peer_name"), j.Str("peer_username"), j.Str("peer_avatar"), j.Int("peer_color") ?? 0, j.Date("peer_last_seen"),
        j.Str("role"), j.Bool("muted"), j.Bool("pinned"), j.Date("last_read_at"), j.Int("members_count") ?? 0, j.Int("last_id"), j.Str("last_kind"),
        j.Str("last_body"), j.Str("last_sender"), j.Str("last_sender_name"), j.Date("last_at"), j.Bool("last_deleted"), j.Int("unread") ?? 0,
        j.Date("others_read_at"), j.Int("pinned_message_id"), j.Str("description"), j.Str("username"),
        j.Bool("peer_bot"), j.Bool("peer_premium"), j.Bool("peer_verified"));
}

public record Message(
    int Id, string ChatId, string? SenderId, string Kind, string? Body, string? MediaUrl, JsonObject Meta, int? ReplyTo,
    string? ForwardedFrom, DateTimeOffset? EditedAt, bool Deleted, DateTimeOffset CreatedAt, bool Pending = false, bool Enc = false,
    string? LocalPath = null)
{
    public string? MetaStatus => Meta.Str("status");
    public double Duration => Meta.Dbl("dur") ?? Meta.Dbl("duration") ?? 0;
    public List<int> Wave => Meta.Arr("wave")?.Select(x => x is JsonValue v && v.TryGetValue<int>(out var i) ? i : (int)(x?.GetValue<double>() ?? 0)).ToList() ?? new();
    public double? Width => Meta.Dbl("w");
    public double? Height => Meta.Dbl("h");
    public string FileName => Meta.Str("name") ?? "Файл";
    public List<string> Parts => Meta.Arr("parts")?.Select(x => x is JsonValue v && v.TryGetValue<string>(out var s) ? s : "").Where(s => s.Length > 0).ToList() ?? new();
    public long? FileSize => Meta.Long("size");
    public bool IsVideoCall => Meta.Bool("video");
    public string Preview => Deleted ? "Сообщение удалено" : Kind == "file" ? "Файл: " + FileName : PreviewText(Kind, Body);

    public static Message From(JsonObject j) => new(
        j.Int("id") ?? 0, j.Str("chat_id") ?? "", j.Str("sender_id"), j.Str("kind") ?? "text", j.Str("body"), j.Str("media_url"),
        j.Get("meta") as JsonObject is { } m ? (JsonObject)m.DeepClone() : new JsonObject(), j.Int("reply_to"), j.Str("forwarded_from"), j.Date("edited_at"), j.Bool("deleted"),
        j.Date("created_at") ?? DateTimeOffset.UtcNow);

    static int pendingSeq;
    public static Message NewPending(string chat, string sender, string kind, string? body, JsonObject? meta = null, int? replyTo = null, string? local = null) =>
        new(-(++pendingSeq) - Random.Shared.Next(1000, 100000), chat, sender, kind, body, null, meta ?? new JsonObject(), replyTo, null, null, false,
            DateTimeOffset.UtcNow, true, false, local);

    public static string PreviewText(string kind, string? body)
    {
        var b = (body ?? "").Replace("**", "").Replace("__", "").Replace("`", "").Replace("~~", "");
        if (E2E.IsEnc(body)) b = "Зашифрованное сообщение";
        return kind switch
        {
            "voice" => "Голосовое сообщение",
            "video_note" => "Видеосообщение",
            "image" => b.Length == 0 ? "Фото" : b,
            "video" => b.Length == 0 ? "Видео" : b,
            "file" => "Файл",
            "sticker" => "Стикер",
            "call" => "Звонок",
            "game" => "Игра",
            "poll" => "Опрос",
            "capsule" => "Капсула времени",
            "capsule_open" => "Капсула времени открылась",
            _ => b,
        };
    }
}

public record Reaction(int MessageId, string UserId, string Emoji, bool Extra = false)
{
    public static Reaction From(JsonObject j, bool extra = false) => new(j.Int("message_id") ?? 0, j.Str("user_id") ?? "", j.Str("emoji") ?? "", extra);
}

public record SearchResult(string Id, string Kind, string Name, string? Username, string? AvatarUrl, int Color, string? Extra)
{
    public static SearchResult From(JsonObject j) => new(j.Str("id") ?? "", j.Str("kind") ?? "user", j.Str("name") ?? "", j.Str("username"),
        j.Str("avatar_url"), j.Int("color") ?? 0, j.Str("extra"));
}

public record StoryItem(int Id, string UserId, string Name, string? AvatarUrl, int Color, string Kind, string MediaUrl, string Caption,
    DateTimeOffset CreatedAt, bool Seen, int Views, string? Thumb)
{
    public static StoryItem From(JsonObject j) => new(j.Int("id") ?? 0, j.Str("user_id") ?? "", j.Str("name") ?? "", j.Str("avatar_url"), j.Int("color") ?? 0,
        j.Str("kind") ?? "image", j.Str("media_url") ?? "", j.Str("caption") ?? "", j.Date("created_at") ?? DateTimeOffset.UtcNow, j.Bool("seen"), j.Int("views") ?? 0,
        j.Obj("meta").Str("thumb"));
}

public record StoryGroup(string UserId, string Name, string? AvatarUrl, int Color, List<StoryItem> Items, bool Unseen, DateTimeOffset Last);
