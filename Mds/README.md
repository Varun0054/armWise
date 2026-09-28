# ARMWise

**An On-Device Windows-on-ARM Compatibility Advisor for Snapdragon®-Powered HP PCs**

Prepared for the Snapdragon® AI Lab Build & Present Challenge.

## What it does

Before you install a piece of software on a Snapdragon-powered Windows-on-ARM PC, ARMWise tells you — with evidence, not guesswork — whether it will run natively, run under Prism emulation, run with limitations, or fail outright, and why.

It combines three layers:

1. **Evidence Engine** (deterministic, no AI) — inspects PE headers, digital signatures, dependencies, and driver/anti-cheat indicators.
2. **AI Retrieval** — embeds that evidence and retrieves the most similar real-world compatibility cases from a curated knowledge base.
3. **AI Reasoning** — a local LLM, running on the Snapdragon Hexagon NPU, turns the evidence and retrieved cases into a plain-language, evidence-grounded explanation.

Everything runs on-device. No cloud dependency, no telemetry.

## Pipeline

```
INPUT (.exe / installed app / Store app)
   │
   ▼
EVIDENCE — deterministic analysis engine (rule-based, no AI)
   │
   ▼
AI RETRIEVAL — embedding model + similarity search vs. Knowledge Base
   │
   ▼
AI REASONING — local LLM (Snapdragon Hexagon NPU)
   │
   ▼
OUTPUT — category + evidence + explanation
```

## Tech stack

| Layer | Technology |
|---|---|
| Desktop UI | Flutter (Windows desktop target) |
| Backend | Python + FastAPI |
| PE parsing | `pefile` |
| Registry / Package APIs | `pywin32` + PowerShell interop |
| Knowledge Base | SQLite |
| Vector search | Cosine similarity over stored embeddings (no dedicated vector DB — KB is small) |
| Embedding model | `all-MiniLM-L6-v2` (dev) → Qualcomm AI Hub embedding model (target) |
| LLM | Local quantized model via `llama.cpp` (dev) → Llama-v3.2-1B-Instruct via Qualcomm AI Hub (target) |
| Inference runtime | ONNX Runtime / Qualcomm AI Engine Direct |
| Hardware acceleration | Snapdragon Hexagon NPU |

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full component breakdown.

## Quick start

See [`docs/SETUP.md`](docs/SETUP.md) for full setup instructions, including how to run against a CPU-only dev backend if you don't have access to Snapdragon hardware.

```bash
# Backend
cd backend
pip install -r requirements.txt
uvicorn main:app --reload

# UI
cd ui
flutter run -d windows
```

## Documentation

| Doc | Covers |
|---|---|
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Full pipeline, component breakdown, NPU integration, privacy architecture |
| [`docs/SETUP.md`](docs/SETUP.md) | Dev environment setup, CPU-stub vs. NPU backend switching |
| [`docs/API.md`](docs/API.md) | Local backend REST API (Flutter ↔ Python) |
| [`docs/DATABASE.md`](docs/DATABASE.md) | Compatibility Knowledge Base schema and sourcing |
| [`docs/TESTING.md`](docs/TESTING.md) | Test strategy, including AI Hub remote validation |
| [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) | Packaging and deployment to target devices |
| [`docs/LIMITATIONS.md`](docs/LIMITATIONS.md) | Known limitations and how they're disclosed to users |
| [`CHANGELOG.md`](CHANGELOG.md) | Version history |

## MVP scope

**In scope:** `.exe` drag-and-drop, installed app scan, installed Store app lookup, PE/metadata/dependency analysis, best-effort driver/anti-cheat detection, on-device embedding retrieval, local LLM explanation, 50–100 curated Knowledge Base cases.

**Out of scope:** exhaustive compatibility database, browser extension, automatic install/execution of software, compatibility guarantees, `.msi` deep parsing, cloud-hosted LLM inference, fabricated confidence percentages, non-Windows platforms.

## Status

Draft — in development for challenge submission. Target platform: Windows 11 24H2+ (Build 26100+), Snapdragon X Elite / X Plus / X2-series.

## Author

Varun Bhagwat — Final-Year B.E., Artificial Intelligence & Data Science (Minor: Cybersecurity)
