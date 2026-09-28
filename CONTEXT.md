# ARMWise Project Context & AI Continuity Guide (`CONTEXT.md`)

## 1. Project Overview & Mission
**ARMWise** is an on-device Windows-on-ARM compatibility advisor tailored for Snapdragon-powered PCs (Copilot+ PCs / Snapdragon X Elite/Plus).

### Key Architectural Constraint
* **Deterministic Fact Engine**: Technical PE binary evidence (Architecture, Driver signatures, Anti-Cheat imports) is derived strictly deterministically using Python PE parsers (`pefile`).
* **Zero-Cloud & Grounded AI**: AI model layers are strictly used for searching vector-embedded historical cases, producing natural language explanations, and context-bound Q&A. The AI **never** guesses hardware/binary facts.

---

## 2. Directory Structure & Architecture

```
Armwire/
├── backend/                  # FastAPI Python Service (Port 8000)
│   ├── api/
│   │   └── scan.py           # REST endpoints (/scan/exe, /scan/installed, /scan/store, /ask, /dashboard/*)
│   ├── database/
│   │   └── db.py             # SQLite DB initialization & vector storage
│   ├── evidence/             # Deterministic logic (NO LLM)
│   │   ├── engine.py         # Primary evidence aggregator
│   │   ├── pe_parser.py      # PE machine headers, DLL dependencies
│   │   ├── drivers.py        # Kernel-mode driver detection
│   │   └── anticheat.py      # Known anti-cheat binary signatures
│   ├── reasoning/
│   │   ├── classifier.py     # Rule-based categorization (Native, Likely Compatible, Uncertain, High Risk)
│   │   └── explainer.py      # Local LLM explanation generator
│   ├── retrieval/
│   │   ├── embedder.py       # all-MiniLM-L6-v2 vector generator
│   │   └── similarity.py     # Cosine similarity matching over SQLite BLOB embeddings
│   ├── data/
│   │   └── kb_seed.json      # Sourced seed cases (12 initial verified compatibility cases)
│   ├── tests/                # 14 Pytest integration/unit tests
│   ├── main.py               # Application entry point & startup lifespan
│   └── requirements.txt
│
├── ui/                       # Flutter Desktop / Web Application
│   ├── lib/
│   │   ├── main.dart         # Entry point, App Shell, Tab Navigation, Backend Health indicator
│   │   ├── screens/
│   │   │   ├── exe_scan_screen.dart       # Drag-and-drop .exe scanning + follow-up Q&A
│   │   │   ├── installed_apps_screen.dart # Windows Registry bulk scanner
│   │   │   └── dashboard_screen.dart      # Summary metrics, native alternatives, pipeline visualizer
│   │   ├── services/
│   │   │   └── api_service.dart           # HTTP Client for FastAPI backend
│   │   ├── theme/
│   │   │   └── app_theme.dart             # Dark glassmorphic design system
│   │   └── widgets/
│   │       └── components.dart            # Shared metric cards, badges, and layout widgets
│   ├── pubspec.yaml
│   └── index.html            # Web entry fallback
│
└── Mds/                      # Project Specifications & Milestone Tracking
    ├── PRD.md
    ├── IMPLEMENTATION.md
    ├── API.md
    ├── DATABASE.md
    └── STATUS.md
```

---

## 3. Milestones Status (M0 - M8)

| Milestone | Description | Status | Verification |
|---|---|---|---|
| **M0** | Requirements & Specs | ✅ Completed | PRD.md, API.md, DATABASE.md updated |
| **M1** | Deterministic Evidence Engine | ✅ Completed | `backend/evidence/` verified against sample PEs |
| **M2** | Knowledge Base & Embeddings | ✅ Completed | SQLite populated with 12 seed cases + 384-dim BLOB vectors |
| **M3** | Classification & Reasoning | ✅ Completed | Rule engine + grounded explanation generator tested |
| **M4** | FastAPI Endpoints | ✅ Completed | All endpoints operational |
| **M5** | Grounded Q&A | ✅ Completed | `/ask` endpoint tested with context binding |
| **M6** | Automated Testing | ✅ Completed | 14/14 tests passing (`pytest`) |
| **M7** | Flutter UI Implementation | ✅ Completed | Web preview running; Flutter UI connected to backend |
| **M8** | End-to-End Verification | ✅ Completed | Full pipeline operational |

---

## 4. Environment & How to Run

### Environment Paths
* **Python**: System Python with dependencies installed (`fastapi`, `uvicorn`, `pefile`, `numpy`, `pytest`, `sentence-transformers`).
* **Flutter SDK**: `C:\develope\flutter_windows_3.38.5-stable\flutter\bin\flutter.bat`

### 1. Launching Backend (Port 8000)
```powershell
cd c:\Users\Yashika\Desktop\Armwire\backend
python main.py
```

### 2. Launching Flutter UI (Web / Edge Preview)
```powershell
cd c:\Users\Yashika\Desktop\Armwire\ui
C:\develope\flutter_windows_3.38.5-stable\flutter\bin\flutter.bat run -d edge --web-port 3000
```

### 3. Launching Native Windows Desktop App (.exe)
*Requires Visual Studio 2022 / Build Tools with "Desktop development with C++" workload installed.*
```powershell
cd c:\Users\Yashika\Desktop\Armwire\ui
C:\develope\flutter_windows_3.38.5-stable\flutter\bin\flutter.bat run -d windows
```

### 4. Running Backend Tests
```powershell
cd c:\Users\Yashika\Desktop\Armwire\backend
pytest
```

---

## 5. Next Steps / Hand-off for AI Models
1. **Visual Studio C++ Build Tools**: Once the user installs the Visual Studio C++ toolchain, build the native Windows `.exe` bundle using `flutter run -d windows` or `flutter build windows`.
2. **Additional PE Samples**: Expand the seed database `backend/data/kb_seed.json` with real-world Windows-on-ARM application compatibility reports.
3. **Hardware NPU Integration (M9)**: Profile local embedder performance on Snapdragon NPU via Qualcomm AI Hub when NPU hardware or Qualcomm AI Hub API key becomes available.
