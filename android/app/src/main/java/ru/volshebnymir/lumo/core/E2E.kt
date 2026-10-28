package ru.volshebnymir.lumo.core

import android.content.Context
import android.content.SharedPreferences
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.math.BigInteger
import java.security.AlgorithmParameters
import java.security.KeyFactory
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.MessageDigest
import java.security.SecureRandom
import java.security.interfaces.ECPrivateKey
import java.security.interfaces.ECPublicKey
import java.security.spec.ECGenParameterSpec
import java.security.spec.ECParameterSpec
import java.security.spec.ECPoint
import java.security.spec.ECPrivateKeySpec
import java.security.spec.ECPublicKeySpec
import javax.crypto.Cipher
import javax.crypto.KeyAgreement
import javax.crypto.Mac
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.PBEKeySpec
import javax.crypto.spec.SecretKeySpec

/**
 * Сквозное шифрование личных чатов.
 * У каждого пользователя на устройстве ключевая пара P-256; открытая часть лежит на сервере (lm_keys),
 * закрытая — только на устройстве и в резервной копии, зашифрованной паролем (lm_key_backup).
 * Ключ чата = HKDF-SHA256(ECDH, соль = id чата, info = "lumo-e2e-v1"); сообщение = "e2e1:" + base64(iv12 ‖ шифртекст+тег), AES-256-GCM.
 */
object E2E {
    const val PREFIX = "e2e1:"
    const val LOCKED = "🔒 Не удалось расшифровать"

    enum class Status { Loading, Ready, NeedRestore }

    var status by mutableStateOf(Status.Loading)
    /** есть ли резервная копия ключа на сервере */
    var backedUp by mutableStateOf(true)
    /** показать окно «придумайте пароль резервной копии» */
    var promptBackup by mutableStateOf(false)
    var busy by mutableStateOf(false)
    private var ver by mutableStateOf(0)

    private lateinit var prefs: SharedPreferences
    private val rnd = SecureRandom()
    private var me: String? = null
    private var myPriv: ECPrivateKey? = null
    private var myPub: ByteArray? = null
    private val peerPubs = HashMap<String, ByteArray>()
    private val noKeyAt = HashMap<String, Long>()
    private val chatKeys = HashMap<String, SecretKeySpec>()
    private val chatPeer = HashMap<String, String>()
    val changed = HashSet<String>()

    fun init(c: Context) { prefs = c.applicationContext.getSharedPreferences("lumo_e2e", Context.MODE_PRIVATE) }

    // ---------- примитивы ----------

    private val params: ECParameterSpec by lazy {
        val ap = AlgorithmParameters.getInstance("EC"); ap.init(ECGenParameterSpec("secp256r1")); ap.getParameterSpec(ECParameterSpec::class.java)
    }
    private fun fixed(b: BigInteger, n: Int): ByteArray {
        val r = b.toByteArray()
        return when { r.size == n -> r; r.size > n -> r.copyOfRange(r.size - n, r.size); else -> ByteArray(n - r.size) + r }
    }
    private fun pubRaw(k: ECPublicKey) = byteArrayOf(4) + fixed(k.w.affineX, 32) + fixed(k.w.affineY, 32)
    private fun pubKey(raw: ByteArray): ECPublicKey {
        require(raw.size == 65 && raw[0] == 4.toByte()) { "bad key" }
        val pt = ECPoint(BigInteger(1, raw.copyOfRange(1, 33)), BigInteger(1, raw.copyOfRange(33, 65)))
        return KeyFactory.getInstance("EC").generatePublic(ECPublicKeySpec(pt, params)) as ECPublicKey
    }
    private fun privKey(d: ByteArray) = KeyFactory.getInstance("EC").generatePrivate(ECPrivateKeySpec(BigInteger(1, d), params)) as ECPrivateKey
    private fun b64(b: ByteArray) = Base64.encodeToString(b, Base64.NO_WRAP)
    private fun unb64(s: String) = Base64.decode(s, Base64.DEFAULT)

    private fun hkdf(ikm: ByteArray, salt: ByteArray, info: ByteArray): ByteArray {
        val mac = Mac.getInstance("HmacSHA256")
        mac.init(SecretKeySpec(salt, "HmacSHA256")); val prk = mac.doFinal(ikm)
        mac.init(SecretKeySpec(prk, "HmacSHA256")); mac.update(info); mac.update(1.toByte())
        return mac.doFinal()
    }

