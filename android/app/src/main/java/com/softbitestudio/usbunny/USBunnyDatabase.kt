package com.softbitestudio.usbunny

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(entities = [Memory::class], version = 1)
abstract class USBunnyDatabase : RoomDatabase() {
    abstract fun memoryDao(): MemoryDao

    companion object {
        @Volatile private var INSTANCE: USBunnyDatabase? = null

        fun get(context: Context): USBunnyDatabase =
            INSTANCE ?: synchronized(this) {
                Room.databaseBuilder(context.applicationContext, USBunnyDatabase::class.java, "usbunny.db")
                    .build().also { INSTANCE = it }
            }
    }
}
