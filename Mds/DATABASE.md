# Database

## Storage

SQLite, single file (`data/armwise.db`). No server process required — fits the on-device, zero-dependency design principle.

## Compatibility Knowledge Base schema

Each record is one sourced, verifiable compatibility observation. All fields mandatory unless noted.

| Field | Type | Description |
|---|---|---|
| `application` | string | Application name |
| `architecture` | enum | `x86` / `x64` / `ARM64` / `ARM64EC` |
| `native_arm64` | boolean | Whether a native ARM64 build exists |
| `driver_indicators` | boolean | Kernel-level driver dependency detected |
| `anti_cheat_indicators` | boolean | Anti-cheat component detected |
| `category` | string | e.g. Game, Utility, Creative, Security |
| `observed_result` | enum | `works` / `works_with_limitations` / `fails` / `unknown` |
| `source` | string | Origin of the observation (report type, publication) |
| `source_date` | string | `YYYY-MM`, for recency assessment |
| `embedding` | blob | Precomputed vector embedding of this record, for similarity search |

## Suggested table

```sql
CREATE TABLE compatibility_cases (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    application TEXT NOT NULL,
    architecture TEXT NOT NULL CHECK(architecture IN ('x86','x64','ARM64','ARM64EC')),
    native_arm64 BOOLEAN NOT NULL,
    driver_indicators BOOLEAN NOT NULL,
    anti_cheat_indicators BOOLEAN NOT NULL,
    category TEXT NOT NULL,
    observed_result TEXT NOT NULL CHECK(observed_result IN ('works','works_with_limitations','fails','unknown')),
    source TEXT NOT NULL,
    source_date TEXT NOT NULL,
    embedding BLOB NOT NULL
);
```

## Evidence object (runtime, not persisted per-scan by default)

Produced by the Evidence Engine for the application currently being analyzed — see [`ARCHITECTURE.md`](ARCHITECTURE.md) for the full shape. Optionally logged to a local `scan_history` table if you want scan history in the UI; not required for MVP.

## Vector search

At the MVP target size (50–100 records), a dedicated vector database is unnecessary overhead. Store each record's embedding as a BLOB and compute cosine similarity in Python (`numpy`) at query time against all records — this is fast enough at this scale and keeps the dependency list minimal. Revisit only if the Knowledge Base grows well beyond MVP scope.

## Sourcing plan

- Publicly documented compatibility reports and community-maintained trackers
- Technical press coverage of Snapdragon X Elite application/game compatibility
- Microsoft's Windows-on-Arm compatibility and driver documentation
- First-party verification via Qualcomm AI Hub's remote-hosted Snapdragon devices, where feasible

Target for MVP: 50–100 verified, source-attributed cases. This is a critical-path deliverable — the retrieval and reasoning layers have nothing to work from until this dataset reaches a usable size.

## Seeding

```bash
python scripts/seed_kb.py --source data/kb_seed.json
```

`kb_seed.json` should be a JSON array of objects matching the schema above (minus `embedding`, which the seed script computes and stores).
