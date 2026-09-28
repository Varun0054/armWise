# ARMWise — IMPLEMENTATION.md

> Master implementation and development plan for ARMWise.
>
> This document is the execution guide for building the project. It references and follows the contracts, architecture, database design, setup process, testing strategy, deployment requirements, and limitations defined in the other project documents.

---

## 1. Purpose

ARMWise is an on-device Windows-on-ARM compatibility advisor for Snapdragon-powered Windows PCs.

The implementation must preserve the core design principle:

**Deterministic analysis establishes facts; AI is used for retrieval and explanation, not for guessing facts.**

The implementation pipeline is:

```text
INPUT
  │
  ├── Dropped .exe
  ├── Installed application
  └── Microsoft Store application
  │
  ▼
EVIDENCE ENGINE
  │
  ├── PE architecture
  ├── Signature / publisher
  ├── Imported DLLs / APIs
  ├── Driver indicators
  ├── Anti-cheat indicators
  └── Store metadata
  │
  ▼
AI RETRIEVAL
  │
  ├── Evidence embedding
  └── Similarity search against Knowledge Base
  │
  ▼
AI REASONING
  │
  └── Local LLM explanation
  │
  ▼
ARMWise REPORT
  │
  ├── Category
  ├── Evidence
  ├── Similar cases
  └── Explanation
```

The detailed architecture is defined in `ARCHITECTURE.md`.

---

# 2. Source-of-Truth Documentation

The implementation must use the project documentation as the contract.

| Document | Implementation role |
|---|---|
| `README.md` | Product definition, scope, stack, MVP |
| `ARCHITECTURE.md` | System architecture and component responsibilities |
| `API.md` | Flutter ↔ FastAPI API contract |
| `DATABASE.md` | SQLite schema and Knowledge Base design |
| `SETUP.md` | Development environment and execution |
| `TESTING.md` | Unit, integration, AI and NPU validation |
| `DEPLOYMENT.md` | Packaging and release requirements |
| `LIMITATIONS.md` | Known limitations and prohibited claims |
| `CHANGELOG.md` | Implementation progress and project history |
| `IMPLEMENTATION.md` | **Master build order and development workflow** |

If implementation decisions conflict with these documents, update the appropriate specification first rather than silently changing the implementation.

---

# 3. MVP Boundary

## 3.1 Implement

The MVP includes:

- `.exe` drag-and-drop analysis
- Installed application enumeration
- Microsoft Store application lookup
- PE / metadata / dependency analysis
- Best-effort driver detection
- Best-effort anti-cheat detection
- Compatibility Knowledge Base
- On-device embedding retrieval
- Similarity search
- Local LLM reasoning
- Grounded explanations
- Dashboard summary
- Follow-up `/ask`
- ARM64-native alternatives from Knowledge Base
- 50–100 curated Knowledge Base cases
- CPU development backend
- QNN/NPU production validation

These boundaries come from `README.md`, `ARCHITECTURE.md`, `API.md`, and `LIMITATIONS.md`.

## 3.2 Do not expand MVP

Do not add:

- Exhaustive application compatibility coverage
- Automatic installation of software
- Automatic execution/testing of arbitrary software
- Compatibility guarantees
- Cloud-hosted LLM inference
- Fabricated confidence percentages
- Non-Windows support
- Deep `.msi` parsing
- Browser extension functionality
- A large independently trained compatibility classifier

See `LIMITATIONS.md`.

---

# 4. Development Strategy

Development is deliberately divided into hardware-independent and Snapdragon/NPU-dependent work.

## Local development

The following can be built and tested without Snapdragon hardware:

- FastAPI backend
- Evidence Engine
- PE parsing
- Registry enumeration
- Store metadata parsing
- SQLite database
- Knowledge Base
- Embedding retrieval
- Similarity calculation
- Classification logic
- API endpoints
- CPU reasoning backend
- Prompt construction
- Flutter UI
- UI/backend integration
- Most automated tests

Use:

```yaml
inference_backend: cpu
```

as defined in `SETUP.md`.

## Snapdragon validation

Only the following requires Snapdragon hardware or Qualcomm AI Hub remote profiling:

- QNN backend
- Qualcomm AI Engine Direct integration
- Hexagon NPU execution
- Final model throughput validation
- Final production inference quality/performance validation

