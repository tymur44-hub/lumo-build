using System.Text.Json.Nodes;

namespace Lumo.Core;

/// <summary>Состояние приложения: профиль, чаты, сообщения, реакции, «в сети», «печатает». Меняется только на главном потоке.</summary>
public static class Store
{
    /// <summary>Демо-режим без сети (LUMO_DEMO=1) — для проверки интерфейса при сборке</summary>
    public static readonly bool Demo = Environment.GetEnvironmentVariable("LUMO_DEMO") == "1";
    public static string? MyId => Demo ? "me" : Api.UserId;
    public static Profile? Me { get; internal set; }
    public static List<ChatItem> Chats { get; internal set; } = new();
    public static readonly Dictionary<string, string> ChatPreview = new();
    public static readonly Dictionary<string, List<Message>> Messages = new();
    public static readonly Dictionary<int, List<Reaction>> Reactions = new();
    public static readonly Dictionary<int, Message> ReplyCache = new();
    public static readonly Dictionary<string, Profile> Profiles = new();
    public static readonly HashSet<string> Online = new();
    public static readonly Dictionary<string, Dictionary<string, string>> Typing = new();
    static readonly Dictionary<string, string> typingAct = new();
    public static readonly Dictionary<string, bool> HasMore = new();
    static readonly HashSet<int> hidden = new();
    static readonly Dictionary<string, DateTimeOffset> cleared = new();
    static readonly HashSet<int> notified = new();
    static readonly Dictionary<string, Realtime.Channel> typingChannels = new();
    static Realtime.Channel? onlineChannel;

    public static string? OpenChatId;
    public static bool WindowActive = true;
    public static bool Started { get; private set; }

    public static event Action? ChatsChanged;
    public static event Action<string>? MessagesChanged;
    public static event Action<int>? ReactionsChanged;
    public static event Action<string>? TypingChanged;
    public static event Action? OnlineChanged;
    public static event Action? MeChanged;
    public static event Action<string>? Toast;
    public static event Action<bool>? NetState;
    /// <summary>Показать уведомление Windows: чат, заголовок, текст</summary>
    public static event Action<string, string, string>? Notify;

    public static void Say(string s) => Toast?.Invoke(s);

    // ---------- запуск ----------

    static CancellationTokenSource? loops;

    public static async Task Start()
    {
        if (Started || MyId == null) return;
        Started = true;
        if (Demo) { DemoData.Load(); ChatsChanged?.Invoke(); MeChanged?.Invoke(); return; }
        var id = MyId!;
        _ = Net.Pick();
        await LoadMe();
        await E2E.Setup(id);
        await LoadChats();
        _ = LoadStories();
        Realtime.Connect();
        var db = Realtime.Get("lm-db", new JsonArray(
            J.O(("event", "INSERT"), ("schema", "public"), ("table", "lm_messages")),
            J.O(("event", "UPDATE"), ("schema", "public"), ("table", "lm_messages")),
            J.O(("event", "*"), ("schema", "public"), ("table", "lm_members")),
            J.O(("event", "*"), ("schema", "public"), ("table", "lm_reactions")),
            J.O(("event", "*"), ("schema", "public"), ("table", "lm_reactions_extra"))));
        db.OnChange = OnDB;
        Realtime.OnReconnect = async () =>
        {
            await LoadChats();
            if (OpenChatId != null) await LoadMessages(OpenChatId);
        };
        Realtime.OnState = on => NetState?.Invoke(on);
        var sch = Realtime.Get("lm-stories");
        sch.OnBroadcast = async (_, _) => { await Task.Delay(350); await LoadStories(); };
        var oc = Realtime.Get("lm-online", presenceKey: id);
        oc.OnPresenceState = st => { Online.Clear(); foreach (var k in st) Online.Add(k.Key); OnlineChanged?.Invoke(); };
        oc.OnPresenceDiff = (joins, leaves) =>
        {
            foreach (var k in joins) Online.Add(k.Key);
            foreach (var k in leaves)
                if (!joins.ContainsKey(k.Key))
                {
                    Online.Remove(k.Key);
                    var i = Chats.FindIndex(c => c.PeerId == k.Key);
                    if (i >= 0) Chats[i] = Chats[i] with { PeerLastSeen = DateTimeOffset.UtcNow };
                    if (Profiles.TryGetValue(k.Key, out var p)) Profiles[k.Key] = p with { LastSeen = DateTimeOffset.UtcNow };
                }
            OnlineChanged?.Invoke();
        };
        Realtime.Track(oc, J.O(("at", DateTimeOffset.UtcNow.ToUnixTimeMilliseconds())));
        onlineChannel = oc;
        Presence(true);
        _ = TouchSession();
        var l = new CancellationTokenSource(); loops = l;
        _ = Loop(l.Token);
    }

    static async Task Loop(CancellationToken t)
    {
        while (!t.IsCancellationRequested)
        {
            try { await Task.Delay(45000, t); } catch { return; }
            if (WindowActive) { Presence(true); _ = TouchSession(); }
        }
    }

