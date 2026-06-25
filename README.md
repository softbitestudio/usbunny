# 🐇🔌 USBunny — AI On A Stick

*"Raw. Local. Unfiltered."*

**USBunny** is a plug-and-play AI environment that packs a full LLM stack onto a single USB drive, turning any workstation into a **private, agentic powerhouse** — no cloud required.

---

## ✨ Core Principles

- **🔒 Data Sovereignty** — Your weights, your drives, your data. No cloud harvesting.
- **🚫 Uncensored by Design** — No corporate safety-washing. Raw compute for distinct narratives.
- **🖥️ Hardware Agnostic** — Works on Windows, Mac, and Linux, across high and low RAM machines.
- **ENJOY** Whhat little time you have left on this earth, and try not to take everything seriously.
---

## 🚀 Quick Start (With USB)

1. Download the zip file to a USB 3.0+ flash drive with **at least 16 GB free**.
2. Open the drive folder.
3. **Right-click `start-(your_OS)`** and select **"Run as Administrator"**.

USBunny will automatically diagnose your machine and select a suitable model.

> **Linux users:** run the included setup script instead:
> ```bash
> chmod +x setup_ollama.sh && ./setup_ollama.sh
> ```

---

## 🖥️ Without a USB — Run Ollama Locally

### WINDOWS Option 1: Native Install (Easiest)
```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama serve

ollama run everythinglm
ollama run everythinglm
```

| xo |
### WINDOWS USERS |
  Ive taken the time to compile an exhaustive powershell diagnosis and repair script for you.
  ive tested its efficacy and im quite pleased.
  written for a RedPanda friend of mine, it will also serrrrrrrrrrrrrrrve you, should you 
  have concerns regarding your windows OS. 
  ### Dont forget to **right click** and __run as Administrator__


#for extra schizten giggles

```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama serve
ollama pull UncensoredAi/diddy
ollama run UncensoredAi/diddy
```

















#or simply summon

```bash
ollama run UncensoredAi/diddy
```

#swap in llama2-uncensored , mistral, phi, etc.





```bash
ollama signin
ollama run everythinglm
```

> **GPU support:** Ollama automatically uses your NVIDIA GPU if available.

### Option 2: Docker (Isolated)

```bash
# Install Docker (Linux)
sudo apt update && sudo apt install -y docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker $USER && newgrp docker

# Run Ollama
docker run -d --gpus all -v ollama_data:/root/.ollama -p 11434:11434 ollama/ollama
```

- `--gpus all` — enable GPU (remove if no GPU)
- `-v ollama_data:/root/.ollama` — persist models on your machine
- `-p 11434:11434` — expose the Ollama API port

|||||||Pull and run a model inside the container: |
```bash
docker exec -it $(docker ps -q) ollama pull llama2
docker exec -it $(docker ps -q) ollama run llama2
```

### Option 3: llama.cpp (Advanced)

Full control over models and quantization.

```bash
sudo apt update && sudo apt install -y git cmake build-essential
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp
make                  # add LLAMA_CUBLAS=1 for NVIDIA GPU support
```

Download and run a model:
```bash
wget https://huggingface.co/TheBloke/Llama-2-7B-Chat-GGML/resolve/main/llama-2-7b-chat.ggmlv3.q4_0.bin -O model.bin
./main -m model.bin -n 512 --repeat_penalty 1.0 -p "Your prompt here"
```

> No GPU? Check out [BitNet.cpp](https://github.com/microsoft/BitNet) for CPU-optimized inference.

---

## 📊 Model Reference

The more RAM you have, the larger the model you can run. USBunny auto-selects based on your hardware.

| RAM | Max Parameters (4-bit) | Example Models |
| :--- | :--- | :--- |
| 0 – 4 GB | < 1B | Phi-2, Qwen-0.5B, TinyLlama |
| 8 GB | 3B | Llama 3.2 3B, Phi-3.5 Mini |
| 16 GB | 8B | Llama 3.1 8B, Mistral 7B |
| 24 GB | 14B | Qwen 2.5 14B, Mistral NeMo 12B |
| 32 GB | 27B – 32B | Gemma 2 27B, Qwen 2.5 32B |
| 48 GB | 40B – 50B | Mixtral 8x7B, Command R 35B |
| 64 GB+ | 70B+ | Llama 3.3 70B, Qwen 2.5 72B |

---

## 🔧 Troubleshooting

**Out of memory?** Use a smaller model, or add swap space:
```bash
sudo fallocate -l 8G /swapfile && sudo chmod 600 /swapfile
sudo mkswap /swapfile && sudo swapon /swapfile
```

**GPU not detected?** Install NVIDIA drivers:
```bash
sudo ubuntu-drivers autoinstall && sudo reboot
```

**Slow performance?** Try a smaller model or enable GPU acceleration.

---

*Your conversation stays on your machine.*
