package ru.volshebnymir.lumo.core

import org.json.JSONArray
import java.util.Date

/** Пример данных для проверки экранов (только по специальной команде, без сети) */
object Demo {
    var openMenu = false
    private fun chat(id: String, type: String, title: String?, peer: String?, peerName: String?, color: Int, kind: String, body: String,
                     sender: String?, minAgo: Long, unread: Int = 0, members: Int = 2, muted: Boolean = false, pinned: Boolean = false) =
        ChatItem(id, type, title, null, color, peer, peerName, peerName?.lowercase(), null, color, Date(System.currentTimeMillis() - 3_600_000),
            "owner", muted, pinned, Date(), members, 10, kind, body, sender, peerName ?: "Аня", Date(System.currentTimeMillis() - minAgo * 60_000),
            false, unread, Date(System.currentTimeMillis() - 30 * 60_000), null, null, null)

    fun load() {
        val me = "me"
        AppModel.demoId = me
        val now = System.currentTimeMillis()
        fun pr(id: String, name: String, c: Int) = Profile(id, name.lowercase(), name, "Люблю Lumo ✨", null, c, Date(now - 600_000), true, false, "all", false)
        AppModel.me = pr(me, "Емеля", 1)
        listOf(pr(me, "Емеля", 1), pr("u1", "Лилия", 0), pr("u2", "Максим", 2), pr("u3", "Аня", 5)).forEach { AppModel.profiles[it.id] = it }
        AppModel.online["u1"] = true
        AppModel.contacts.addAll(listOf("u1", "u2", "u3"))
        AppModel.chats.addAll(listOf(
            chat("c1", "private", null, "u1", "Лилия", 0, "text", "Привет! Как дела? 😊", "u1", 2, unread = 2, pinned = true),
            chat("c2", "group", "Друзья", null, null, 3, "voice", "", "u2", 15, unread = 5, members = 6),
            chat("c3", "private", null, "u2", "Максим", 2, "image", "", me, 60),
            chat("c4", "channel", "Новости Lumo", null, null, 6, "text", "Вышла бета-версия для Android!", "u3", 300, members = 128, muted = true),
            chat("c5", "private", null, me, "Емеля", 1, "text", "Заметка", me, 2000),
        ))
        AppModel.chatsLoaded = true
        fun m(id: Int, from: String, kind: String, body: String?, minAgo: Long, meta: org.json.JSONObject = org.json.JSONObject(), reply: Int? = null) =
            Message(id, "c1", from, kind, body, null, meta, reply, null, null, false, Date(now - minAgo * 60_000))
        AppModel.messages["c1"] = listOf(
            m(1, "u1", "text", "Привет! 👋", 1500),
            m(2, me, "text", "Привет! Смотри, **Lumo** теперь есть на Android", 1490),
            m(3, "u1", "text", "Ого, круто! https://volshebny-mir.ru", 1480),
            m(4, me, "voice", null, 30, jsonOf("dur" to 7, "wave" to JSONArray((0 until 40).map { (it * 7) % 31 }))),
            m(5, "u1", "text", "Привет! Как дела? 😊", 2, reply = 2),
            m(6, me, "text", "Отлично! 🔥", 1),
        )
        AppModel.reactions[3] = listOf(Reaction(3, me, "❤️"))
        AppModel.unreadTotal = 7
        fun st(id: Int, u: String, n: String, c: Int, seen: Boolean) = StoryItem(id, u, n, n.lowercase(), null, c, "image", "", "", Date(now - 3_600_000), seen, 3)
        AppModel.stories.addAll(listOf(
            StoryGroup("u1", "Лилия", null, 0, listOf(st(1, "u1", "Лилия", 0, false)), true, Date()),
            StoryGroup("u2", "Максим", null, 2, listOf(st(2, "u2", "Максим", 2, false)), true, Date()),
            StoryGroup("u3", "Аня", null, 5, listOf(st(3, "u3", "Аня", 5, true)), false, Date()),
        ))
        AppModel.loggedIn = true
    }
}
