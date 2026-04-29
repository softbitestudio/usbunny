// MainActivity.kt
package com.softbitestudio.bunnyclaw

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.BufferedReader
import java.io.InputStreamReader

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            BunnyclawTheme {
                ChatScreen()
            }
        }
    }
}

@Composable
fun ChatScreen() {
    var chatMessages by remember { mutableStateOf(listOf("Agent: Hello! I'm Bunnyclaw. How can I help?")) }
    var userInput by remember { mutableStateOf("") }

    Column(modifier = Modifier.fillMaxSize()) {
        // Chat messages
        LazyColumn(
            modifier = Modifier
                .weight(1f)
                .padding(8.dp)
        ) {
            items(chatMessages) { message ->
                Text(
                    text = message,
                    modifier = Modifier.padding(4.dp)
                )
                Divider()
            }
        }

        // User input
        Row(modifier = Modifier.fillMaxWidth()) {
            TextField(
                value = userInput,
                onValueChange = { userInput = it },
                modifier = Modifier.weight(1f),
                label = { Text("Type your message...") }
            )
            Button(
                onClick = {
                    if (userInput.isNotBlank()) {
                        // Add user message to chat
                        chatMessages = chatMessages + "You: $userInput"

                        // Run bun.sh script with user input
                        CoroutineScope(Dispatchers.IO).launch {
                            val response = runBunScript(userInput)
                            withContext(Dispatchers.Main) {
                                chatMessages = chatMessages + listOf("Agent: $response")
                            }
                        }
                        userInput = ""
                    }
                },
                modifier = Modifier.padding(start = 8.dp)
            ) {
                Text("Send")
            }
        }
    }
}

// Run the bun.sh script and return the output
private fun runBunScript(input: String): String {
    return try {
        val process = ProcessBuilder()
            .command("bun", "run", "agent.js", input)
            .redirectErrorStream(true)
            .start()

        val reader = BufferedReader(InputStreamReader(process.inputStream))
        val output = reader.readText()
        reader.close()
        output.ifEmpty { "No response from agent." }
    } catch (e: Exception) {
        "Error: ${e.message}"
    }
}

@Composable
fun BunnyclawTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        content = content
    )
}

// bunny noises 
private suspend fun copyAssetsToInternalStorage(context: Context) {
    withContext(Dispatchers.IO) {
        val assetManager = context.assets
        val files = assetManager.list("") ?: return@withContext

        for (file in files) {
            val inputStream = assetManager.open(file)
            val outputFile = File(context.filesDir, file)
            inputStream.use { input ->
                outputFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
            // Make the file executable (important for bun.sh)
            outputFile.setExecutable(true)
        }
    }
}