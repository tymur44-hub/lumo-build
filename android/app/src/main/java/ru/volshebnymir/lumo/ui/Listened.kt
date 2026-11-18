package ru.volshebnymir.lumo.ui

import androidx.compose.runtime.mutableStateMapOf
import kotlinx.coroutines.launch
import ru.volshebnymir.lumo.core.*

/**
 * Точка «не прослушано» у голосовых и кружков.
 * Входящее: горит, пока вы его не включили. Исходящее: горит, пока собеседник не прослушал.
 * Кто прослушал — хранится на сервере в meta.lb и приходит всем через обновление сообщения.
 */
object Listened {
    private val local = mutableStateMapOf<Int, Boolean>()
    private val sent = HashSet<Int>()

    fun unheard(m: Message, mine: Boolean): Boolean {
        if ((m.kind != "voice" && m.kind != "video_note") || m.id <= 0) return false
        val arr = m.meta.optJSONArray("lb")
        val lb = (0 until (arr?.length() ?: 0)).map { arr!!.optString(it) }
        val me = AppModel.myId ?: return false
        if (mine) {
            val c = AppModel.chats.firstOrNull { it.id == m.chatId }
            if (c != null && c.isPrivate && c.peerId == me) return false
            return lb.isEmpty()
        }
        if (local[m.id] == true) return false
        return me !in lb
    }

    /** Вызывается, когда входящее голосовое или кружок начали воспроизводить */
    fun mark(m: Message, mine: Boolean) {
        if (mine || m.id <= 0 || !unheard(m, false)) return
        local[m.id] = true
        if (!sent.add(m.id)) return
        AppModel.scope.launch { runCatching { Api.rpc("lm_voice_listen", jsonOf("p_msg" to m.id)) } }
    }
}
