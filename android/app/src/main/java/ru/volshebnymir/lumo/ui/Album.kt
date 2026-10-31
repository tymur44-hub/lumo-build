package ru.volshebnymir.lumo.ui

import android.Manifest
import android.content.ContentUris
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import ru.volshebnymir.lumo.core.AppModel
import ru.volshebnymir.lumo.core.ChatItem
import ru.volshebnymir.lumo.core.Fmt
import ru.volshebnymir.lumo.core.Message
import ru.volshebnymir.lumo.core.jsonOf

// ---------------- альбом: несколько фото/видео в одном пузыре ----------------

private fun albumRows(n: Int): List<Int> = when (n) {
    2 -> listOf(2); 3 -> listOf(1, 2); 4 -> listOf(2, 2); 5 -> listOf(2, 3); 6 -> listOf(3, 3)
    7 -> listOf(1, 3, 3); 8 -> listOf(2, 3, 3); 9 -> listOf(3, 3, 3); else -> listOf(2, 2, 3, 3)
}

@Composable
fun AlbumGrid(items: List<Message>, onOpen: (Message) -> Unit) {
    val shown = items.take(10)
    val rows = albumRows(shown.size)
    var idx = 0
    Column(Modifier.width(260.dp).clip(RoundedCornerShape(14.dp)), verticalArrangement = Arrangement.spacedBy(2.dp)) {
        rows.forEach { n ->
            val h = when (n) { 1 -> 190.dp; 2 -> 128.dp; else -> 86.dp }
            Row(Modifier.fillMaxWidth().height(h), horizontalArrangement = Arrangement.spacedBy(2.dp)) {
                repeat(n) {
                    val m = shown.getOrNull(idx++)
                    if (m != null) Box(Modifier.weight(1f).fillMaxHeight().background(Color.Black.copy(alpha = 0.15f)).clickable { onOpen(m) }, contentAlignment = Alignment.Center) {
                        AsyncImage(m.localPath ?: m.mediaUrl, null, Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
                        if (m.kind == "video") Box(Modifier.size(38.dp).clip(CircleShape).background(Color.Black.copy(alpha = 0.5f)), contentAlignment = Alignment.Center) {
                            Icon(Icons.Filled.PlayArrow, null, tint = Color.White, modifier = Modifier.size(26.dp))
                        }
                    }
                }
            }
        }
    }
}

// ---------------- шторка «скрепки»: галерея с выбором нескольких фото ----------------

private class GalItem(val uri: Uri, val video: Boolean, val dur: Long)

private fun loadGallery(ctx: Context): List<GalItem> {
    val out = mutableListOf<GalItem>()
    val files = MediaStore.Files.getContentUri("external")
    val type = MediaStore.Files.FileColumns.MEDIA_TYPE
    val sel = "$type=? OR $type=?"
    val args = arrayOf(MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE.toString(), MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO.toString())
    val sort = MediaStore.Files.FileColumns.DATE_ADDED + " DESC"
    runCatching {
        ctx.contentResolver.query(files, arrayOf(MediaStore.Files.FileColumns._ID, type, "duration"), sel, args, sort)?.use { c ->
            while (c.moveToNext() && out.size < 400) {
                val id = c.getLong(0); val video = c.getInt(1) == MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO
                val base = if (video) MediaStore.Video.Media.EXTERNAL_CONTENT_URI else MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                out.add(GalItem(ContentUris.withAppendedId(base, id), video, if (video) c.getLong(2) else 0))
            }
        }
    }
    if (out.isEmpty()) runCatching {
        ctx.contentResolver.query(files, arrayOf(MediaStore.Files.FileColumns._ID, type), sel, args, sort)?.use { c ->
            while (c.moveToNext() && out.size < 400) {
                val id = c.getLong(0); val video = c.getInt(1) == MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO
                val base = if (video) MediaStore.Video.Media.EXTERNAL_CONTENT_URI else MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                out.add(GalItem(ContentUris.withAppendedId(base, id), video, 0))
            }
        }
    }
    return out
}

private fun galPerms(): Array<String> =
    if (Build.VERSION.SDK_INT >= 33) arrayOf(Manifest.permission.READ_MEDIA_IMAGES, Manifest.permission.READ_MEDIA_VIDEO)
    else arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE)

