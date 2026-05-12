package com.softbitestudio.usbunny

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch
import java.io.File

class MainActivity : ComponentActivity() {

    private lateinit var llm: LlamaInference
    private lateinit var db: USBunnyDatabase

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        llm = LlamaInference(this)
        db  = USBunnyDatabase.get(this)
        setContent { MaterialTheme { ChatScreen(llm, db) } }
    }

    override fun onDestroy() {
        super.onDestroy()
        llm.release()
    }
}

@Composable
fun ChatScreen(llm: LlamaInference, db: USBunnyDatabase) {
    val scope      = rememberCoroutineScope()
    val listState  = rememberLazyListState()
    val messages   = remember { mutableStateListOf<Pair<String, String>>() } // role, content
    var input      by remember { mutableStateOf("") }
    var streaming  by remember { mutableStateOf("") }
    var busy       by remember { mutableStateOf(false) }
    var modelStatus by remember { mutableStateOf("No model loaded") }

    // Load history and model on first composition
    LaunchedEffect(Unit) {
        db.memoryDao().getAll().forEach { messages.add(it.role to it.content) }

        val modelFile = File(llm.modelDir, llm.modelDir.list()
            ?.firstOrNull { it.endsWith(".gguf") } ?: "")
        if (modelFile.exists()) {
            modelStatus = "Loading ${modelFile.name}…"
            val ok = llm.loadModel(modelFile)
            modelStatus = if (ok) modelFile.name else "Failed to load model"
        } else {
            modelStatus = "Drop a .gguf into: ${llm.modelDir}"
        }
    }

    Column(Modifier.fillMaxSize()) {
        Text(
            text = modelStatus,
            style = MaterialTheme.typography.labelSmall,
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 4.dp)
        )

        LazyColumn(
            state = listState,
            modifier = Modifier.weight(1f).padding(horizontal = 8.dp)
        ) {
            items(messages) { (role, content) ->
                val label = if (role == "user") "You" else "USBunny"
                Text("$label: $content", modifier = Modifier.padding(vertical = 4.dp))
                HorizontalDivider()
            }
            if (streaming.isNotEmpty()) {
                item {
                    Text("USBunny: $streaming", modifier = Modifier.padding(vertical = 4.dp))
                }
            }
        }

        Row(
            modifier = Modifier.fillMaxWidth().padding(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            TextField(
                value = input,
                onValueChange = { input = it },
                modifier = Modifier.weight(1f),
                placeholder = { Text("Message…") },
                enabled = !busy
            )
            Spacer(Modifier.width(8.dp))
            Button(
                onClick = {
                    if (input.isBlank() || busy || !llm.isLoaded) return@Button
                    val userText = input.trim()
                    input = ""
                    busy = true

                    scope.launch {
                        messages.add("user" to userText)
                        db.memoryDao().insert(Memory(role = "user", content = userText))

                        // Build prompt from recent history (last 10 turns)
                        val history = db.memoryDao().getRecent(10).reversed()
                        val prompt = buildString {
                            history.forEach { m ->
                                if (m.role == "user") append("User: ${m.content}\n")
                                else append("Assistant: ${m.content}\n")
                            }
                            append("Assistant:")
                        }

                        streaming = ""
                        val response = llm.complete(prompt, maxTokens = 512) { tok ->
                            streaming += tok
                        }
                        streaming = ""

                        messages.add("assistant" to response)
                        db.memoryDao().insert(Memory(role = "assistant", content = response))
                        listState.animateScrollToItem(messages.size - 1)
                        busy = false
                    }
                },
                enabled = !busy && llm.isLoaded
            ) {
                Text(if (busy) "…" else "Send")
            }
        }
    }
}