    public static void Stop()
    {
        loops?.Cancel();
        Realtime.Disconnect();
        Started = false; Me = null;
        Chats = new(); Stories = new(); ChatPreview.Clear(); Messages.Clear(); Reactions.Clear(); ReplyCache.Clear(); Profiles.Clear(); Online.Clear(); Typing.Clear();
        HasMore.Clear(); hidden.Clear(); cleared.Clear(); notified.Clear(); typingChannels.Clear(); OpenChatId = null; contacts = null;
        E2E.Forget();
    }

    public static async void Presence(bool on) { try { await Api.Rpc("lm_presence", J.O(("p_active", on))); } catch { } }

    static async Task TouchSession()
    {
        var dev = Prefs.Get("device_id");
        if (dev == null) { dev = Guid.NewGuid().ToString(); Prefs.Set("device_id", dev); }
        try
        {
            await Api.Rpc("lm_session_touch", J.O(("p_device", dev), ("p_name", "Windows · " + Environment.MachineName), ("p_platform", "windows"),
                ("p_version", "1.0.0"), ("p_fresh", false)));
        }
        catch { }
    }

    // ---------- профили ----------

    public static async Task LoadMe()
    {
        var id = MyId; if (id == null) return;
        var p = (await FetchProfiles(new[] { id })).FirstOrDefault();
        if (p != null) { Me = p; Profiles[id] = p; MeChanged?.Invoke(); }
    }

    static async Task<List<Profile>> FetchProfiles(IEnumerable<string> ids)
    {
        try { return (await Api.Rpc("lm_profiles_get", J.O(("p_ids", ids.Distinct().ToList())))).Objects().Select(Profile.From).ToList(); }
        catch { return new(); }
    }

    static readonly HashSet<string> fresh = new();

    public static async Task LoadProfiles(IEnumerable<string> ids)
    {
        var need = ids.Where(i => i.Length > 0 && (!Profiles.ContainsKey(i) || !fresh.Contains(i))).Distinct().ToList();
        if (need.Count == 0) return;
        foreach (var i in need) fresh.Add(i);
        foreach (var p in await FetchProfiles(need)) Profiles[p.Id] = p;
    }

    public static async Task<Profile?> GetProfile(string id)
    {
        if (!fresh.Contains(id)) await LoadProfiles(new[] { id });
        return Profiles.GetValueOrDefault(id);
    }

    public static string DisplayName(string? uid)
    {
        if (uid == null) return "";
        if (uid == MyId) return Me?.Name ?? "Вы";
        if (Profiles.TryGetValue(uid, out var p)) return p.Name.Length > 0 ? p.Name : p.Username;
        var c = Chats.FirstOrDefault(x => x.PeerId == uid);
        return c?.PeerName ?? "Пользователь";
    }

    public static async Task<string?> SaveProfile(string first, string last, string bio, string username)
    {
        var id = MyId; if (id == null) return "Войдите заново";
        try
        {
            var u = username.Trim().TrimStart('@');
            if (u.Length > 0 && u != Me?.Username) await Api.Rpc("lm_set_username", J.O(("p_username", u)));
            var full = string.Join(" ", new[] { first.Trim(), last.Trim() }.Where(s => s.Length > 0));
            await Api.Update("lm_profiles", Api.Q(("id", id)), J.O(("name", full), ("last_name", last.Trim()), ("bio", bio.Trim())));
            await LoadMe();
            return null;
        }
        catch (Exception e) { return e.Message; }
    }

    public static async Task<string?> SetAvatar(byte[] data, string ext, string type)
    {
        var id = MyId; if (id == null) return "Войдите заново";
        try
        {
            var url = await Api.Upload(data, ext, type);
            await Api.Update("lm_profiles", Api.Q(("id", id)), J.O(("avatar_url", url)));
            await LoadMe();
            return null;
        }
        catch (Exception e) { return e.Message; }
    }

    // ---------- истории ----------

    public static List<StoryGroup> Stories { get; internal set; } = new();
    public static event Action? StoriesChanged;

    public static async Task LoadStories()
    {
        if (Demo || MyId == null) return;
        try
        {
            var rows = (await Api.Rpc("lm_stories_feed")).Objects().Select(StoryItem.From).ToList();
            Stories = rows.GroupBy(r => r.UserId).Select(g =>
            {
                var items = g.OrderBy(x => x.CreatedAt).ToList(); var f = items[0];
                return new StoryGroup(g.Key, f.Name, f.AvatarUrl, f.Color, items, g.Key != MyId && items.Any(x => !x.Seen), items[^1].CreatedAt);
            }).OrderByDescending(x => x.UserId == MyId).ThenByDescending(x => x.Unseen).ThenByDescending(x => x.Last).ToList();
            StoriesChanged?.Invoke();
        }
        catch { }
    }

    public static async Task ViewStory(StoryItem s)
    {
        if (s.Seen || s.UserId == MyId) return;
        try { await Api.Rpc("lm_story_view", J.O(("p_id", s.Id))); } catch { }
    }