Do not block ordinary development on NPU access.

---

# 5. Phase 0 — Repository and Environment Setup

## Objective

Create the development foundation before implementing product logic.

## Required environment

According to `SETUP.md`:

- Windows 10/11
- Windows 11 24H2 / Build 26100+ for final target validation
- Flutter SDK with Windows desktop enabled
- Python 3.10+
- Git

Enable Flutter Windows support:

```bash
flutter config --enable-windows-desktop
```

## Backend environment

```bash
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

## UI environment

```bash
cd ../ui
flutter pub get
```

## Initial validation

Confirm:

```bash
python --version
flutter --version
flutter devices
```

Then verify:

```bash
flutter run -d windows
```

The initial Flutter application only needs to prove that the Windows desktop target works.

---

# 6. Phase 1 — Backend Skeleton

## Objective

Create a working FastAPI service before implementing analysis logic.

Expected foundation:

```text
backend/
├── main.py
├── config.yaml
├── requirements.txt
├── api/
├── evidence/
├── retrieval/
├── reasoning/
├── database/
├── scripts/
└── tests/
```

The exact internal package structure can evolve, but responsibilities must remain separated according to `ARCHITECTURE.md`.

## First endpoint

Implement a basic health endpoint for development.

Example:

```text
GET /health
```

This is a development endpoint and must not remain enabled unnecessarily in the production build.

## Run

```bash
uvicorn main:app --reload --port 8000
```

Verify that the backend starts successfully before adding analysis functionality.

---

# 7. Phase 2 — Evidence Engine

## Objective

Build the deterministic foundation of ARMWise.

The Evidence Engine must not depend on an LLM.

It establishes the facts consumed by every downstream component.

## 7.1 PE architecture detection

For a dropped `.exe`, inspect:

- PE header
- Declared architecture
- ARM64
- ARM64EC
- x64
- x86

Use the project's selected PE parsing dependency (`pefile` according to `README.md`).

Output:

```json
{
  "architecture": "x64",
  "native_arm64": false
}
```

## 7.2 Digital signature and publisher metadata

Extract available:

- publisher information
- signature status
- relevant executable metadata

Do not infer trustworthiness merely from the presence of a publisher.

## 7.3 Imported DLL/API analysis

Extract the executable's imported dependencies.

Record:

```text
dependency_count
imports
```

The dependency evidence can later be converted into the retrieval representation.

## 7.4 Driver indicators

Implement the curated signature-based detection described in `ARCHITECTURE.md`.

This is explicitly:

**best-effort detection**

It must never be presented as exhaustive.

## 7.5 Anti-cheat indicators

Use the same curated, versioned signature approach.

Again:

**best-effort, not guaranteed.**

## 7.6 Evidence object

The Evidence Engine should produce a structured object consistent with the architecture/API contract:

```json
{
  "application": "ExampleApp.exe",
  "architecture": "x64",
  "native_arm64": false,
  "driver_indicators": false,
  "anti_cheat_indicators": false,
  "category": "Utility",
  "dependency_count": 17,
  "detection_confidence": "best-effort"
}
```

Do not add an invented numerical risk score.

---

# 8. Phase 3 — Installed Application Detection

## Objective

Implement:

```text
GET /scan/installed
```

The implementation should:

1. Enumerate installed applications through Windows Registry mechanisms.
2. Locate executable information where available.
3. Run applicable Evidence Engine analysis.
4. Produce scan result objects.
5. Produce the dashboard summary.

The API contract specifies that this endpoint returns scan results plus a summary block.

This functionality is secondary to the primary `.exe` demo path, so it should not delay the first end-to-end prototype.

---

# 9. Phase 4 — Microsoft Store Application Detection

## Objective

Implement:

```text
GET /scan/store
```

Use Windows Package APIs / `Get-AppxPackage` as described in the architecture and setup documentation.

Store metadata can directly declare package architecture.

Therefore Store architecture detection can have:

```text
detection_confidence = "declared"
```

where appropriate.

This is different from best-effort binary indicator detection.

---

# 10. Phase 5 — Classification Logic

Classification must remain deterministic where deterministic evidence is sufficient.

The architecture defines:

| Condition | Category |
|---|---|
| ARM64 / ARM64EC | Native |
| Store metadata confirms native package | Native |
| Retrieved cases predominantly successful | Likely Compatible |
| Sparse/conflicting evidence | Uncertain |
| Driver/anti-cheat indicators and/or predominantly failing retrieved cases | High Risk |

Important:

Do not create an artificial percentage such as:

```text
87% compatible
```

The project explicitly rejects fabricated or uncalibrated compatibility confidence.

When evidence is insufficient:

```json
{
  "insufficient_evidence": true
}
```

should be returned according to the API contract.

---

# 11. Phase 6 — SQLite Database

## Objective

Create the local Knowledge Base.

Storage:

```text
data/armwise.db
```

No database server is required.

The primary table is:

```sql
compatibility_cases
```

with fields defined in `DATABASE.md`:

```text
id
application
architecture
native_arm64
driver_indicators
anti_cheat_indicators
category
observed_result
source
source_date
embedding
```

Allowed architecture values:

```text
x86
x64
ARM64
ARM64EC
```

Allowed observed results:

```text
works
works_with_limitations
fails
unknown
```

---

# 12. Phase 7 — Knowledge Base Seeding

## Objective

Build the initial retrieval corpus.

## Development fixture

Start with:

```text
10–15 records
```

This is sufficient for retrieval tests.

## MVP corpus

Grow to:

```text
50–100 verified, source-attributed cases
```

This is a critical-path deliverable.

Each record must contain a source and source date.

Do not fabricate compatibility observations.

## Seed script

The documented interface is:

```bash
python scripts/seed_kb.py --source data/kb_seed.json
```

The seed JSON contains the case fields excluding the computed embedding.

---

# 13. Phase 8 — Embedding Layer

## Development model

Use the development embedding model specified in `README.md`:

```text
all-MiniLM-L6-v2
```

The embedding layer must expose a stable abstraction.

Conceptually:

```python
embedding = embed(evidence)
```

Do not couple the rest of the application directly to a particular model.

## Production target

Replace the development embedding implementation with the Qualcomm AI Hub target model once finalized.

The API/application logic should remain unchanged.

---

# 14. Phase 9 — Similarity Retrieval

## Objective

Retrieve comparable compatibility cases.

Pipeline:

```text
Evidence Object
      │
      ▼
