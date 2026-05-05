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
> **📩 Interested?** [Message me](mailto:bunrec@softbite.studio) to order.

---

## 🚀 Spin Up the Backend

### For Users **Without the USB**:
Run Ollama locally with Docker (models will be stored on your machine):
```bash
docker run -d --gpus all -v ollama_data:/root/.ollama -p 11434:11434 ollama/ollama
`


### For Users **With the USB**:
1. Mount the USB (e.g., to `/mnt/usb`).
2. Run Ollama with the USB as storage:
```bash
docker run -d --gpus all -v /mnt/usb/ollama:/root/.ollama -p 11434:11434 ollama/ollama
```
```

---
### **Notes for Non-Technical Users**
- **Docker Required**: They’ll need to [install Docker](https://docs.docker.com/get-docker/) first.
- **GPU Optional**: If they don’t have a GPU, remove `--gpus all` (but expect slower performance).
- **First-Time Setup**: After running the container, they’ll need to pull a model (e.g., `docker exec -it <container_id> ollama pull llama2`).

---
