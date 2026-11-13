using System.Text.Json.Nodes;

namespace Lumo.Core;

/// <summary>Пример данных для демо-режима (без сети): несколько чатов и сообщений разных видов</summary>
public static class DemoData
{
    static ChatItem Chat(string id, string type, string name, int color, string? peer, string last, int unread, int minutesAgo, bool pinned = false, bool verified = false, int members = 0) =>
        new(id, type, type == "private" ? null : name, null, color, peer, type == "private" ? name : null, peer == null ? null : name.ToLower().Replace(' ', '_'), null, color,
            DateTimeOffset.UtcNow.AddMinutes(-20), type == "channel" ? "owner" : "member", false, pinned, null, members, 1, "text", last, peer ?? "u2", "Олег",
            DateTimeOffset.UtcNow.AddMinutes(-minutesAgo), false, unread, DateTimeOffset.UtcNow.AddMinutes(-minutesAgo - 1), null, null, null, false, false, verified);

    static int id = 100;
    static Message M(string chat, string? from, string kind, string? body, int minutesAgo, JsonObject? meta = null, int? reply = null, string? media = null, string? fwd = null) =>
        new(++id, chat, from, kind, body, media, meta ?? new JsonObject(), reply, fwd, null, false, DateTimeOffset.UtcNow.AddMinutes(-minutesAgo));

    public static void Load()
    {
        Store.Me = new Profile("me", "lumo_user", "Тимур", "Пишу код и снимаю видео", null, 2, DateTimeOffset.UtcNow, true, false, true, "", null, true, false, null, new JsonObject());
        Store.Profiles["me"] = Store.Me;
        Store.Profiles["u1"] = new Profile("u1", "anna", "Анна Смирнова", "Фотограф. Москва", null, 5, DateTimeOffset.UtcNow.AddMinutes(-3), true, false, true, "Смирнова", "2001-07-01", false, false, null, new JsonObject());
        Store.Profiles["u2"] = new Profile("u2", "oleg", "Олег", "", null, 0, DateTimeOffset.UtcNow.AddHours(-2), true, false, false, "", null, false, false, null, new JsonObject());
        Store.Online.Add("u1");
        Store.Chats = new List<ChatItem>
        {
            Chat("c1", "private", "Анна Смирнова", 5, "u1", "Тогда до вечера!", 2, 2, true, true),
            Chat("c2", "group", "Волшебный мир", 1, null, "Репетиция в 18:00", 5, 15, members: 24),
            Chat("c3", "channel", "Новости Lumo", 3, null, "Вышло приложение для Windows", 0, 60, members: 1280),
            Chat("c4", "private", "Избранное", 2, "me", "Список покупок", 0, 300),
        };
        var a = new List<Message>
        {
            M("c1", "u1", "text", "Привет! Ты сегодня будешь на репетиции?", 40),
            M("c1", "me", "text", "Привет! Да, буду к шести", 38),
            M("c1", "u1", "voice", null, 35, new JsonObject { ["dur"] = 14 }, media: "https://example.invalid/v.m4a"),
            M("c1", "me", "file", null, 30, new JsonObject { ["name"] = "Сценарий концерта.pdf", ["size"] = 482133 }, media: "https://example.invalid/f.pdf"),
            M("c1", "u1", "text", "Супер, посмотрю сценарий **сегодня** и напишу. Вот ссылка на зал: https://lumomess.ru", 12),
        };
        a.Add(M("c1", "me", "text", "Тогда до вечера!", 2, reply: a[^1].Id));
        Store.Messages["c1"] = a;
        Store.Reactions[a[1].Id] = new() { new Reaction(a[1].Id, "u1", "❤️") };
        Store.Reactions[a[4].Id] = new() { new Reaction(a[4].Id, "me", "\U0001F44D"), new Reaction(a[4].Id, "u1", "\U0001F44D") };
        Store.Messages["c2"] = new List<Message>
        {
            M("c2", "u2", "text", "Всем привет! Напоминаю про репетицию", 60),
            M("c2", "u1", "text", "Буду", 50),
            M("c2", null, "system", "Олег закрепил сообщение", 49),
            M("c2", "me", "text", "Я тоже, возьму колонку", 40),
            M("c2", "u2", "text", "Репетиция в 18:00", 15, fwd: "Волшебный мир"),
        };
        Store.Messages["c3"] = new List<Message> { M("c3", "me", "text", "Вышло приложение для Windows", 60) };
        Store.Messages["c4"] = new List<Message> { M("c4", "me", "text", "Список покупок: хлеб, молоко, кофе", 300) };
        foreach (var k in Store.Messages.Keys) Store.HasMore[k] = false;
    }
}
