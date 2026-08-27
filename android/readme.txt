
>[!IMPORTANT]
>this is still on progress but Android support will be available by September 20th, 2026

Bunnyclaw-Android/
├── app/
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/softbitestudio/bunnyclaw/
│   │   │   │   ├── MainActivity.kt
│   │   │   │   ├── Memory.kt (Entity)
│   │   │   │   ├── MemoryDao.kt
│   │   │   │   └── BunnyclawDatabase.kt (Room DB)
│   │   │   ├── res/
│   │   │   │   └── layout/ (if using XML)
│   │   │   └── assets/
│   │   │       ├── bun
│   │   │       └── agent.js
│   │   └── AndroidManifest.xml
│   └── build.gradle
└── build.gradle


building an android wrapper to host an LLM 