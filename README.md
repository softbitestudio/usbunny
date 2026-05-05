# 🐇🔌 USBunny 🍡 AI On A Stick

*"Raw. Local. Unfiltered."*

---

**USBunny** is a **plug-and-play AI environment** for those who want their AI like their food:
**Locally grown, untampered with, and free of corporate additives.**
By packing a full LLM stack onto a single drive, it turns any workstation into a **private, agentic powerhouse**.

---

## ✨ Core Principles

- **🔒 Data Sovereignty**
  Your weights, your drives, your data. **No cloud harvesting.**

- **🚫 Uncensored by Design**
  No corporate "safety-washing." Just raw compute for **distinctive narratives.**

- **🖥️ Hardware Agnostic**
  Designed to bridge the gap between **heavy local LLMs, Windows, Mac, and interactive sprites** on hardware like the **ESP32 or Raspberry Pi.**
  Works for **high RAM and low.**

---

## 📦 One-Time Install

The installer will **automatically detect your machine** and offer the optimal setup.

> **To install:**
> Right-click **`start-(your_OS)[.bat | .command]`** and select **"Run as Administrator"** (or equivalent).

---

## 🌐 Fully Offline

Each USB includes **two pre-loaded models** (purchase required from [softbite.studio](mailto:bunrec@softbite.studio)):
- **🪲 ONE TINY LLM** – Guaranteed to work on most machines.
- **🏢 ONE MID-SIZED LLM** – Fits commercial standards.

> **💰 Pricing:** $30 USD (includes shipping).
> **📩 Interested?** [Message me at bunrec@softbite.studio](mailto:bunrec@softbite.studio) to order.

---

## 🚀 Spin Up the Backend

For Users **Without the USB**:

Run Ollama locally with Docker (models will be stored on your machine):

```bash
docker run -d --gpus all -v ollama_data:/root/.ollama -p 11434:11434 ollama/ollama
```


## 
The installer will **automatically detect your machine** and offer the optimal setup.
 
|⭐ For Users **With the USB**:
   |
|----------------|
| 
    • plug in USBunny 
+ open folders of it doesn't automatically
    • Choose OS (windows, mac) 
    • START
|



# 🐧 Running Local AI on Linux (Ubuntu)

*No cloud. No tracking. Just your machine and the model.*

---

## 📌 Prerequisites
- **Ubuntu 20.04/22.04+** (or compatible Linux distro).
- **Internet connection** (to download models).
- **Optional**: NVIDIA GPU with CUDA drivers for faster performance.

---

## 🛠️ Option 1: Ollama (Easiest)
Ollama is the simplest way to run LLMs locally.

### 1. Install Ollama
```bash
curl -fsSL https://ollama.com/install.sh | sh
```

### 2. Start the Ollama Server
```bash
ollama serve
```

### 3. Pull a Model
```bash
ollama pull llama2       # Replace with mistral, phi, etc.
```

### 4. Run the Model
```bash
ollama run llama2
```

> **💡 GPU Support**: Ollama automatically uses your NVIDIA GPU if available. No extra steps needed!

---

## 🐳 Option 2: Ollama with Docker (Isolated)
For users who prefer Docker.

### 1. Install Docker
```bash
sudo apt update && sudo apt install -y docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
newgrp docker  # Refresh permissions
```

### 2. Run Ollama in Docker
```bash
docker run -d --gpus all -v ollama_data:/root/.ollama -p 11434:11434 ollama/ollama
```
- `--gpus all`: Enable GPU (remove if no GPU).
- `-v ollama_data:/root/.ollama`: Persist models on your machine.
- `-p 11434:11434`: Expose the Ollama API port.

### 3. Pull and Run a Model
```bash
docker exec -it <container_id> ollama pull llama2
docker exec -it <container_id> ollama run llama2
```
> Replace `<container_id>` with your container’s ID (find it with `docker ps`).

---

## 🔧 Option 3: `llama.cpp` (Advanced)
For full control over models and quantization.

### 1. Install Dependencies
```bash
sudo apt update && sudo apt install -y git cmake build-essential
```

### 2. Clone and Build
```bash
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp
make
```
> For GPU support (NVIDIA):
> ```bash
> make LLAMA_CUBLAS=1
> ```

### 3. Download a Model
```bash
wget https://huggingface.co/TheBloke/Llama-2-7B-Chat-GGML/resolve/main/llama-2-7b-chat.ggmlv3.q4_0.bin -O model.bin
```

### 4. Run the Model
```bash
./main -m model.bin -n 512 --repeat_penalty 1.0 -p "Your prompt here"
```
- `-n 512`: Generate up to 512 tokens.
- `--repeat_penalty 1.0`: Adjust creativity (higher = more repetitive).

---

## 📝 Notes & Tips

### Model Recommendations
| Size       | Model Example       | RAM Required | Use Case               |
|------------|---------------------|--------------|------------------------|
| Tiny       | `phi`, `tinyllama`   | 2-4GB        | Testing, low-end PCs   |
| Small      | `llama2:7b`         | 8GB+         | General use            |
| Medium     | `mistral:7b`        | 8GB+         | Balanced performance   |
| Large      | `llama2:13b`        | 16GB+        | High-end machines      |

### Troubleshooting
- **Out of Memory?**
  Use a smaller model or enable swap:
  ```bash
  sudo fallocate -l 8G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  ```

- **GPU Not Detected?**
  Install NVIDIA drivers:
  ```bash
  sudo ubuntu-drivers autoinstall
  sudo reboot
  ```

- **Slow Performance?**
  Use a smaller model or enable GPU acceleration.

---
### 🎯 Quick Start for USBunny Users
If you're using a **USBunny** drive, run the included setup script:
```bash
chmod +x setup_ollama.sh
./setup_ollama.sh
```
Then start chatting:
```bash
ollama run llama2
```

