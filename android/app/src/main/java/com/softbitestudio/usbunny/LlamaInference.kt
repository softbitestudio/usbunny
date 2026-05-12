package com.softbitestudio.usbunny

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

class LlamaInference(context: Context) {

    val modelDir: File = File(context.getExternalFilesDir(null), "models").also { it.mkdirs() }

    private var sessionPtr: Long = 0L

    companion object {
        init { System.loadLibrary("usbunny_llm") }
    }

    fun interface TokenCallback { fun onToken(token: String) }

    private external fun nativeLoad(path: String, nCtx: Int, nThreads: Int): Long
    private external fun nativeComplete(ptr: Long, prompt: String, maxTokens: Int, cb: TokenCallback): String
    private external fun nativeFree(ptr: Long)

    val isLoaded get() = sessionPtr != 0L

    fun loadModel(file: File, nCtx: Int = 4096): Boolean {
        release()
        sessionPtr = nativeLoad(
            file.absolutePath,
            nCtx,
            Runtime.getRuntime().availableProcessors().coerceAtMost(8)
        )
        return isLoaded
    }

    suspend fun complete(
        prompt: String,
        maxTokens: Int = 512,
        onToken: ((String) -> Unit)? = null
    ): String = withContext(Dispatchers.IO) {
        check(isLoaded) { "No model loaded" }
        nativeComplete(sessionPtr, prompt, maxTokens) { tok -> onToken?.invoke(tok) }
    }

    fun release() {
        if (sessionPtr != 0L) { nativeFree(sessionPtr); sessionPtr = 0L }
    }
}
