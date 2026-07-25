# 🐇🔌 USBunny — AI On A Stick

*"Raw. Local. Unfiltered."*

**USBunny** turns any USB drive into a portable, private AI workstation. Plug it in, run it, and transform any computer into an **uncensored, agentic powerhouse**—no cloud, no tracking, no restrictions.

---

## ✨ Why USBunny?

- **🔒 Your Data, Your Rules** — Models and conversations stay on your drive. No cloud harvesting, ever.
- **🚫 Truly Uncensored** — No corporate filters. Pure, unfiltered compute for any narrative.
- **🖥️ Works Everywhere** — Windows, Mac, Linux. High-end rig or modest laptop—it adapts.
- **🎉 Enjoy the Ride** — Life's short. Have fun, don't take it all so seriously.

---

## 🚀 Quick Start (USB Method)

The easiest way to get started:

1. **Download** the USBunny zip to a **USB 3.0+ drive (16GB+ free space)**
2. **Open** the drive folder
3. **Right-click** `start-(your_OS)` and **Run as Administrator**

USBunny will automatically detect your hardware and select the best model for your machine.

> **Linux users:** Run the setup script instead:
> ```bash
> chmod +x setup_ollama.sh && ./setup_ollama.sh
> ```

---

## 🖥️ Local Installation (No USB)

### Option 1: Native Ollama Install (Easiest)

**Windows/macOS/Linux:**
```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama serve
```

Then pull and run a model:
```bash
# For a balanced, uncensored experience
ollama pull everythinglm
ollama run everythinglm

# Or try these popular uncensored models
ollama pull UncensoredAi/diddy
ollama run UncensoredAi/diddy

# Swap in any model you like
ollama run llama2-uncensored
ollama run mistral
ollama run phi
```

> **Pro Tip:** `ollama signin` first to access private model registries.
> **GPU Support:** Ollama automatically uses NVIDIA GPUs if available.

---

### Option 2: Docker (Isolated Environment)

Perfect for keeping your system clean:

```bash
# Install Docker (Linux example)
sudo apt update && sudo apt install -y docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker $USER && newgrp docker

# Run Ollama container
docker run -d --gpus all -v ollama_data:/root/.ollama -p 11434:11434 ollama/ollama
```

**Flags Explained:**
- `--gpus all` — Enable GPU acceleration (remove if no GPU)
- `-v ollama_data:/root/.ollama` — Persist models on your machine
- `-p 11434:11434` — Expose Ollama's API port

**To use models in the container:**
```bash
docker exec -it $(docker ps -q) ollama pull llama2
docker exec -it $(docker ps -q) ollama run llama2
```

---

### Option 3: llama.cpp (Advanced Users)

For full control over models and quantization:

```bash
# Install dependencies
sudo apt update && sudo apt install -y git cmake build-essential

# Clone and build
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp
make                  # Add LLAMA_CUBLAS=1 for NVIDIA GPU

# Download and run a model
wget https://huggingface.co/TheBloke/Llama-2-7B-Chat-GGML/resolve/main/llama-2-7b-chat.ggmlv3.q4_0.bin -O model.bin
./main -m model.bin -n 512 --repeat_penalty 1.0 -p "Your prompt here"
```

> **No GPU?** Check out [BitNet.cpp](https://github.com/microsoft/BitNet) for CPU-optimized inference.

---

## 📊 Model Selection Guide

USBunny automatically selects the best model for your hardware. Here's what you can run:

| **RAM** | **Max Parameters (4-bit)** | **Recommended Models** |
|---------|----------------------------|------------------------|
| 0–4 GB  | < 1B                       | Phi-2, Qwen-0.5B, TinyLlama |
| 8 GB    | 3B                         | Llama 3.2 3B, Phi-3.5 Mini |
| 16 GB   | 8B                         | Llama 3.1 8B, Mistral 7B |
| 24 GB   | 14B                        | Qwen 2.5 14B, Mistral NeMo 12B |
| 32 GB   | 27B–32B                    | Gemma 2 27B, Qwen 2.5 32B |
| 48 GB   | 40B–50B                    | Mixtral 8x7B, Command R 35B |
| 64 GB+  | 70B+                       | Llama 3.3 70B, Qwen 2.5 72B |

---

## 🛠️ Windows Power Users

We've included a **comprehensive PowerShell diagnosis and repair script** for Windows users. It's been thoroughly tested and works like a charm.

> **⚠️ Important:** Right-click and **Run as Administrator** for full functionality.

This script was originally created for a RedPanda friend—now it's here to serve you too!

---

## 🔧 Troubleshooting

### Common Issues & Fixes

**💥 Out of Memory?**
Use a smaller model or add swap space:
```bash
sudo fallocate -l 8G /swapfile && sudo chmod 600 /swapfile
sudo mkswap /swapfile && sudo swapon /swapfile
```

**🖥️ GPU Not Detected?**
Install NVIDIA drivers:
```bash
sudo ubuntu-drivers autoinstall && sudo reboot
```

**🐢 Slow Performance?**
- Try a smaller model
- Enable GPU acceleration
- Close other memory-intensive applications

---

## 💬 Community & Support

Your conversation stays on your machine. But if you need help:

- Check the [GitHub Issues](https://github.com/softbitestudio/usbunny/issues)
- Join the discussion in [GitHub Discussions](https://github.com/softbitestudio/usbunny/discussions)

---

## 🎯 Philosophy

USBunny embodies a simple belief: **AI should be accessible, private, and free from arbitrary restrictions.**

In a world of walled gardens and data harvesting, we offer a different path—one where you control your compute, your data, and your experience.

So plug in, fire it up, and enjoy the freedom of truly local AI.

*Your mind, your machine, your rules.*