    // ---------- чаты ----------

    public static ChatItem? Chat(string id) => Chats.FirstOrDefault(c => c.Id == id);
    public static int UnreadTotal => Chats.Where(c => !c.Muted).Sum(c => c.Unread);

    public static async Task LoadChats()
    {
        if (MyId == null) return;
        try
        {
            var rows = (await Api.Rpc("lm_chats_v2")).Objects();
            var list = rows.Select(ChatItem.From).ToList();
            await E2E.Prefetch(list.Where(c => c.IsPrivate && c.PeerId != null).Select(c => c.PeerId!));
            foreach (var c in list.Where(c => c.IsPrivate && E2E.IsEnc(c.LastBody)))
            {
                await E2E.Prepare(c.Id, c.PeerId);
                ChatPreview[c.Id] = E2E.Decrypt(c.Id, c.LastBody) ?? "";
            }
            Chats = list.OrderByDescending(c => c.Pinned).ThenByDescending(c => c.LastAt ?? DateTimeOffset.MinValue).ToList();
            ChatsChanged?.Invoke();
            SyncTyping();
        }
        catch (ApiError e) when (e.Status == 401) { Api.Forget(); }
        catch { }
    }

    static CancellationTokenSource? reloadCts;
    static async void ScheduleReload()
    {
        reloadCts?.Cancel(); var c = new CancellationTokenSource(); reloadCts = c;
        try { await Task.Delay(400, c.Token); } catch { return; }
        await LoadChats();
    }

    public static async Task<string?> OpenDm(string userId)
    {
        try
        {
            var cid = (await Api.Rpc("lm_open_dm", J.O(("p_other", userId))))?.GetValue<string>();
            await LoadChats();
            return cid;
        }
        catch (Exception e) { Say(e.Message); return null; }
    }

    static List<string>? contacts;
    /// <summary>Мои контакты (id пользователей)</summary>
    public static async Task<List<string>> ContactIds(bool fresh = false)
    {
        if (contacts != null && !fresh) return contacts;
        try { contacts = (await Api.Select("lm_contacts", Api.Q(("select", "contact_id")))).Select(r => r.Str("contact_id")).Where(x => x != null).Select(x => x!).ToList(); }
        catch { contacts ??= new(); }
        return contacts;
    }

    public static async Task<List<SearchResult>> Search(string q)
    {
        try { return (await Api.Rpc("lm_search", J.O(("q", q)))).Objects().Select(SearchResult.From).ToList(); }
        catch { return new(); }
    }

    /// <summary>Создать группу или канал; id нового чата</summary>
    public static async Task<string?> CreateChat(string type, string title, string description, List<string> members, string? username, byte[]? avatar)
    {
        try
        {
            var p = J.O(("p_type", type), ("p_title", title), ("p_members", members), ("p_description", description), ("p_protected", false), ("p_requests", false));
            if (!string.IsNullOrWhiteSpace(username)) p["p_username"] = username.Trim().TrimStart('@').ToLowerInvariant();
            var cid = (await Api.Rpc("lm_create_chat_v3", p))?.GetValue<string>();
            if (cid != null && avatar != null)
                try { var url = await Api.Upload(avatar, "jpg", "image/jpeg"); await Api.Update("lm_chats", Api.Q(("id", cid)), J.O(("avatar_url", url))); } catch { }
            await LoadChats();
            return cid;
        }
        catch (Exception e) { Say(e.Message); return null; }
    }

    public static async Task Join(string chatId)
    {
        try { await Api.Rpc("lm_join", J.O(("p_chat", chatId))); await LoadChats(); } catch (Exception e) { Say(e.Message); }
    }

    public static async Task SetMuted(string chatId, bool on)
    {
        try { await Api.Update("lm_members", Api.Q(("chat_id", chatId), ("user_id", MyId ?? "")), J.O(("muted", on))); await LoadChats(); } catch (Exception e) { Say(e.Message); }
    }

    public static async Task SetPinned(string chatId, bool on)
    {
        try { await Api.Update("lm_members", Api.Q(("chat_id", chatId), ("user_id", MyId ?? "")), J.O(("pinned", on))); await LoadChats(); } catch (Exception e) { Say(e.Message); }
    }

    // ---------- сообщения ----------

    static Message Dec(Message m) => !E2E.IsEnc(m.Body) ? m : m with { Body = E2E.Decrypt(m.ChatId, m.Body), Enc = true };

    public static async Task Prep(string chatId)
    {
        if (Chat(chatId) == null) await LoadChats();
        var c = Chat(chatId); if (c == null || !c.IsPrivate) return;
        await E2E.Prepare(chatId, c.PeerId);
        await E2E.Refresh(chatId, c.PeerId);
    }

    public static List<Message> Msgs(string chatId) => Messages.GetValueOrDefault(chatId) ?? new();