/** Читает выбранные фото/видео и готовит части альбома (в порядке выбора) */
suspend fun buildAlbumParts(ctx: Context, uris: List<Uri>): List<AppModel.AlbumPart> {
    val out = mutableListOf<AppModel.AlbumPart>()
    for (u in uris) {
        val type = ctx.contentResolver.getType(u) ?: ""
        val data = withContext(Dispatchers.IO) { MediaUtil.read(ctx, u) }
        if (data == null) { AppModel.say("Не удалось открыть файл"); continue }
        if (data.size > 50 * 1024 * 1024) { AppModel.say("Файл больше 50 МБ пропущен"); continue }
        if (type.startsWith("video")) {
            val ext = android.webkit.MimeTypeMap.getSingleton().getExtensionFromMimeType(type) ?: "mp4"
            out.add(AppModel.AlbumPart("video", data, ext, type, jsonOf("name" to "video.$ext", "size" to data.size)))
        } else {
            val j = withContext(Dispatchers.Default) { MediaUtil.jpeg(data) } ?: continue
            out.add(AppModel.AlbumPart("image", j.first, "jpg", "image/jpeg", jsonOf("w" to j.second, "h" to j.third)))
        }
    }
    return out
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AttachSheet(
    canLumens: Boolean,
    onDismiss: () -> Unit,
    onSend: (List<Uri>, String?) -> Unit,
    onSystemPicker: () -> Unit,
    onFile: () -> Unit,
    onAudio: () -> Unit,
    onCamera: () -> Unit,
    onNote: () -> Unit,
    onLumens: () -> Unit,
    onPost: (String, String?, String?, org.json.JSONObject) -> Unit = { _, _, _, _ -> },
) {
    var tabSel by remember { mutableStateOf("Галерея") }
    val p = P
    val ctx = LocalContext.current
    var granted by remember { mutableStateOf(galPerms().all { ContextCompatCheck(ctx, it) }) }
    var denied by remember { mutableStateOf(false) }
    var gallery by remember { mutableStateOf<List<GalItem>>(emptyList()) }
    val picked = remember { mutableStateListOf<Uri>() }
    var caption by remember { mutableStateOf("") }
    val perm = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { r ->
        // на Android 14+ достаточно частичного доступа к выбранным фото
        granted = r.values.any { it } || galPerms().any { ContextCompatCheck(ctx, it) }
        denied = !granted
    }
    LaunchedEffect(Unit) { if (!granted) perm.launch(galPerms()) }
    LaunchedEffect(granted) { if (granted) gallery = withContext(Dispatchers.IO) { loadGallery(ctx) } }
    val sheet = rememberModalBottomSheetState(skipPartiallyExpanded = false)

    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = sheet, containerColor = p.bg, shape = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp)) {
        Box(Modifier.fillMaxWidth().fillMaxHeight(0.92f)) {
            Column(Modifier.fillMaxSize()) {
                Box(Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 4.dp), contentAlignment = Alignment.Center) {
                    Text(if (picked.isEmpty()) (if (tabSel == "Галерея") "Недавние" else if (tabSel == "Контакт") "Контакты" else tabSel) else "Выбрано: ${picked.size}", color = p.text, fontWeight = FontWeight.Bold, fontSize = 18.sp)
                    Box(Modifier.align(Alignment.CenterStart)) { RoundIcon(Icons.Filled.Close, 44.dp, bg = p.panel) { onDismiss() } }
                }
                if (tabSel == "Файл") FilesPanel(false, onPickFile = { onDismiss(); onFile() }, onGallery = { tabSel = "Галерея" },
                    onResend = { m -> onPost("file", null, m.mediaUrl, m.meta); onDismiss() })
                else if (tabSel == "Звук") FilesPanel(true, onPickFile = { onDismiss(); onAudio() }, onGallery = { tabSel = "Галерея" },
                    onResend = { m -> onPost("file", null, m.mediaUrl, m.meta); onDismiss() })
                else if (tabSel == "Геопозиция") LocationPanel { la, lo -> onPost("text", SpecialMsg.locationBody(null, la, lo), null, org.json.JSONObject()); onDismiss() }
                else if (tabSel == "Контакт") ContactsPanel { x -> onPost("text", SpecialMsg.contactBody(AppModel.aliases[x.id] ?: x.name, x.id), null, org.json.JSONObject()); onDismiss() }
                else if (!granted) {
                    Column(Modifier.fillMaxSize().padding(30.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
                        Icon(Icons.Filled.PhotoLibrary, null, tint = p.muted, modifier = Modifier.size(46.dp))
                        Spacer(Modifier.height(10.dp))
                        Text(if (denied) "Нет доступа к фото" else "Нужен доступ к фото", color = p.text, fontWeight = FontWeight.Bold, fontSize = 17.sp)
                        Spacer(Modifier.height(6.dp))
                        Text("Разрешите доступ, чтобы выбирать фото и видео, или откройте системную галерею", color = p.muted, fontSize = 14.sp)
                        TextButton({ perm.launch(galPerms()) }) { Text("Разрешить") }
                        TextButton({ onDismiss(); onSystemPicker() }) { Text("Открыть системную галерею") }
                    }
                } else LazyVerticalGrid(GridCells.Fixed(3), Modifier.fillMaxSize(), horizontalArrangement = Arrangement.spacedBy(2.dp), verticalArrangement = Arrangement.spacedBy(2.dp),
                    contentPadding = PaddingValues(bottom = 130.dp)) {
                    items(gallery, key = { it.uri.toString() }) { g ->
                        val idx = picked.indexOf(g.uri)
                        Box(Modifier.aspectRatio(1f).clickable {
                            if (idx >= 0) picked.remove(g.uri) else if (picked.size >= 10) AppModel.say("Можно выбрать до 10 файлов") else picked.add(g.uri)
                        }) {
                            AsyncImage(g.uri, null, Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
                            if (idx >= 0) Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.2f)))
                            if (g.video) Text(Fmt.duration(g.dur / 1000.0), color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.SemiBold,
                                modifier = Modifier.align(Alignment.BottomStart).padding(5.dp).clip(RoundedCornerShape(10.dp)).background(Color.Black.copy(alpha = 0.45f)).padding(horizontal = 6.dp, vertical = 2.dp))
                            Box(Modifier.align(Alignment.TopEnd).padding(7.dp).size(26.dp).clip(CircleShape)
                                .background(if (idx >= 0) p.a1 else Color.Black.copy(alpha = 0.12f)).border(2.dp, Color.White, CircleShape), contentAlignment = Alignment.Center) {
                                if (idx >= 0) Text("${idx + 1}", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 13.sp)
                            }
                        }
                    }
                }
            }
            // низ: вкладки или подпись + отправка
            Box(Modifier.align(Alignment.BottomCenter).fillMaxWidth().navigationBarsPadding().padding(horizontal = 10.dp, vertical = 8.dp)) {
                if (picked.isEmpty() || tabSel != "Галерея") {
                    Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(36.dp)).background(p.panel).horizontalScroll(rememberScrollState()).padding(6.dp)) {
                        @Composable fun tab(icon: ImageVector, t: String, on: Boolean = false, f: () -> Unit) {
                            Column(Modifier.width(84.dp).clip(RoundedCornerShape(30.dp)).background(if (on) p.a1.copy(alpha = 0.14f) else Color.Transparent).clickable(onClick = f).padding(vertical = 8.dp),
                                horizontalAlignment = Alignment.CenterHorizontally) {
                                Icon(icon, null, tint = if (on) p.a1 else p.text, modifier = Modifier.size(28.dp))
                                Text(t, color = if (on) p.a1 else p.text, fontSize = 12.5.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                            }
                        }
                        tab(Icons.Filled.PhotoLibrary, "Галерея", tabSel == "Галерея") { picked.clear(); tabSel = "Галерея" }
                        tab(Icons.Filled.Description, "Файл", tabSel == "Файл") { picked.clear(); tabSel = "Файл" }
                        tab(Icons.Filled.LocationOn, "Геопозиция", tabSel == "Геопозиция") { picked.clear(); tabSel = "Геопозиция" }
                        tab(Icons.Filled.BarChart, "Опрос") { AppModel.say("Опрос: в разработке") }
                        tab(Icons.Filled.PlayCircle, "Звук", tabSel == "Звук") { picked.clear(); tabSel = "Звук" }
                        tab(Icons.Filled.AccountCircle, "Контакт", tabSel == "Контакт") { picked.clear(); tabSel = "Контакт" }
                        tab(Icons.Filled.CameraAlt, "Камера") { onDismiss(); onCamera() }
                        tab(Icons.Filled.SlowMotionVideo, "Кружок") { onDismiss(); onNote() }
                        if (canLumens) tab(Icons.Filled.Diamond, "Люмены") { onDismiss(); onLumens() }
                    }
                } else {
                    Row(verticalAlignment = Alignment.Bottom) {
                        Box(Modifier.weight(1f).clip(RoundedCornerShape(26.dp)).background(p.panel).padding(horizontal = 16.dp, vertical = 14.dp)) {
                            if (caption.isEmpty()) Text("Добавьте подпись…", color = p.muted, fontSize = 16.sp)
                            BasicTextField(caption, { caption = it }, maxLines = 4, textStyle = TextStyle(color = p.text, fontSize = 16.sp), cursorBrush = SolidColor(p.a1), modifier = Modifier.fillMaxWidth())
                        }
                        Spacer(Modifier.width(8.dp))
                        Box(Modifier.size(52.dp).clip(CircleShape).background(p.accent).bouncy {
                            val list = picked.toList(); val cap = caption.trim().ifEmpty { null }
                            onDismiss(); onSend(list, cap)
                        }, contentAlignment = Alignment.Center) {
                            Icon(Icons.AutoMirrored.Filled.Send, null, tint = Color.White)
                            Text("${picked.size}", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 11.sp,
                                modifier = Modifier.align(Alignment.TopEnd).clip(RoundedCornerShape(9.dp)).background(p.a1).padding(horizontal = 5.dp))
                        }
                    }
                }
            }
        }
    }
}

