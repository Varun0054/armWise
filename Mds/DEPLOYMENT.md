# Deployment

## Target platform

- Windows 11, version 24H2 (Build 26100+) — minimum build with Snapdragon X Elite NPU driver support (NFR-5)
- Snapdragon X Elite / X Plus, and X2-series where available

## Build artifacts

### Flutter UI

```bash
cd ui
flutter build windows --release
```

Produces a release build under `ui/build/windows/x64/runner/Release/` (despite the `x64` path name, this targets the Windows desktop build; confirm ARM64-native build output once Flutter's Windows-on-ARM release tooling is finalized for your Flutter version).

### Python backend

Package the backend as a standalone executable so end users don't need a separate Python install:

```bash
cd backend
pip install pyinstaller
pyinstaller --onefile main.py
```

### AI models

- Finalize and export the embedding model and Llama-v3.2-1B-Instruct (or 3B fallback) to ONNX via `qai_hub_models`.
- Deploy through the Genie on-device LLM runtime targeting the Hexagon NPU via Qualcomm AI Engine Direct.
- Bundle model files alongside the packaged backend, or document a first-run download step if bundling makes the installer too large.

## Packaging

Combine the Flutter UI, packaged backend, model files, and the seeded Knowledge Base (`data/armwise.db`) into a single Windows installer (e.g. via Inno Setup or MSIX).

Installer should:
- Install to a standard location (e.g. `%LOCALAPPDATA%\ARMWise`)
- Register the backend to start alongside the UI (or launch it from the UI on startup) rather than requiring a separate manual step
- Not require an internet connection to install or run (per NFR-1 / privacy architecture)

## Pre-release checklist

- [ ] NPU validation completed via Qualcomm AI Hub remote profiling (see [`TESTING.md`](TESTING.md))
- [ ] `inference_backend` defaults to `qnn` in the shipped build config, not `cpu`
- [ ] Knowledge Base seeded with the full 50–100 case target, not the dev fixture set
- [ ] No hardcoded dev-only paths or debug endpoints left enabled
- [ ] Verified no network calls occur during a scan (privacy architecture, NFR-1) — test with network disabled
- [ ] Installer tested on a clean Windows 11 24H2+ Snapdragon machine (or closest available), not just the dev machine

## Known deployment gap

If final packaging/installer testing can't be done on real Snapdragon hardware before submission, note this explicitly in the submission materials rather than presenting it as fully validated — consistent with ARMWise's own "disclose uncertainty rather than fabricate confidence" principle.
