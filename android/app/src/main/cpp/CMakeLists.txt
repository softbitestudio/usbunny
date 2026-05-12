cmake_minimum_required(VERSION 3.22.1)
project(usbunny_llm)

set(LLAMA_BUILD_TESTS    OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_SERVER   OFF CACHE BOOL "" FORCE)
set(BUILD_SHARED_LIBS    OFF CACHE BOOL "" FORCE)

add_subdirectory(llama.cpp)

add_library(usbunny_llm SHARED llama_bridge.cpp)

target_include_directories(usbunny_llm PRIVATE
    llama.cpp/include
    llama.cpp/common
)

target_link_libraries(usbunny_llm
    llama
    common
    android
    log
)
