package ru.volshebnymir.lumo.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch
import ru.volshebnymir.lumo.core.AppModel
import ru.volshebnymir.lumo.core.E2E

/** Окна сквозного шифрования: восстановление ключей на новом устройстве и пароль резервной копии */
@Composable
fun E2EDialogs() {
    val p = P
    val scope = rememberCoroutineScope()
    if (E2E.status == E2E.Status.NeedRestore) {
        var pw by remember { mutableStateOf("") }
        var confirmReset by remember { mutableStateOf(false) }
        if (confirmReset) AlertDialog(onDismissRequest = { confirmReset = false }, title = { Text("Сбросить ключи?") },
            text = { Text("Будут созданы новые ключи. Старые личные переписки останутся зашифрованными и прочитать их будет нельзя. Новые сообщения будут работать как обычно.") },
            confirmButton = { TextButton({ confirmReset = false; scope.launch { if (E2E.reset()) { AppModel.say("Ключи созданы заново"); AppModel.loadChats() } else AppModel.say("Не удалось, попробуйте ещё раз") } }) { Text("Сбросить", color = p.danger) } },
            dismissButton = { TextButton({ confirmReset = false }) { Text("Отмена") } })
        else AlertDialog(onDismissRequest = {}, title = { Text("Расшифровка переписок") },
            text = {
                Column(Modifier.verticalScroll(rememberScrollState())) {
                    Text("Личные чаты защищены сквозным шифрованием. Введите пароль резервной копии, который вы задали на другом устройстве.", color = p.muted, fontSize = 13.sp)
                    Spacer(Modifier.height(12.dp))
                    LumoField(pw, { pw = it }, "Пароль резервной копии", password = true)
                }
            },
            confirmButton = { TextButton({
                if (pw.isEmpty() || E2E.busy) return@TextButton
                scope.launch { if (E2E.restore(pw)) { AppModel.say("Переписки расшифрованы"); AppModel.loadChats() } else AppModel.say("Неверный пароль") }
            }) { Text(if (E2E.busy) "Проверяю…" else "Расшифровать") } },
            dismissButton = { TextButton({ confirmReset = true }) { Text("Забыл пароль", color = p.danger) } })
    } else if (E2E.promptBackup && E2E.status == E2E.Status.Ready) {
        var pw by remember { mutableStateOf("") }
        var pw2 by remember { mutableStateOf("") }
        AlertDialog(onDismissRequest = { E2E.skipBackup() }, title = { Text(if (E2E.backedUp) "Новый пароль копии" else "Сохраните ключи") },
            text = {
                Column(Modifier.verticalScroll(rememberScrollState())) {
                    Text("Ключи шифрования хранятся только на вашем устройстве. Придумайте пароль резервной копии — с ним переписки можно будет прочитать на новом телефоне. " +
                        "Если пароль забыть, старые сообщения восстановить будет нельзя: мы их прочитать не можем.", color = p.muted, fontSize = 13.sp)
                    Spacer(Modifier.height(12.dp))
                    LumoField(pw, { pw = it }, "Пароль (не меньше 8 символов)", password = true)
                    Spacer(Modifier.height(8.dp))
                    LumoField(pw2, { pw2 = it }, "Повторите пароль", password = true)
                }
            },
            confirmButton = { TextButton({
                if (E2E.busy) return@TextButton
                if (pw.length < 8) { AppModel.say("Пароль слишком короткий"); return@TextButton }
                if (pw != pw2) { AppModel.say("Пароли не совпадают"); return@TextButton }
                scope.launch { if (E2E.createBackup(pw)) AppModel.say("Резервная копия сохранена") else AppModel.say("Не удалось сохранить, попробуйте ещё раз") }
            }) { Text(if (E2E.busy) "Сохраняю…" else "Сохранить") } },
            dismissButton = { TextButton({ E2E.skipBackup() }) { Text("Позже") } })
    }
}

/** Код безопасности чата: совпадает у обоих собеседников, если между вами нет подмены ключей */
@Composable
fun SafetyDialog(peerId: String, onClose: () -> Unit) {
    val p = P
    val code = E2E.safety(peerId)
    AlertDialog(onDismissRequest = onClose, title = { Text("Код безопасности") },
        text = {
            Column {
                Text(code ?: "У собеседника пока нет ключа шифрования — сообщения ему идут без сквозного шифрования.", color = p.text, fontSize = 18.sp)
                if (code != null) {
                    Spacer(Modifier.height(10.dp))
                    Text("Сравните этот код с кодом у собеседника при встрече или по звонку. Если коды совпадают — переписка защищена от подмены." +
                        (if (E2E.changed.contains(peerId)) "\n\n⚠️ Ключ собеседника изменился с прошлого раза (например, он сменил телефон или сбросил ключи)." else ""), color = p.muted, fontSize = 13.sp)
                }
            }
        },
        confirmButton = { TextButton(onClose) { Text("Закрыть") } })
}