Embedding
      │
      ▼
Cosine Similarity
      │
      ▼
All Knowledge Base Records
      │
      ▼
Top-K Cases
```

For the MVP database size, do not introduce a dedicated vector database.

`DATABASE.md` specifies storing embeddings as BLOBs and computing cosine similarity in Python.

The result should contain real similarity scores.

Do not convert similarity into an invented "risk percentage."

---

# 15. Phase 10 — Retrieval-Based Compatibility Reasoning

The system should use retrieved cases rather than training a classifier from the limited dataset.

The reason is documented in `ARCHITECTURE.md`:

- available labelled data is only in the low hundreds
- retrieval is more traceable
- retrieved evidence can be inspected
- sparse data degrades to `Uncertain`

Implementation:

```text
Evidence
   ↓
Embedding
   ↓
Top-K retrieved cases
   ↓
Observed outcomes
   ↓
Classification
```

Every classification should remain traceable to the evidence and retrieved cases.

---

# 16. Phase 11 — Local LLM Reasoning

## Objective

Generate human-readable explanations.

The LLM receives:

```text
Structured Evidence
+
Derived Category
+
Retrieved Compatibility Cases
```

It must:

- explain the classification
- reference concrete evidence
- reference retrieved cases
- include source/source_date where applicable
- answer follow-up questions using supplied context

It must not:

- invent compatibility facts
- invent sources
- invent alternative applications
- override deterministic evidence
- provide unsupported confidence values

The reasoning layer is therefore an explanation layer, not the source of truth.

---

# 17. Phase 12 — `/ask`

Implement:

```text
POST /ask
```

Request:

```json
{
  "context_id": "scan-result-id or 'system-summary'",
  "question": "Why does Photoshop work but this VPN doesn't?"
}
```

Response:

```json
{
  "answer": "..."
}
```

The answer must be grounded only in the evidence and retrieved cases available for that context.

Tests must explicitly check that the LLM does not fall back to unsupported general knowledge.

---

# 18. Phase 13 — Dashboard

Implement:

```text
GET /dashboard/summary
```

Example:

```json
{
  "native": 12,
  "likely_compatible": 30,
  "uncertain": 8,
  "high_risk": 3,
  "total": 53
}
```

Implement:

```text
GET /dashboard/alternatives/{application_id}
```

Alternatives must come from the Knowledge Base.

The LLM must not invent alternative applications.

---

# 19. Phase 14 — Flutter UI

## Primary screen

Build the first useful UI around the primary demo path:

```text
Drag .exe
     ↓