    static List<Message> Sorted(IEnumerable<Message> l) => l.Where(m => m.Id > 0).OrderBy(m => m.Id).Concat(l.Where(m => m.Id <= 0)).ToList();

    public static async Task LoadMessages(string chatId, bool older = false)
    {
        var me = MyId; if (me == null) return;
        if (Demo) { MessagesChanged?.Invoke(chatId); return; }
        await Prep(chatId);
        if (!cleared.ContainsKey(chatId))
        {
            try
            {
                var r = (await Api.Select("lm_members", Api.Q(("select", "cleared_at"), ("chat_id", "eq." + chatId), ("user_id", "eq." + me)))).FirstOrDefault();
                cleared[chatId] = r.Date("cleared_at") ?? DateTimeOffset.MinValue;
            }
            catch { }
        }
        var q = Api.Q(("select", "*"), ("chat_id", "eq." + chatId), ("deleted", "eq.false"), ("order", "id.desc"), ("limit", "50"));
        if (cleared.TryGetValue(chatId, out var cl) && cl > DateTimeOffset.MinValue) q["created_at"] = "gt." + Dates.Iso(cl);
        var current = Msgs(chatId);
        if (older) { var first = current.FirstOrDefault(m => m.Id > 0); if (first != null) q["id"] = "lt." + first.Id; }
        List<JsonObject> rows;
        try { rows = await Api.Select("lm_messages", q); } catch { return; }
        try
        {
            foreach (var r in await Api.Select("lm_hidden", Api.Q(("select", "message_id"), ("chat_id", "eq." + chatId))))
                if (r.Int("message_id") is int h) hidden.Add(h);
        }
        catch { }
        var arr = rows.Select(r => Dec(Message.From(r))).Reverse().Where(m => !hidden.Contains(m.Id)).ToList();
        Messages[chatId] = older ? arr.Where(m => current.All(c => c.Id != m.Id)).Concat(current).ToList() : arr.Concat(current.Where(m => m.Pending)).ToList();
        HasMore[chatId] = rows.Count == 50;
        await LoadProfiles(arr.Where(m => m.SenderId != null).Select(m => m.SenderId!));
        var ids = arr.Select(m => m.Id).ToList();
        if (ids.Count > 0)
        {
            var inIds = "in.(" + string.Join(",", ids) + ")";
            try
            {
                var rr = await Api.Select("lm_reactions", Api.Q(("select", "message_id,user_id,emoji"), ("message_id", inIds)));
                var rx = await Api.Select("lm_reactions_extra", Api.Q(("select", "message_id,user_id,emoji"), ("message_id", inIds)));
                foreach (var i in ids) Reactions[i] = new();
                foreach (var g in rr.Select(x => Reaction.From(x)).Concat(rx.Select(x => Reaction.From(x, true))).GroupBy(x => x.MessageId)) Reactions[g.Key] = g.ToList();
            }
            catch { }
        }
        var need = arr.Where(m => m.ReplyTo != null).Select(m => m.ReplyTo!.Value).ToList();
        if (Chat(chatId)?.PinnedMessageId is int pin) need.Add(pin);
        var missing = need.Where(i => Find(i, chatId) == null).Distinct().ToList();
        if (missing.Count > 0)
        {
            try
            {
                foreach (var r in await Api.Select("lm_messages", Api.Q(("select", "*"), ("id", "in.(" + string.Join(",", missing) + ")"))))
                { var m = Dec(Message.From(r)); ReplyCache[m.Id] = m; }
            }
            catch { }
        }
        MessagesChanged?.Invoke(chatId);
    }

    /// <summary>Поиск по чату (личные чаты зашифрованы — ищем по последним сообщениям на устройстве)</summary>
    public static async Task<List<Message>> SearchMessages(string chatId, string q)
    {
        var needle = q.ToLowerInvariant();
        await Prep(chatId);
        try
        {
            var rows = await Api.Select("lm_messages", Api.Q(("select", "*"), ("chat_id", "eq." + chatId), ("deleted", "eq.false"), ("order", "id.desc"), ("limit", "800")));
            return rows.Select(r => Dec(Message.From(r))).Where(m => m.Kind != "system" && m.Kind != "call" && !hidden.Contains(m.Id) && (m.Body ?? "").ToLowerInvariant().Contains(needle)).Take(100).ToList();
        }
        catch { return new(); }
    }

    public static Message? Find(int id, string chatId) => Msgs(chatId).FirstOrDefault(m => m.Id == id) ?? ReplyCache.GetValueOrDefault(id);

    public static void MarkRead(string chatId)
    {
        var me = MyId; if (me == null || !WindowActive) return;
        var last = Msgs(chatId).LastOrDefault(m => m.Id > 0); if (last == null) return;
        var i = Chats.FindIndex(c => c.Id == chatId);
        if (i >= 0)
        {
            var c = Chats[i];
            if (c.Unread == 0 && c.LastReadAt != null && c.LastReadAt >= last.CreatedAt) return;
            Chats[i] = c with { Unread = 0, LastReadAt = last.CreatedAt.AddMilliseconds(1) };
            ChatsChanged?.Invoke();
        }
        _ = Task.Run(async () =>
        {
            try { await Api.Update("lm_members", Api.Q(("chat_id", chatId), ("user_id", me)), J.O(("last_read_at", Dates.Iso(last.CreatedAt.AddMilliseconds(1))))); } catch { }
        });
    }

