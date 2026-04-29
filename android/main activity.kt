// MainActivity.kt
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            BunnyclawTheme {
                var chatMessages by remember { mutableStateOf(listOf("Agent: Hello! How can I help?")) }
                var userInput by remember { mutableStateOf("") }

                Column {
                    // Chat display
                    LazyColumn {
                        items(chatMessages) { message ->
                            Text(message, modifier = Modifier.padding(8.dp))
                        }
                    }
                    // User input
                    Row {
                        TextField(
                            value = userInput,
                            onValueChange = { userInput = it },
                            modifier = Modifier.weight(1f)
                        )
                        Button(onClick = {
                            // Run bun.sh script with user input
                            val process = ProcessBuilder()
                                .command("bun", "run", "agent.js", userInput)
                                .redirectErrorStream(true)
                                .start()
                            val output = process.inputStream.bufferedReader().readText()
                            chatMessages = chatMessages + listOf("You: $userInput", "Agent: $output")
                            userInput = ""
                        }) {
                            Text("Send")
                        }
                    }
                }
            }
        }
    }
}