Analyze
     ↓
Result
```

The UI should display:

- Application name
- Compatibility category
- Architecture
- Native ARM64 status
- Driver indicators
- Anti-cheat indicators
- Dependency information
- Retrieved similar cases
- Similarity values
- Explanation
- Insufficient-evidence state

## Secondary screens/features

Then implement:

1. Installed applications
2. Store applications
3. Dashboard
4. Follow-up questions
5. Alternatives

Do not overbuild UI before the backend produces reliable data.

---

# 20. Phase 15 — API Integration

Connect Flutter to the local FastAPI service:

```text
Flutter
   │
   │ HTTP localhost
   ▼
FastAPI :8000
   │
   ▼
Evidence / Retrieval / Reasoning
```

All API request/response shapes must follow `API.md`.

The API is local and must not upload executable files or derived evidence.

---

# 21. Phase 16 — End-to-End Pipeline

At this point the complete CPU-backed flow should work:

```text
Drop example.exe
       ↓
Flutter
       ↓
POST /scan/exe
       ↓
PE analysis
       ↓
Evidence object
       ↓
Embedding
       ↓
SQLite Knowledge Base
       ↓
Top-K cases
       ↓
Classification
       ↓
Local LLM
       ↓
JSON response
       ↓
Flutter result screen
```

This is the first major milestone.

---

# 22. Phase 17 — Testing

Testing follows `TESTING.md`.

## Evidence tests

Test:

- known ARM64 executable
- known x64 executable
- known x86 executable
- unsigned executable
- known driver signature
- known anti-cheat signature
- Registry enumeration
- Store package parsing

These tests must run locally and quickly.

## Retrieval tests

Use a 10–15 record fixture database.

Verify:

- expected top-k ordering
- real similarity values
- insufficient evidence behavior

## LLM tests

Verify:

- explanations only use supplied evidence
- source/source_date are correctly represented
- `/ask` stays within context
- hallucinated facts are not introduced

## Flutter tests

Test:

- drag-and-drop
- result panel
- dashboard
- API integration
- rendering of evidence and retrieved cases

---

# 23. Phase 18 — Demo Scenarios

The end-to-end test plan specifies five core scenarios.

## Scenario 1

Drop a native ARM64 application.

Expected:

```text
Native
```

## Scenario 2

Drop a standard x64 application.

Expected:

```text
Likely Compatible
```

with Prism/emulation context where applicable.

## Scenario 3

Drop an application with known driver/anti-cheat indicators.

Expected:

```text
High Risk
```

with retrieved similar cases shown.

## Scenario 4

Ask:

```text
Why?
```

Expected:

A grounded explanation based on already displayed evidence.

## Scenario 5

Show the architecture pipeline.

Expected:

The demonstration clearly explains where deterministic analysis, retrieval, and local AI reasoning occur.

---

# 24. Phase 19 — QNN / Qualcomm AI Hub Integration

Only begin this phase after the CPU implementation is functionally complete.

Target pipeline:

```text
Embedding Model
       │
       ▼
ONNX Runtime
       │
       ▼
Qualcomm AI Engine Direct
       │
       ▼