private fun ContextCompatCheck(ctx: Context, perm: String) =
    androidx.core.content.ContextCompat.checkSelfPermission(ctx, perm) == PackageManager.PERMISSION_GRANTED

// ---------------- удаление чата: у себя / у всех ----------------

fun chatDeleteTitle(c: ChatItem): String = when {
    c.isPrivate -> "Удалить чат"
    c.role == "owner" -> if (c.isChannel) "Удалить канал" else "Удалить группу"
    else -> if (c.isChannel) "Отписаться" else "Покинуть группу"
}

@Composable
fun ChatDeleteFlow(c: ChatItem, onDismiss: () -> Unit) {
    val p = P
    val scope = rememberCoroutineScope()
    var warn by remember { mutableStateOf(false) }
    val owner = c.role == "owner"
    val name = c.displayName
    if (warn) {
        AlertDialog(onDismissRequest = onDismiss, title = { Text("Внимание!") },
            text = {
                Text(when {
                    c.isPrivate -> "Если удалить этот чат у обоих, вся переписка будет потеряна у вас и у собеседника. Вы точно хотите его удалить?"
                    c.isChannel -> "Если удалить этот канал, все подписчики и сообщения будут потеряны. Вы точно хотите его удалить?"
                    else -> "Если удалить эту группу, все участники и сообщения будут потеряны. Вы точно хотите её удалить?"
                })
            },
            confirmButton = { TextButton({ onDismiss(); scope.launch { AppModel.deleteChat(c.id, true) } }) { Text("Удалить всё", color = p.danger) } },
            dismissButton = { TextButton(onDismiss) { Text("Отмена") } })
        return
    }
    AlertDialog(onDismissRequest = onDismiss,
        title = { Text(if (c.isPrivate) "Удалить чат с «$name»?" else "«$name»", maxLines = 2, overflow = TextOverflow.Ellipsis) },
        text = {
            Column {
                @Composable fun opt(t: String, f: () -> Unit) {
                    Text(t, color = p.danger, fontWeight = FontWeight.SemiBold, fontSize = 16.sp, modifier = Modifier.fillMaxWidth().clickable(onClick = f).padding(vertical = 12.dp))
                }
                if (c.isPrivate) {
                    opt("Удалить у меня") { onDismiss(); scope.launch { AppModel.deleteChat(c.id, false) } }
                    opt("Удалить у меня и у $name") { warn = true }
                } else {
                    if (owner) opt(if (c.isChannel) "Удалить канал у всех" else "Удалить группу у всех") { warn = true }
                    opt(if (c.isChannel) "Отписаться" else "Покинуть группу") { onDismiss(); scope.launch { AppModel.deleteChat(c.id, false) } }
                }
            }
        },
        confirmButton = {}, dismissButton = { TextButton(onDismiss) { Text("Отмена") } })
}