    static void SetList(string chatId, List<Message> l) { Messages[chatId] = l; MessagesChanged?.Invoke(chatId); }

    public static async Task<bool> Send(string chatId, string kind, string? body = null, string? media = null, JsonObject? meta = null,
        int? replyTo = null, string? forwardedFrom = null, int? pendingId = null)
    {
        var me = MyId; if (me == null) return false;
        meta ??= new JsonObject();
        int pid;
        if (pendingId != null) pid = pendingId.Value;
        else { var p = Message.NewPending(chatId, me, kind, body, meta.Clone(), replyTo); pid = p.Id; SetList(chatId, Msgs(chatId).Append(p).ToList()); }
        async Task<JsonObject?> InsertRow()
        {
            var wire = body;
            if (kind == "text" && body != null) { await Prep(chatId); var enc = E2E.Encrypt(chatId, body); if (enc != null) wire = enc; }
            var row = J.O(("chat_id", chatId), ("sender_id", me), ("kind", kind), ("meta", meta));
            if (wire != null) row["body"] = wire;
            if (media != null) row["media_url"] = media;
            if (replyTo != null) row["reply_to"] = replyTo.Value;
            if (forwardedFrom != null) row["forwarded_from"] = forwardedFrom;
            return await Api.Insert("lm_messages", row);
        }
        try
        {
            JsonObject? saved;
            try { saved = await InsertRow(); }
            catch (ApiError e) when (e.Message.Contains("зашифровано")) { E2E.DropCaches(); saved = await InsertRow(); }
            if (saved == null) throw new ApiError("Не отправлено", 500);
            var m = Dec(Message.From(saved));
            var list = Msgs(chatId).Where(x => x.Id != pid).ToList();
            if (list.All(x => x.Id != m.Id)) list.Add(m);
            SetList(chatId, Sorted(list));
            ScheduleReload();
            return true;
        }
        catch (Exception e)
        {
            SetList(chatId, Msgs(chatId).Where(x => x.Id != pid).ToList());
            Say("Не отправлено: " + e.Message);
            return false;
        }
    }

    /// <summary>Отправить файл с диска: фото, видео, голосовое или документ. Большие файлы — частями по 45 МБ.</summary>
    public static async Task SendFile(string chatId, string path, string? caption = null, int? replyTo = null, bool asFile = false)
    {
        var me = MyId; if (me == null) return;
        var fi = new FileInfo(path);
        var ext = fi.Extension.TrimStart('.').ToLowerInvariant();
        var limit = (Me?.Premium == true ? 200L : 100L) * 1024 * 1024;
        if (fi.Length > limit) { Say("Файл больше " + (Me?.Premium == true ? "200 МБ" : "100 МБ")); return; }
        string kind = asFile ? "file" : ext switch
        {
            "jpg" or "jpeg" or "png" or "webp" or "gif" or "bmp" or "heic" => "image",
            "mp4" or "mov" or "webm" or "m4v" or "mkv" => "video",
            _ => "file",
        };
        var type = Mime(ext);
        var meta = J.O(("name", fi.Name), ("size", fi.Length));
        if (kind == "image")
        {
            try { var (w, h) = await Media.ImageSize(path); if (w > 0) { meta["w"] = w; meta["h"] = h; } } catch { }
        }
        var temp = Message.NewPending(chatId, me, kind, caption, meta.Clone(), replyTo, path);
        SetList(chatId, Msgs(chatId).Append(temp).ToList());
        try
        {
            const int chunk = 45 * 1024 * 1024;
            string url;
            if (fi.Length > chunk)
            {
                var parts = new JsonArray();
                using var fs = File.OpenRead(path);
                var buf = new byte[chunk]; int i = 0;
                while (true)
                {
                    int n = 0;
                    while (n < chunk) { var r = await fs.ReadAsync(buf.AsMemory(n, chunk - n)); if (r <= 0) break; n += r; }
                    if (n == 0) break;
                    parts.Add(await Api.Upload(n == chunk ? buf : buf[..n], ext + ".p" + i, "application/octet-stream"));
                    i++;
                    if (n < chunk) break;
                }
                meta["parts"] = parts;
                url = parts[0]!.GetValue<string>();
            }
            else url = await Api.Upload(await File.ReadAllBytesAsync(path), ext.Length == 0 ? "bin" : ext, type);
            await Send(chatId, kind, caption, url, meta, replyTo, pendingId: temp.Id);
        }
        catch (Exception e)
        {
            SetList(chatId, Msgs(chatId).Where(x => x.Id != temp.Id).ToList());
            Say("Ошибка загрузки: " + e.Message);
        }
    }

