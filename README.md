<div align="center">
  <img src="https://img.icons8.com/?size=512&id=v9hN1R8P8XzC&format=png" alt="ArmWise Logo" width="120" />
  <h1>ARM<span style="color:#0078D7">Wise</span></h1>
  <p><b>On-Device Windows-on-ARM Compatibility Advisor for Snapdragon-powered PCs</b></p>

  <p>
    <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white" alt="Flutter" /></a>
    <a href="https://fastapi.tiangolo.com/"><img src="https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi" alt="FastAPI" /></a>
    <a href="https://www.python.org/"><img src="https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54" alt="Python" /></a>
    <a href="https://www.sqlite.org/"><img src="https://img.shields.io/badge/sqlite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white" alt="SQLite" /></a>
  </p>
</div>

<br />

## 🌟 Overview

**ARMWise** is an intelligent, zero-cloud desktop application designed for Copilot+ PCs and Snapdragon X Elite/Plus devices. It acts as an on-device compatibility advisor, seamlessly analyzing legacy Windows x86/x64 executables and accurately predicting their behavior on ARM64 architectures. 

Unlike traditional tools, ARMWise uses a deterministic fact engine (parsing PE binaries, detecting driver signatures, identifying anti-cheat mechanisms) combined with grounded local AI to provide clear, actionable insights without hallucinating hardware facts.

---

## ✨ Key Features

- 🔍 **Deep Binary Analysis**: Deterministic parsing of PE machine headers and DLL dependencies.
- 🛡️ **Kernel & Anti-Cheat Detection**: Flags kernel-mode drivers and known anti-cheat mechanisms that often break emulation.
- 🧠 **Local Grounded AI**: Uses `all-MiniLM-L6-v2` vector embeddings and cosine similarity against a local SQLite database to explain compatibility logic and suggest ARM-native alternatives.
- 💻 **Stunning Native UI**: A beautiful, dark glassmorphic Flutter interface supporting both desktop and web preview.
- 🔒 **Zero-Cloud & Privacy First**: Everything runs on-device. No data leaves your machine.

---

## 🏗️ Architecture

ARMWise adopts a clean separation of concerns:
- **Backend**: Python-powered `FastAPI` service (running on port `8000`), handling file parsing, vector embeddings, SQLite interactions, and serving as the AI inference bridge.
- **Frontend**: A `Flutter`-based shell (compiled to Windows native or Web), offering a responsive, tabbed dashboard with drag-and-drop file scanning capabilities.

---

## 🚀 Getting Started

### Prerequisites

- **Python 3.9+**
- **Flutter SDK** (v3.38+ recommended)
- *(Optional)* Visual Studio 2022 Build Tools (for native Windows `.exe` build)

### 1️⃣ Launching the Backend API

```powershell
cd backend
pip install -r requirements.txt
python main.py
```
*The FastAPI server will start at `http://localhost:8000`.*

### 2️⃣ Launching the Flutter UI (Web Preview)

```powershell
cd ui
flutter run -d edge --web-port 3000
```

### 3️⃣ Running as a Native Windows App

If you have Visual Studio C++ tools installed:
```powershell
cd ui
flutter run -d windows
```

---

## 🧪 Testing

To run the backend integration and unit tests:
```powershell
cd backend
pytest
```

---

## 🔮 Roadmap

- [x] Deterministic Evidence Engine (PE parsing)
- [x] Embedded SQLite Knowledge Base
- [x] Local Classification & Explainer AI
- [x] Flutter UI Integration
- [ ] Hardware NPU Integration via Qualcomm AI Hub 
- [ ] Expand the Seed Knowledge Base with community reports

<br />

<div align="center">
  <sub>Built for the next generation of Windows computing.</sub>
</div>
