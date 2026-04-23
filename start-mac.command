#!/bin/bash
# ================================================================
# USBunnyclaw // Portable AI Engine [Mac Launcher]
# ----------------------------------------------------------------
# Everything stays on the drive. No installation, no footprint.
# ================================================================

# Move to the USB drive directory
cd "$(dirname "$0")"

USB_DIR=$(pwd)
MAC_OLLAMA_DIR="$USB_DIR/ollama_mac"
DATA_DIR="$USB_DIR/ollama/data"
STORAGE_DIR="$USB_DIR/anythingllm_data"

echo "✨ Initializing USBunnyclaw for Mac..."

# -----------------------------------------------------------------
# STEP 1: Deploy Mac Ollama Engine
# -----------------------------------------------------------------
if [ ! -d "$MAC_OLLAMA_DIR/Ollama.app" ] && [ ! -f "$MAC_OLLAMA_DIR/ollama" ]; then
    echo "⚙️ First run: Fetching AI Engine..."
    mkdir -p "$MAC_OLLAMA_DIR"
    curl -L --progress-bar "https://github.com/ollama/ollama/releases/latest/download/ollama-darwin.zip" -o "$MAC_OLLAMA_DIR/ollama-darwin.zip"
    unzip -o -q "$MAC_OLLAMA_DIR/ollama-darwin.zip" -d "$MAC_OLLAMA_DIR/"
    rm "$MAC_OLLAMA_DIR/ollama-darwin.zip"
    
    [ -f "$MAC_OLLAMA_DIR/Ollama.app/Contents/MacOS/Ollama" ] && chmod +x "$MAC_OLLAMA_DIR/Ollama.app/Contents/MacOS/Ollama"
    [ -f "$MAC_OLLAMA_DIR/ollama" ] && chmod +x "$MAC_OLLAMA_DIR/ollama"
    echo "✅ Engine ready."
fi

# -----------------------------------------------------------------
# STEP 2: Deploy AnythingLLM
# -----------------------------------------------------------------
if [ ! -d "$USB_DIR/anythingllm_mac/AnythingLLM.app" ]; then
    echo "⚙️ First run: Fetching interface..."
    mkdir -p "$USB_DIR/anythingllm_mac"
    curl -L --progress-bar "https://cdn.anythingllm.com/latest/AnythingLLMDesktop-Silicon.dmg" -o "$USB_DIR/anythingllm_mac/AnythingLLM_Installer.dmg"
    
    MOUNT_DIR=$(hdiutil attach -nobrowse "$USB_DIR/anythingllm_mac/AnythingLLM_Installer.dmg" | grep -o '/Volumes/.*')
    cp -R "$MOUNT_DIR/AnythingLLM.app" "$USB_DIR/anythingllm_mac/"
    hdiutil detach "$MOUNT_DIR"
    rm "$USB_DIR/anythingllm_mac/AnythingLLM_Installer.dmg"
    
    # Un-quarantine for seamless portability
    xattr -rc "$USB_DIR/anythingllm_mac/AnythingLLM.app"
    echo "✅ Interface ready."
fi

# -----------------------------------------------------------------
# STEP 3: System Prep & Config
# -----------------------------------------------------------------
export OLLAMA_MODELS="$DATA_DIR"
export STORAGE_DIR="$STORAGE_DIR"
mkdir -p "$STORAGE_DIR/storage"

# Configure local routing
DEFAULT_MODEL=$(head -n 1 "$USB_DIR/models/installed-models.txt" 2>/dev/null | cut -d '|' -f 1 || echo "nemomix-local")

cat > "$STORAGE_DIR/storage/.env" << EOF
LLM_PROVIDER=ollama
OLLAMA_BASE_PATH=http://127.0.0.1:11434
OLLAMA_MODEL_PREF=$DEFAULT_MODEL
OLLAMA_MODEL_TOKEN_LIMIT=4096
EMBEDDING_ENGINE=native
VECTOR_DB=lancedb
EOF

# Spin up Ollama
[ -f "$MAC_OLLAMA_DIR/Ollama.app/Contents/MacOS/Ollama" ] && "$MAC_OLLAMA_DIR/Ollama.app/Contents/MacOS/Ollama" serve > /dev/null 2>&1 &
[ -f "$MAC_OLLAMA_DIR/ollama" ] && "$MAC_OLLAMA_DIR/ollama" serve > /dev/null 2>&1 &
OLLAMA_PID=$!

sleep 3
echo "🚀 SYSTEM ONLINE: USBunnyclaw is live."

# -----------------------------------------------------------------
# STEP 4: Launch
# -----------------------------------------------------------------
# Wipe cache to ensure cross-Mac compatibility
rm -rf "$STORAGE_DIR/Cache" "$STORAGE_DIR/Code Cache" "$STORAGE_DIR/GPUCache" "$STORAGE_DIR/config.json" 2>/dev/null

open -a "$USB_DIR/anythingllm_mac/AnythingLLM.app" --args --user-data-dir="$STORAGE_DIR"

echo "---------------------------------------------------"
echo "Keep terminal active. Hit [ENTER] to kill the connection."
read -p ""
kill $OLLAMA_PID 2>/dev/null
killall AnythingLLM 2>/dev/null
echo "🛡️ USBunnyclaw powered down safely."