Snapdragon Hexagon NPU
```

Target local reasoning model:

```text
Llama-v3.2-1B-Instruct
```

with the documented 3B model as a fallback/quality upgrade where appropriate.

The exact embedding model must be finalized against current Qualcomm AI Hub availability for the target.

Do not claim NPU performance until it has actually been validated.

---

# 25. Phase 20 — Qualcomm AI Hub Validation

Use Qualcomm AI Hub remote-hosted Snapdragon devices if physical target hardware is unavailable.

Validate:

- single-scan latency
- model throughput
- output quality
- CPU-vs-NPU functional equivalence
- target hardware compatibility

`TESTING.md` identifies the expected Llama-v3.2-1B-Instruct throughput range as approximately:

```text
34–37 tok/s
```

This must be treated as a validation target, not an assumed result.

---

# 26. Phase 21 — Production Backend Selection

After NPU validation:

```yaml
inference_backend: qnn
```

must become the shipped production configuration.

During development:

```yaml
inference_backend: cpu
```

remains appropriate.

The API contract must remain identical between CPU and QNN implementations.

---

# 27. Phase 22 — Packaging

Build Flutter:

```bash
cd ui
flutter build windows --release
```

Package the Python backend:

```bash
cd backend
pip install pyinstaller
pyinstaller --onefile main.py
```

Package:

```text
Flutter UI
+
Python backend
+
AI models
+
SQLite Knowledge Base
```

into the final Windows installer.

The documented deployment options include Inno Setup or MSIX.

---

# 28. Phase 23 — Privacy Verification

ARMWise's privacy architecture is a core product property.

Before release:

1. Disable network connectivity.
2. Run an executable scan.
3. Run retrieval.
4. Run local reasoning.
5. Confirm the scan works without network access.
6. Verify no executable, metadata, or derived evidence is uploaded.

`DEPLOYMENT.md` explicitly requires this validation.

---

# 29. Phase 24 — Release Validation

Before submission, verify every deployment checklist item:

```text
[ ] NPU validation completed
[ ] Production config uses qnn
[ ] Knowledge Base contains 50–100 target cases
[ ] No development-only paths remain
[ ] No debug endpoints remain enabled
[ ] Network-disabled scan works
[ ] Installer works on clean Windows 11 24H2+ Snapdragon hardware
```

If real Snapdragon hardware is unavailable for final installer testing, document that limitation rather than presenting the system as fully validated.

---

# 30. Development Milestones

Use the following milestones to control progress.

## M0 — Environment

```text
[ ] Repository structure
[ ] Python environment
[ ] Flutter Windows environment
[ ] Backend starts
[ ] Flutter starts
```

## M1 — Evidence Engine

```text
[ ] PE architecture
[ ] Publisher/signature
[ ] Imports/dependencies
[ ] Driver indicators
[ ] Anti-cheat indicators
[ ] Evidence object
```

## M2 — Database

```text
[ ] SQLite database
[ ] Schema
[ ] Seed script
[ ] 10–15 test cases
```

## M3 — Retrieval

```text
[ ] Embedding abstraction
[ ] Development embedding model
[ ] Embedding storage
[ ] Cosine similarity
[ ] Top-K retrieval
[ ] Insufficient evidence
```

## M4 — Classification

```text
[ ] Native
[ ] Likely Compatible
[ ] Uncertain
[ ] High Risk
```

## M5 — Reasoning

```text
[ ] CPU LLM backend
[ ] Prompt construction
[ ] Grounded explanation
[ ] /ask
[ ] Hallucination tests
```

## M6 — API

```text
[ ] /scan/exe
[ ] /scan/installed
[ ] /scan/store
[ ] /ask
[ ] /dashboard/summary
[ ] /dashboard/alternatives
```

## M7 — Flutter

```text
[ ] Drag/drop
[ ] Result screen
[ ] Evidence display
[ ] Retrieved cases
[ ] Explanation
[ ] Dashboard
[ ] Follow-up
[ ] Alternatives
```

## M8 — Integration

```text
[ ] Full CPU pipeline
[ ] End-to-end tests
[ ] Demo scenarios
```

## M9 — Snapdragon

```text
[ ] ONNX models
[ ] Qualcomm AI Hub
[ ] QNN backend
[ ] NPU validation
[ ] Performance validation
```

## M10 — Release

```text
[ ] Production config
[ ] Knowledge Base 50–100 cases
[ ] Installer
[ ] Privacy test
[ ] Clean-machine test
[ ] Final demo rehearsal
```

---

# 31. Recommended Build Order

The actual coding order should be:

```text
1. Repository + environment
        ↓
2. FastAPI skeleton
        ↓
3. Evidence Engine
        ↓
4. Evidence Engine tests
        ↓
5. SQLite + schema
        ↓
6. KB seed script
        ↓
7. Initial fixture KB
        ↓
8. Embedding abstraction
        ↓
