package com.softbitestudio.usbunny

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query

@Dao
interface MemoryDao {
    @Insert
    suspend fun insert(memory: Memory)

    @Query("SELECT * FROM memory ORDER BY timestamp ASC")
    suspend fun getAll(): List<Memory>

    // Last N turns to keep context window manageable
    @Query("SELECT * FROM memory ORDER BY timestamp DESC LIMIT :n")
    suspend fun getRecent(n: Int): List<Memory>

    @Query("DELETE FROM memory")
    suspend fun clearAll()
}