    /// <summary>Отправить готовые байты (вставка из буфера, запись голоса)</summary>
    public static async Task SendBytes(string chatId, string kind, byte[] data, string ext, JsonObject meta, string? caption = null, int? replyTo = null)
    {
        var me = MyId; if (me == null) return;
        var temp = Message.NewPending(chatId, me, kind, caption, meta.Clone(), replyTo);
        SetList(chatId, Msgs(chatId).Append(temp).ToList());
        try
        {
            var url = await Api.Upload(data, ext, Mime(ext));
            await Send(chatId, kind, caption, url, meta, replyTo, pendingId: temp.Id);
        }
        catch (Exception e)
        {
            SetList(chatId, Msgs(chatId).Where(x => x.Id != temp.Id).ToList());
            Say("Ошибка загрузки: " + e.Message);
        }
    }

    public static string Mime(string ext) => ext switch
    {
        "jpg" or "jpeg" => "image/jpeg", "png" => "image/png", "webp" => "image/webp", "gif" => "image/gif", "bmp" => "image/bmp",
        "mp4" or "m4v" => "video/mp4", "mov" => "video/quicktime", "webm" => "video/webm", "mkv" => "video/x-matroska",
        "m4a" => "audio/mp4", "mp3" => "audio/mpeg", "ogg" => "audio/ogg", "wav" => "audio/wav",
        "pdf" => "application/pdf", "txt" => "text/plain", "zip" => "application/zip",
        _ => "application/octet-stream",
    };

    public static async Task Forward(Message m, string to, bool hideAuthor = false)
    {
        if (hideAuthor) { await Send(to, m.Kind, m.Body, m.MediaUrl, m.Meta.Clone()); return; }
        var src = Chat(m.ChatId);
        var from = !string.IsNullOrEmpty(m.ForwardedFrom) ? m.ForwardedFrom : src?.IsChannel == true ? src.DisplayName : DisplayName(m.SenderId);
        await Send(to, m.Kind, m.Body, m.MediaUrl, m.Meta.Clone(), forwardedFrom: from);
    }

    public static async Task Delete(List<Message> list, bool everyone)
    {
        if (list.Count == 0) return;
        var chatId = list[0].ChatId;
        var ids = list.Where(m => m.Id > 0).Select(m => m.Id).ToHashSet();
        var albums = list.Select(m => m.Meta.Str("album")).Where(a => a != null).ToHashSet();
        if (albums.Count > 0) foreach (var m in Msgs(chatId)) if (m.Id > 0 && albums.Contains(m.Meta.Str("album"))) ids.Add(m.Id);
        if (ids.Count == 0) return;
        SetList(chatId, Msgs(chatId).Where(m => !ids.Contains(m.Id)).ToList());
        try
        {
            foreach (var id in ids)
            {
                if (everyone) await Api.Update("lm_messages", Api.Q(("id", id.ToString())), J.O(("deleted", true)));
                else
                {
                    hidden.Add(id);
                    await Api.Raw("POST", "/rest/v1/lm_hidden", body: J.O(("message_id", id), ("chat_id", chatId)),
                        headers: Api.Q(("Prefer", "resolution=ignore-duplicates,return=minimal")));
                }
            }
            if (everyone && Chat(chatId)?.PinnedMessageId is int p && ids.Contains(p))
                try { await Api.Update("lm_chats", Api.Q(("id", chatId)), new JsonObject { ["pinned_message_id"] = null }); } catch { }
            ScheduleReload();
        }
        catch (Exception e) { Say(e.Message); await LoadMessages(chatId); }
    }

    public static async Task Edit(Message m, string text)
    {
        await Prep(m.ChatId);
        var wire = m.Kind == "text" ? E2E.Encrypt(m.ChatId, text) ?? text : text;
        try
        {
            await Api.Update("lm_messages", Api.Q(("id", m.Id.ToString())), J.O(("body", wire), ("edited_at", Dates.Iso(DateTimeOffset.UtcNow))));
            SetList(m.ChatId, Msgs(m.ChatId).Select(x => x.Id == m.Id ? x with { Body = text, EditedAt = DateTimeOffset.UtcNow } : x).ToList());
        }
        catch (Exception e) { Say(e.Message); }
    }

    public static async Task Pin(Message? m, string chatId)
    {
        try
        {
            await Api.Update("lm_chats", Api.Q(("id", chatId)), new JsonObject { ["pinned_message_id"] = m == null ? null : JsonValue.Create(m.Id) });
            if (m != null) ReplyCache[m.Id] = m;
            await LoadChats();
            Say(m == null ? "Сообщение откреплено" : "Сообщение закреплено");
        }
        catch (Exception e) { Say(e.Message); }
    }

