# Setup

## Prerequisites

- Windows 10/11 (Windows 11 24H2 / Build 26100+ required only for final target validation)
- Flutter SDK (Windows desktop support enabled: `flutter config --enable-windows-desktop`)
- Python 3.10+
- Git

You do **not** need Snapdragon/ARM64 hardware to build and test most of ARMWise locally. See "Dev hardware notes" below.

## 1. Clone and install

```bash
git clone <repo-url> armwise
cd armwise

# Backend
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt

# UI
cd ../ui
flutter pub get
```

## 2. Configure the inference backend

ARMWise abstracts embedding and LLM inference behind a single interface (`embed()`, `generate()`) with two implementations. Select which one runs via `backend/config.yaml`:

```yaml
inference_backend: cpu   # options: cpu | qnn
```

### `cpu` (default for local dev)

- Embedding model: `all-MiniLM-L6-v2` via `sentence-transformers`, CPU-only
- LLM: small quantized GGUF model via `llama.cpp` (e.g. a 1B model, INT4)
- No Snapdragon hardware required
- Use this for building and debugging the Evidence Engine, Knowledge Base, retrieval logic, prompt templates, and UI — everything except final NPU performance validation

### `qnn` (Snapdragon Hexagon NPU)

- Embedding + LLM served via ONNX Runtime / Qualcomm AI Engine Direct
- Requires either physical Snapdragon X Elite/Plus hardware, or Qualcomm AI Hub's remote-hosted device profiling
- Use this only for final performance/quality validation against NFR-2 (few-seconds-per-scan)

## 3. Run

```bash
# Backend (from /backend)
uvicorn main:app --reload --port 8000

# UI (from /ui, separate terminal)
flutter run -d windows
```

## 4. Seed the Knowledge Base

```bash
cd backend
python scripts/seed_kb.py --source data/kb_seed.json
```

See [`DATABASE.md`](DATABASE.md) for the schema and sourcing plan.

## Dev hardware notes

If your dev machine doesn't have Snapdragon/ARM64/NPU hardware (e.g. an older Intel CPU with limited RAM):

- Build and fully debug the Evidence Engine, Knowledge Base, and retrieval layer locally — none of it needs special hardware.
- Use `inference_backend: cpu` for all pipeline/logic development. It's slower than NPU inference but functionally equivalent for debugging.
- Keep the local LLM stub small (an INT4-quantized 1B model, or fewer parameters) to stay within limited RAM. If even that's too heavy, mock `generate()` with template-based canned responses while wiring up the UI, and swap in a real model only when testing the reasoning layer specifically.
- Validate actual NPU throughput and output quality via Qualcomm AI Hub's remote device profiling before the final demo — this is the one thing that can't be faked locally.
- Confirm your dev machine can run the Windows 11 24H2 build you're targeting for the Store/Package API work; if not, develop against an available Windows 10/11 build and validate the final installer separately on a machine or VM that meets NFR-5.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `flutter run -d windows` fails to find a device | Windows desktop support not enabled — run `flutter config --enable-windows-desktop` and restart |
| Backend can't reach `Get-AppxPackage` | Run the backend with permissions to invoke PowerShell; check `pywin32` install |
| Local LLM stub is too slow to be usable | Reduce model size/quantization further, or switch to the mock `generate()` response for non-reasoning-focused work |
| `qnn` backend fails to initialize | Expected on non-Snapdragon hardware — switch back to `cpu`, or use AI Hub remote profiling instead of local `qnn` |
