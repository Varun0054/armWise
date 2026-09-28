# Architecture

## Design principle

Hard facts are established deterministically. AI is used only where it adds genuine value — semantic retrieval and natural-language reasoning — never to guess at things a rule-based check can determine with certainty.

## Pipeline overview

```
INPUT
(.exe / installed app / Store app)
   │
   ▼
EVIDENCE — Deterministic Analysis Engine (rule-based, no AI)
   │
   ▼
AI RETRIEVAL — Embedding Model + Similarity Search
   │  against Compatibility Knowledge Base
   ▼
AI REASONING — Local LLM (on Snapdragon Hexagon NPU)
   │
   ▼
OUTPUT
ARMWise Report (category + evidence + explanation)
```

Each stage has one responsibility. Nothing downstream introduces facts the Evidence Engine didn't establish.

## Component breakdown

### 1. Input layer

| Method | Mechanism | MVP status |
|---|---|---|
| Drag & drop `.exe` | PE header + dependency analysis on the dropped binary | Primary — core demo path |
| Installed applications | Windows Registry enumeration + PE inspection | Secondary — bulk system health check |
| Microsoft Store apps | `Get-AppxPackage` / Windows Package APIs (architecture is declared in metadata, no binary inspection needed) | Secondary |
| Drag & drop `.msi` | Basic architecture/metadata check only | Stretch goal |

### 2. Evidence Engine (deterministic, no AI)

Establishes the trusted ground truth for everything downstream:

- PE header inspection — declared architecture (ARM64 / ARM64EC / x64 / x86)
- Digital signature and publisher metadata
- Imported DLL / Windows API dependency list
- Best-effort driver and anti-cheat indicator matching against a curated signature list (explicitly disclosed as best-effort)
- Store package metadata via Windows Package APIs

Output — structured evidence object:

```json
{
  "application": "ExampleApp.exe",
  "architecture": "x64",
  "native_arm64": false,
  "driver_indicators": true,
  "anti_cheat_indicators": false,
  "category": "Utility",
  "dependency_count": 17,
  "detection_confidence": "best-effort"
}
```

### 3. Compatibility Knowledge Base

Curated, source-attributed real-world compatibility observations used as the retrieval corpus. See [`DATABASE.md`](DATABASE.md) for the full schema. Target size for MVP: 50–100 verified cases.

### 4. AI Layer 1 — Embedding & similarity retrieval

```
New Application Evidence
   │
   ▼
Embedding Model (on-device)
   │
   ▼
Vector Representation
   │
   ▼
Similarity Search over Knowledge Base
   │
   ▼
Top-k Similar Cases (real similarity scores + outcomes)
```

Retrieval was chosen over training a supervised classifier from scratch: the available labelled data is in the low hundreds of examples — not enough to train or validate a trustworthy classifier. Retrieval degrades gracefully with sparse data and keeps every conclusion traceable to specific, inspectable source cases.

### 5. AI Layer 2 — Local LLM reasoning

Runs on the Snapdragon Hexagon NPU. Receives the structured evidence, retrieved cases, and derived category, and:

- Explains why a category was assigned, citing specific evidence and cases
- Answers free-form follow-up questions ("Why does Photoshop work but this VPN doesn't?")
- Supports system-wide queries ("Show me all apps with compatibility problems")

The LLM is constrained to explain given evidence — it does not introduce facts of its own.

### 6. Compatibility classification

| Category | Trigger condition |
|---|---|
| **Native** | PE header declares ARM64/ARM64EC, or Store metadata confirms native package |
| **Likely Compatible** | Retrieved high-similarity cases predominantly report success |
| **Uncertain** | Sparse or conflicting retrieved cases; KB coverage gap |
| **High Risk** | Driver/anti-cheat indicators present and/or retrieved cases predominantly report failure |

No invented numeric confidence score is shown when evidence is weak — the system states "insufficient evidence" directly.

## Snapdragon / Qualcomm AI Hub integration

```
ARMWise AI Components
      │
   ┌──┴──┐
Embedding  Local LLM
   │         │
   └────┬────┘
        ▼
  ONNX Runtime
        ▼
Qualcomm AI Engine Direct
        ▼
Snapdragon Hexagon NPU
```

| Model | Target | Reported throughput | Use |
|---|---|---|---|
| Llama-v3.2-1B-Instruct | Snapdragon X Elite CRD / X2 Elite CRD | ~34–37 tok/s (QNN/GENIE) | Primary — live explanation generation |
| Llama-v3.2-3B-Chat | Snapdragon X Elite CRD | ~23 tok/s (QNN) | Fallback / quality upgrade |

Both are deployed via `qai_hub_models` and the Genie on-device LLM runtime. Embedding model selection is finalized against current Qualcomm AI Hub availability for the Windows/ARM64 target.

## Privacy architecture

All analysis, embedding, retrieval, and LLM inference happens on-device. No executable, metadata, or derived evidence is uploaded anywhere. No telemetry is required for the tool to function.

## Dev-hardware note

Local development happens on non-Snapdragon hardware. The Evidence Engine, Knowledge Base, and retrieval layer are hardware-independent and fully testable locally. The LLM reasoning layer uses a swappable backend (CPU stub locally, QNN/Hexagon NPU on real or AI-Hub-remote hardware) — see [`SETUP.md`](SETUP.md).
