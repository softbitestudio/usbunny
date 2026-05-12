package com.softbitestudio.usbunny

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "memory")
data class Memory(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val role: String,       // "user" or "assistant"
    val content: String,
    val timestamp: Long = System.currentTimeMillis()
)