9. Similarity retrieval
        ↓
10. Classification
        ↓
11. /scan/exe
        ↓
12. CPU reasoning backend
        ↓
13. /ask
        ↓
14. Installed-app scanning
        ↓
15. Store-app scanning
        ↓
16. Dashboard APIs
        ↓
17. Flutter result UI
        ↓
18. Flutter dashboard
        ↓
19. Full API/UI integration
        ↓
20. End-to-end testing
        ↓
21. Expand KB to 50–100 cases
        ↓
22. Qualcomm AI Hub / QNN
        ↓
23. NPU validation
        ↓
24. Packaging
        ↓
25. Clean-machine validation
        ↓
26. Final demo
```

---

# 32. Definition of Done

ARMWise is implementation-complete for MVP only when:

### Evidence

- `.exe` analysis produces deterministic evidence.
- Architecture detection works.
- Driver/anti-cheat detection is explicitly best-effort.
- Installed and Store scans function.

### Retrieval

- Knowledge Base is seeded.
- Embeddings are generated.
- Similarity retrieval works.
- Retrieved cases are inspectable and source-attributed.

### Reasoning

- Local LLM produces grounded explanations.
- `/ask` remains context-grounded.
- No unsupported confidence percentages are generated.

### UI

- User can drop an `.exe`.
- Results are understandable.
- Retrieved evidence is visible.
- Dashboard works.
- Follow-up questions work.

### Testing

- Evidence tests pass.
- Retrieval tests pass.
- Reasoning tests pass.
- UI tests pass.
- End-to-end demo scenarios pass.

### Deployment

- CPU development mode works.
- QNN/NPU validation is completed before claiming production NPU performance.
- Network-disabled operation is verified.
- Installer works on the target Windows/Snapdragon environment, or any remaining hardware validation gap is explicitly disclosed.

---

# 33. Change Management

Every meaningful implementation change should update the appropriate documentation.

Examples:

```text
API change
→ API.md

Architecture change
→ ARCHITECTURE.md

Database change
→ DATABASE.md

Setup/dependency change
→ SETUP.md

Testing change
→ TESTING.md

Packaging change
→ DEPLOYMENT.md

New limitation
→ LIMITATIONS.md

Completed feature / historical change
→ CHANGELOG.md

Overall implementation sequence
→ IMPLEMENTATION.md
```

Do not let implementation and documentation drift apart.

---

# 34. Core Engineering Rules

1. **Evidence before AI.**
2. **Never let the LLM become the source of deterministic facts.**
3. **Never fabricate compatibility evidence.**
4. **Use retrieval instead of training a large classifier for the MVP.**
5. **Show real similarity values.**
6. **Use `insufficient_evidence` when evidence is insufficient.**
7. **Keep the Knowledge Base source-attributed.**
8. **Keep CPU and QNN implementations behind the same inference interface.**
9. **Do not block development on Snapdragon hardware.**
10. **Do not claim NPU performance before validation.**
11. **Keep the system functional without network access.**
12. **Treat best-effort driver/anti-cheat detection as best-effort everywhere in the UI and documentation.**
13. **Do not expand MVP scope during implementation without updating the specifications.**
14. **Test each layer before moving to the next.**
15. **Prefer a working vertical slice over prematurely implementing every feature.**

---

# 35. First Working Vertical Slice

The first major coding objective should be deliberately small:

```text
User drops .exe
       ↓
Flutter
       ↓
POST /scan/exe
       ↓
Evidence Engine
       ↓
Architecture + metadata + imports
       ↓
Basic deterministic classification
       ↓
JSON response
       ↓
Flutter displays result
```

Only after this works should we introduce:

```text
Embedding
   ↓
Knowledge Base
   ↓
Similarity Retrieval
   ↓
LLM Explanation
```

This creates a stable foundation and lets every subsequent layer build on something demonstrably functional.

---

# 36. Current Starting Point

The project documentation currently describes ARMWise as:

```text
Draft — in development for challenge submission
```

and identifies the Evidence Engine, Knowledge Base, CPU inference backend, QNN backend, and Flutter UI as planned implementation work.

Therefore the next concrete action is:

**Start M0 → M1 and implement the FastAPI skeleton followed by the deterministic Evidence Engine.**

No NPU work is required at this stage.