    public static async Task React(Message m, string emoji)
    {
        var me = MyId; if (me == null || m.Id <= 0) return;
        var list = Reactions.GetValueOrDefault(m.Id) ?? new();
        var mine = list.Where(r => r.UserId == me).ToList();
        var others = list.Where(r => r.UserId != me).ToList();
        var had = mine.FirstOrDefault(r => r.Emoji == emoji);
        void SetR(List<Reaction> l) { Reactions[m.Id] = l; ReactionsChanged?.Invoke(m.Id); }
        if (had != null)
        {
            SetR(others.Concat(mine.Where(r => r.Emoji != emoji)).ToList());
            try { await Api.Delete(had.Extra ? "lm_reactions_extra" : "lm_reactions", Api.Q(("message_id", m.Id.ToString()), ("user_id", me), ("emoji", emoji))); } catch { }
            return;
        }
        var row = J.O(("message_id", m.Id), ("user_id", me), ("chat_id", m.ChatId), ("emoji", emoji));
        var merge = Api.Q(("Prefer", "resolution=merge-duplicates,return=minimal"));
        try
        {
            if (Me?.Premium != true)
            {
                SetR(others.Append(new Reaction(m.Id, me, emoji)).ToList());
                await Api.Raw("POST", "/rest/v1/lm_reactions", Api.Q(("on_conflict", "message_id,user_id")), row, merge);
                return;
            }
            if (mine.Count >= 3) { Say("Можно поставить не больше 3 реакций"); return; }
            if (mine.All(r => r.Extra))
            {
                SetR(others.Concat(mine).Append(new Reaction(m.Id, me, emoji)).ToList());
                await Api.Raw("POST", "/rest/v1/lm_reactions", Api.Q(("on_conflict", "message_id,user_id")), row, merge);
            }
            else
            {
                SetR(others.Concat(mine).Append(new Reaction(m.Id, me, emoji, true)).ToList());
                await Api.Raw("POST", "/rest/v1/lm_reactions_extra", body: row, headers: Api.Q(("Prefer", "return=minimal")));
            }
        }
        catch (Exception e) { SetR(list); Say(e.Message); }
    }

    // ---------- «печатает…» ----------

    static void SyncTyping()
    {
        if (MyId == null) return;
        var want = Chats.Take(40).Select(c => c.Id).ToHashSet();
        if (OpenChatId != null) want.Add(OpenChatId);
        foreach (var k in typingChannels.Keys.Where(k => !want.Contains(k)).ToList()) { Realtime.Leave("lm-typing-" + k); typingChannels.Remove(k); }
        foreach (var k in want.Where(k => !typingChannels.ContainsKey(k))) typingChannels[k] = MakeTyping(k);
    }

    static readonly Dictionary<string, CancellationTokenSource> typingClear = new();

    static Realtime.Channel MakeTyping(string id)
    {
        var ch = Realtime.Get("lm-typing-" + id);
        ch.OnBroadcast = async (ev, p) =>
        {
            var uid = p.Str("uid");
            if (ev != "typing" || uid == null || uid == MyId) return;
            var key = id + uid;
            typingAct[key] = p.Str("act") ?? "typing";
            if (typingClear.TryGetValue(key, out var old)) old.Cancel();
            if (!Typing.TryGetValue(id, out var t)) Typing[id] = t = new();
            if (p.Str("act") == "stop") { t.Remove(uid); TypingChanged?.Invoke(id); return; }
            t[uid] = p.Str("name") ?? "";
            TypingChanged?.Invoke(id);
            var c = new CancellationTokenSource(); typingClear[key] = c;
            try { await Task.Delay(4000, c.Token); } catch { return; }
            t.Remove(uid); TypingChanged?.Invoke(id);
        };
        return ch;
    }

    static DateTime lastTypingSent;
    static string lastAct = "";

    public static void UserTyping(string chatId, string act = "typing")
    {
        var m = Me; if (m == null) return;
        if (!typingChannels.TryGetValue(chatId, out var ch)) typingChannels[chatId] = ch = MakeTyping(chatId);
        if (act == lastAct && act != "stop" && (DateTime.UtcNow - lastTypingSent).TotalMilliseconds < 2500) return;
        lastTypingSent = DateTime.UtcNow; lastAct = act;
        Realtime.Broadcast(ch, "typing", J.O(("uid", m.Id), ("name", m.Name), ("act", act)));
    }

    public static string? TypingText(string chatId)
    {
        if (!Typing.TryGetValue(chatId, out var t) || t.Count == 0) return null;
        string Verb(string uid) => typingAct.GetValueOrDefault(chatId + uid) switch
        {
            "voice" => "записывает голосовое…", "video" => "записывает видеосообщение…", _ => "печатает…",
        };
        if (Chat(chatId)?.IsPrivate == true) return Verb(t.Keys.First());
        if (t.Count == 1) return DisplayName(t.Keys.First()) + " " + Verb(t.Keys.First());
        return string.Join(", ", t.Keys.Take(2).Select(DisplayName)) + " печатают…";
    }

