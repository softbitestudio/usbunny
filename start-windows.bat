@echo off
:: =================================================================
:: USBunny // Portable AI Engine [Bunny Reckless Edition]
:: Aesthetic: Bubble Goth / Pastel Punk
:: =================================================================
title USBunny // System Online
color 05

echo ***************************************************************
echo      (\ /)
echo      (n n)
echo     (     )o    USBunny // AI Engine Awakening...
echo        
echo   keep it local.
echo    
echo     
echo ***************************************************************

:: -------------------------------------------------------
:: Path Sovereignty: Keeping it all on the drive
:: -------------------------------------------------------
set "OLLAMA_MODELS=%~dp0ollama\data"
set "STORAGE_DIR=%~dp0anythingllm_data"
set "APPDATA=%STORAGE_DIR%"
set "LOCALAPPDATA=%STORAGE_DIR%"

if not exist "%STORAGE_DIR%" mkdir "%STORAGE_DIR%"

:: -------------------------------------------------------
:: Engine Routing: Ensuring the Bunny stays uncensored
:: -------------------------------------------------------
set "ENV_FILE=%STORAGE_DIR%\storage\.env"
if not exist "%STORAGE_DIR%\storage" mkdir "%STORAGE_DIR%\storage"

set "DEFAULT_MODEL=nemomix-local"
if exist "%~dp0models\installed-models.txt" (
    for /f "usebackq tokens=1 delims=|" %%a in ("%~dp0models\installed-models.txt") do (
        set "DEFAULT_MODEL=%%a"
        goto :GotModel
    )
)
:GotModel

echo [Configuring Engine Pipeline...]
(
    echo LLM_PROVIDER=ollama
    echo OLLAMA_BASE_PATH=http://127.0.0.1:11434
    echo OLLAMA_MODEL_PREF=%DEFAULT_MODEL%
    echo OLLAMA_MODEL_TOKEN_LIMIT=4096
    echo EMBEDDING_ENGINE=native
    echo VECTOR_DB=lancedb
) > "%ENV_FILE%"

:: -------------------------------------------------------
:: Status Check
:: -------------------------------------------------------
if exist "%~dp0models\installed-models.txt" (
    echo.
    echo [Loaded Models:]
    for /f "usebackq tokens=1,2,3 delims=|" %%a in ("%~dp0models\installed-models.txt") do (
        echo   + %%b [%%c]
    )
    echo.
)

:: Startup Sequence
echo Starting Ollama background process...
start "" /B "%~dp0ollama\ollama.exe" serve
timeout /t 3 >nul

:: Launch Interface
if not exist "%~dp0anythingllm\AnythingLLM.exe" (
    echo [!] ERROR: Bunny needs her tools! AnythingLLM not found.
    pause & exit /b
)

:: Clean state maintenance
if exist "%STORAGE_DIR%\config.json" del /q "%STORAGE_DIR%\config.json"
for %%d in ("Cache" "Code Cache" "GPUCache") do (
    if exist "%STORAGE_DIR%\%%~d" rmdir /s /q "%STORAGE_DIR%\%%~d"
)

echo Launching Interface...
pushd "%~dp0anythingllm"
start "" "AnythingLLM.exe" --user-data-dir="%STORAGE_DIR%"
popd

:: -------------------------------------------------------
:: System Active
:: -------------------------------------------------------
echo.
echo ***************************************************************
echo    USBunny is fully operational. Vivere Militare Est.
echo ***************************************************************
echo.
echo Keep this terminal alive to keep the magic running.
echo Press any key to safely power down the Bunny...
pause >nul

:: Clean Shutdown
taskkill /F /IM "ollama.exe" >nul 2>&1
taskkill /F /IM "AnythingLLM.exe" >nul 2>&1
echo.
echo Shutdown complete!uwu
timeout /t 2 >nul
