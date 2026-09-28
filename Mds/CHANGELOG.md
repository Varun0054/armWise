# Changelog

All notable changes to ARMWise will be documented here.

## [0.1.0] - 2026-09-22

### Added
- **Backend Foundation (M0)**: Configured FastAPI application server in [main.py](file:///c:/Users/Yashika/Desktop/Armwire/backend/main.py) with CORS middleware, lifespan events, and `/health` status endpoint.
- **Evidence Engine (M1)**: Added PE header inspection ([pe_parser.py](file:///c:/Users/Yashika/Desktop/Armwire/backend/evidence/pe_parser.py)) for architecture detection (`ARM64`, `ARM64EC`, `x64`, `x86`), publisher signature check, and dependency DLL analysis.
- **Driver & Anti-Cheat Detectors (M1)**: Added signature matching for kernel drivers ([drivers.py](file:///c:/Users/Yashika/Desktop/Armwire/backend/evidence/drivers.py)) and anti-cheat engines ([anticheat.py](file:///c:/Users/Yashika/Desktop/Armwire/backend/evidence/anticheat.py)).
- **Database & Knowledge Base (M2)**: Created SQLite schema ([db.py](file:///c:/Users/Yashika/Desktop/Armwire/backend/database/db.py)), initial 12-case seed dataset ([kb_seed.json](file:///c:/Users/Yashika/Desktop/Armwire/backend/data/kb_seed.json)), and vector seeding script ([seed_kb.py](file:///c:/Users/Yashika/Desktop/Armwire/backend/scripts/seed_kb.py)).
- **Embedding & Similarity Retrieval (M3)**: Implemented vector embedding pipeline ([embedder.py](file:///c:/Users/Yashika/Desktop/Armwire/backend/retrieval/embedder.py)) and NumPy cosine similarity top-K search ([similarity.py](file:///c:/Users/Yashika/Desktop/Armwire/backend/retrieval/similarity.py)).
- **Classification & Reasoning (M4, M5)**: Implemented deterministic 4-way classification ([classifier.py](file:///c:/Users/Yashika/Desktop/Armwire/backend/reasoning/classifier.py)) and grounded explanation generator with follow-up QA handler ([explainer.py](file:///c:/Users/Yashika/Desktop/Armwire/backend/reasoning/explainer.py)).
- **API Endpoints (M6)**: Implemented `/scan/exe`, `/scan/installed`, `/scan/store`, `/ask`, `/dashboard/summary`, and `/dashboard/alternatives/{app}` in [scan.py](file:///c:/Users/Yashika/Desktop/Armwire/backend/api/scan.py).
- **Test Suite**: Added unit and integration tests ([test_evidence.py](file:///c:/Users/Yashika/Desktop/Armwire/backend/tests/test_evidence.py), [test_api.py](file:///c:/Users/Yashika/Desktop/Armwire/backend/tests/test_api.py)) with 100% test pass rate.