    private fun seal(k: SecretKeySpec, plain: ByteArray): ByteArray {
        val iv = ByteArray(12).also { rnd.nextBytes(it) }
        val c = Cipher.getInstance("AES/GCM/NoPadding"); c.init(Cipher.ENCRYPT_MODE, k, GCMParameterSpec(128, iv))
        return iv + c.doFinal(plain)
    }
    private fun open(k: SecretKeySpec, data: ByteArray): ByteArray? = runCatching {
        if (data.size < 28) return null
        val c = Cipher.getInstance("AES/GCM/NoPadding"); c.init(Cipher.DECRYPT_MODE, k, GCMParameterSpec(128, data.copyOfRange(0, 12)))
        c.doFinal(data, 12, data.size - 12)
    }.getOrNull()

    // ---------- хранение закрытого ключа на устройстве (под защитой Android Keystore) ----------

    private fun wrapKey(): javax.crypto.SecretKey? = runCatching {
        val ks = KeyStore.getInstance("AndroidKeyStore"); ks.load(null)
        if (!ks.containsAlias("lumo_e2e_wrap")) {
            val g = javax.crypto.KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
            g.init(KeyGenParameterSpec.Builder("lumo_e2e_wrap", KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM).setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE).setKeySize(256).build())
            g.generateKey()
        }
        ks.getKey("lumo_e2e_wrap", null) as javax.crypto.SecretKey
    }.getOrNull()

    private fun saveLocal(uid: String, d: ByteArray, pub: ByteArray) {
        val plain = d + pub
        val w = wrapKey()
        val v = if (w != null) runCatching {
            val c = Cipher.getInstance("AES/GCM/NoPadding"); c.init(Cipher.ENCRYPT_MODE, w)
            "k:" + b64(c.iv + c.doFinal(plain))
        }.getOrNull() else null
        prefs.edit().putString("key_$uid", v ?: ("p:" + b64(plain))).apply()
    }
    private fun loadLocal(uid: String): Pair<ByteArray, ByteArray>? {
        val s = prefs.getString("key_$uid", null) ?: return null
        val raw = runCatching {
            if (s.startsWith("k:")) {
                val w = wrapKey() ?: return null
                val d = unb64(s.substring(2))
                val c = Cipher.getInstance("AES/GCM/NoPadding"); c.init(Cipher.DECRYPT_MODE, w, GCMParameterSpec(128, d.copyOfRange(0, 12)))
                c.doFinal(d, 12, d.size - 12)
            } else unb64(s.substring(2))
        }.getOrNull() ?: return null
        if (raw.size != 97) return null
        return raw.copyOfRange(0, 32) to raw.copyOfRange(32, 97)
    }
    private fun clearLocal(uid: String) { prefs.edit().remove("key_$uid").apply() }

    private fun install(uid: String, d: ByteArray, pub: ByteArray) {
        me = uid; myPriv = privKey(d); myPub = pub
        chatKeys.clear(); chatPeer.clear(); peerPubs.clear(); noKeyAt.clear()
    }

    // ---------- запуск после входа ----------

    suspend fun setup(uid: String) {
        if (me == uid && status == Status.Ready && myPriv != null) return
        runCatching {
            val srv = Api.select("lm_keys", mapOf("select" to "pub", "user_id" to "eq.$uid")).firstOrNull()?.str("pub")
            val local = loadLocal(uid)
            if (local != null && (srv == null || srv == b64(local.second))) {
                install(uid, local.first, local.second)
                if (srv == null) publish(uid, local.second)
                backedUp = Api.select("lm_key_backup", mapOf("select" to "user_id", "user_id" to "eq.$uid")).isNotEmpty()
                promptBackup = !backedUp && !prefs.getBoolean("skip_$uid", false)
                status = Status.Ready
                return
            }
            if (local != null) clearLocal(uid) // на сервере другой ключ: этот устройство отстало
            if (srv != null) { me = uid; myPriv = null; status = Status.NeedRestore; return }
            generateAndPublish(uid)
            promptBackup = true
        }
    }

    private suspend fun publish(uid: String, pub: ByteArray) {
        Api.raw("POST", "/rest/v1/lm_keys", mapOf("on_conflict" to "user_id"), jsonOf("user_id" to uid, "pub" to b64(pub)),
            mapOf("Prefer" to "resolution=merge-duplicates,return=minimal"))
    }

    private suspend fun generateAndPublish(uid: String) {
        val g = KeyPairGenerator.getInstance("EC"); g.initialize(ECGenParameterSpec("secp256r1"), rnd)
        val kp = g.generateKeyPair()
        val d = fixed((kp.private as ECPrivateKey).s, 32); val pub = pubRaw(kp.public as ECPublicKey)
        publish(uid, pub)
        saveLocal(uid, d, pub); install(uid, d, pub)
        backedUp = false; status = Status.Ready
    }

    fun forget() {
        me = null; myPriv = null; myPub = null; chatKeys.clear(); chatPeer.clear(); peerPubs.clear(); noKeyAt.clear(); changed.clear()
        status = Status.Loading; promptBackup = false; backedUp = true
    }

    // ---------- резервная копия под паролем ----------

    private fun pbkdf(password: String, salt: ByteArray, iters: Int): SecretKeySpec {
        val f = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")
        return SecretKeySpec(f.generateSecret(PBEKeySpec(password.toCharArray(), salt, iters, 256)).encoded, "AES")
    }

    suspend fun createBackup(password: String): Boolean {
        val uid = me ?: return false; val pr = myPriv ?: return false; val pub = myPub ?: return false
        busy = true
        return try {
            val salt = ByteArray(16).also { rnd.nextBytes(it) }
            val iters = 310000
            val blob = withContext(Dispatchers.Default) { seal(pbkdf(password, salt, iters), fixed(pr.s, 32) + pub) }
            Api.raw("POST", "/rest/v1/lm_key_backup", mapOf("on_conflict" to "user_id"),
                jsonOf("user_id" to uid, "salt" to b64(salt), "iters" to iters, "blob" to b64(blob), "updated_at" to Dates.string(java.util.Date())),
                mapOf("Prefer" to "resolution=merge-duplicates,return=minimal"))
            backedUp = true; promptBackup = false; true
        } catch (e: Exception) { false } finally { busy = false }
    }

    fun skipBackup() { me?.let { prefs.edit().putBoolean("skip_$it", true).apply() }; promptBackup = false }

    /** восстановление на новом устройстве; false — неверный пароль или нет копии */
    suspend fun restore(password: String): Boolean {
        val uid = Api.userId ?: return false
        busy = true
        return try {
            val row = Api.select("lm_key_backup", mapOf("select" to "salt,iters,blob", "user_id" to "eq.$uid")).firstOrNull() ?: return false
            val salt = unb64(row.str("salt") ?: return false); val iters = row.int("iters") ?: 310000
            val blob = unb64(row.str("blob") ?: return false)
            val plain = withContext(Dispatchers.Default) { open(pbkdf(password, salt, iters), blob) } ?: return false
            if (plain.size != 97) return false
            val d = plain.copyOfRange(0, 32); val pub = plain.copyOfRange(32, 97)
            val srv = Api.select("lm_keys", mapOf("select" to "pub", "user_id" to "eq.$uid")).firstOrNull()?.str("pub")
            if (srv != null && srv != b64(pub)) return false
            saveLocal(uid, d, pub); install(uid, d, pub)
            backedUp = true; promptBackup = false; status = Status.Ready
            true
        } catch (e: Exception) { false } finally { busy = false }
    }

    /** забыли пароль: новые ключи, старые зашифрованные сообщения прочитать будет нельзя */
    suspend fun reset(): Boolean {
        val uid = Api.userId ?: return false
        busy = true
        return try {
            runCatching { Api.delete("lm_key_backup", mapOf("user_id" to uid)) }
            generateAndPublish(uid)
            promptBackup = true
            true
        } catch (e: Exception) { false } finally { busy = false }
    }

    // ---------- ключи собеседников и чатов ----------

    private suspend fun peerPub(uid: String): ByteArray? {
        if (uid == me) return myPub
        peerPubs[uid]?.let { return it }
        val t = noKeyAt[uid]
        if (t != null && System.currentTimeMillis() - t < 60_000) return null
        val s = runCatching { Api.select("lm_keys", mapOf("select" to "pub", "user_id" to "eq.$uid")).firstOrNull()?.str("pub") }.getOrNull()
        if (s == null) { noKeyAt[uid] = System.currentTimeMillis(); return null }
        return if (accept(uid, s)) peerPubs[uid] else null
    }

    fun dropCaches() { noKeyAt.clear(); peerPubs.keys.removeAll { it != me }; chatKeys.clear() }

    /** Загрузить ключи сразу нескольких собеседников одним запросом */
    suspend fun prefetch(ids: Collection<String>) {
        val now = System.currentTimeMillis()
        val need = ids.filter { it != me && !peerPubs.containsKey(it) && (noKeyAt[it]?.let { t -> now - t > 60_000 } ?: true) }.distinct()
        if (need.isEmpty()) return
        val rows = runCatching { Api.select("lm_keys", mapOf("select" to "user_id,pub", "user_id" to "in.(" + need.joinToString(",") + ")")) }.getOrNull() ?: return
        val got = HashSet<String>()
        for (r in rows) { val u = r.str("user_id") ?: continue; val s = r.str("pub") ?: continue; if (accept(u, s)) got.add(u) }
        need.filter { it !in got }.forEach { noKeyAt[it] = now }
    }

    private fun accept(uid: String, s: String): Boolean {
        val raw = runCatching { unb64(s) }.getOrNull()?.takeIf { it.size == 65 } ?: return false
        noKeyAt.remove(uid)
        val pinned = prefs.getString("pin_$uid", null)
        if (pinned == null) prefs.edit().putString("pin_$uid", s).apply() else if (pinned != s) changed.add(uid)
        peerPubs[uid] = raw
        return true
    }

    /** Подготовить ключ чата (личный чат; peerId == null — «Избранное») */
    suspend fun prepare(chatId: String, peerId: String?) {
        if (status != Status.Ready || myPriv == null) return
        if (chatKeys.containsKey(chatId)) return
        val peer = peerId ?: me ?: return
        val pub = peerPub(peer) ?: return
        runCatching {
            val ka = KeyAgreement.getInstance("ECDH"); ka.init(myPriv); ka.doPhase(pubKey(pub), true)
            chatKeys[chatId] = SecretKeySpec(hkdf(ka.generateSecret(), chatId.lowercase().toByteArray(), "lumo-e2e-v1".toByteArray()), "AES")
            chatPeer[chatId] = peer
            ver++
        }
    }

    fun active(chatId: String): Boolean { ver; return chatKeys.containsKey(chatId) }
    fun isEnc(body: String?) = body != null && body.startsWith(PREFIX)

    fun encrypt(chatId: String, text: String): String? {
        val k = chatKeys[chatId] ?: return null
        return PREFIX + b64(seal(k, text.toByteArray()))
    }

    fun decrypt(chatId: String, body: String?): String? {
        if (body == null || !body.startsWith(PREFIX)) return body
        val k = chatKeys[chatId] ?: return LOCKED
        val raw = runCatching { unb64(body.substring(PREFIX.length)) }.getOrNull() ?: return LOCKED
        return open(k, raw)?.toString(Charsets.UTF_8) ?: LOCKED
    }

    /** Код безопасности: одинаковый у обоих собеседников, сверяется при встрече или по звонку */
    fun safety(peerId: String): String? {
        val a = myPub ?: return null
        val b = (if (peerId == me) myPub else peerPubs[peerId]) ?: return null
        val sa = b64(a); val sb = b64(b)
        val (x, y) = if (sa <= sb) sa to sb else sb to sa
        val h = MessageDigest.getInstance("SHA-256").digest("$x|$y".toByteArray())
        return (0 until 8).joinToString(" ") { i ->
            val v = ((h[i * 4].toLong() and 0xff) shl 24) or ((h[i * 4 + 1].toLong() and 0xff) shl 16) or ((h[i * 4 + 2].toLong() and 0xff) shl 8) or (h[i * 4 + 3].toLong() and 0xff)
            (v % 100000).toString().padStart(5, '0')
        }
    }
}