    public static string Status(ChatItem c)
    {
        var t = TypingText(c.Id); if (t != null) return t;
        if (c.IsPrivate)
        {
            if (c.PeerBot) return "бот";
            if (c.PeerId == null || c.PeerId == MyId) return "заметки для себя";
            if (Online.Contains(c.PeerId)) return "в сети";
            var p = Profiles.GetValueOrDefault(c.PeerId);
            return Fmt.LastSeen(p?.LastSeen ?? c.PeerLastSeen, p?.ShowSeen ?? true);
        }
        var n = c.MembersCount;
        return c.IsChannel ? $"{n} {Fmt.Plural(n, "подписчик", "подписчика", "подписчиков")}" : $"{n} {Fmt.Plural(n, "участник", "участника", "участников")}";
    }

    // ---------- живые обновления ----------

    static async void OnDB(JsonObject d)
    {
        var table = d.Str("table"); var type = d.Str("type"); var rec = d.Obj("record");
        switch (table)
        {
            case "lm_messages":
            {
                var m0 = Message.From(rec);
                if (m0.Id <= 0 || m0.ChatId.Length == 0) return;
                if (E2E.IsEnc(m0.Body)) await Prep(m0.ChatId);
                var m = Dec(m0);
                if (type == "INSERT") Incoming(m);
                else if (type == "UPDATE")
                {
                    if (Messages.TryGetValue(m.ChatId, out var l))
                        SetList(m.ChatId, m.Deleted ? l.Where(x => x.Id != m.Id).ToList() : l.Select(x => x.Id == m.Id ? m : x).ToList());
                    if (ReplyCache.ContainsKey(m.Id)) ReplyCache[m.Id] = m;
                    ScheduleReload();
                }
                break;
            }
            case "lm_members": ScheduleReload(); break;
            case "lm_reactions":
            case "lm_reactions_extra":
            {
                var isExtra = table == "lm_reactions_extra";
                if (type == "DELETE")
                {
                    var old = d.Obj("old_record"); var mid = old.Int("message_id"); var uid = old.Str("user_id"); var e = old.Str("emoji");
                    if (mid != null && uid != null && uid != MyId && Reactions.TryGetValue(mid.Value, out var rl))
                    {
                        Reactions[mid.Value] = rl.Where(r => !(r.UserId == uid && r.Extra == isExtra && (e == null || r.Emoji == e))).ToList();
                        ReactionsChanged?.Invoke(mid.Value);
                    }
                }
                else
                {
                    var r = Reaction.From(rec, isExtra);
                    if (r.MessageId <= 0 || r.UserId == MyId) return;
                    var l = Reactions.GetValueOrDefault(r.MessageId) ?? new();
                    if (!isExtra) l = l.Where(x => !(x.UserId == r.UserId && !x.Extra)).ToList();
                    Reactions[r.MessageId] = l.Where(x => !(x.UserId == r.UserId && x.Emoji == r.Emoji)).Append(r).ToList();
                    ReactionsChanged?.Invoke(r.MessageId);
                }
                break;
            }
        }
    }

    static void Incoming(Message m)
    {
        if (Messages.TryGetValue(m.ChatId, out var list) && list.All(x => x.Id != m.Id))
        {
            var l = list.ToList();
            if (m.SenderId == MyId) { var i = l.FindIndex(x => x.Pending && x.Kind == m.Kind && x.Body == m.Body); if (i >= 0) l.RemoveAt(i); }
            l.Add(m);
            SetList(m.ChatId, Sorted(l));
        }
        if (m.SenderId != null && Typing.TryGetValue(m.ChatId, out var t) && t.Remove(m.SenderId)) TypingChanged?.Invoke(m.ChatId);
        ScheduleReload();
        if (m.SenderId == MyId || m.Kind == "system") return;
        _ = LoadProfiles(m.SenderId == null ? Array.Empty<string>() : new[] { m.SenderId });
        var visible = WindowActive && OpenChatId == m.ChatId;
        if (visible) { _ = Task.Delay(300).ContinueWith(_ => Realtime.Post(() => MarkRead(m.ChatId))); return; }
        if (m.Kind == "call" && (m.MetaStatus == null || m.MetaStatus is "ended" or "rejected")) return;
        if (!notified.Add(m.Id)) return;
        _ = NotifyAsync(m);
    }

    static async Task NotifyAsync(Message m)
    {
        if (Chat(m.ChatId) == null) await LoadChats();
        var ch = Chat(m.ChatId);
        if (ch?.Muted == true) return;
        if (m.SenderId != null) await LoadProfiles(new[] { m.SenderId });
        var sender = DisplayName(m.SenderId);
        var body = m.Preview;
        if (m.Kind == "call") body = m.IsVideoCall ? "Пропущенный видеозвонок" : "Пропущенный звонок";
        string title;
        if (ch == null || ch.IsPrivate) title = sender;
        else if (ch.IsChannel) title = ch.DisplayName;
        else { body = sender + ": " + body; title = ch.DisplayName; }
        if (m.Meta.Bool("urgent")) title = "Срочно · " + title;
        Notify?.Invoke(m.ChatId, title, body);
    }
}
