# Limitations

ARMWise's design principle is to disclose uncertainty rather than present false confidence. This file documents known limitations so they're never buried or forgotten under deadline pressure.

| Limitation | Mitigation |
|---|---|
| Static analysis can't reliably detect dynamically loaded anti-cheat or driver components installed post-setup | Labelled "best-effort detection" in every result; signature list is curated and versioned, not exhaustive |
| Knowledge Base coverage will be sparse relative to the full universe of Windows software | System returns "insufficient evidence" rather than a fabricated verdict — this is correct behavior, not a failure state |
| No physical Snapdragon device available during most of development | Qualcomm AI Hub's remote profiling used for model validation and performance benchmarking |
| Recommending an incorrect "safe" alternative would be worse than no recommendation | Alternatives restricted to apps with direct Knowledge Base evidence; the LLM never generates alternatives from its own knowledge |
| Overstating model confidence undermines trust and is easy to challenge | Similarity scores shown are real, computed cosine-similarity values; no invented aggregate "risk percentage" |

## Explicitly out of scope (MVP)

- A comprehensive, exhaustive application compatibility database
- Browser extension or companion for pre-purchase Store browsing
- Automatic installation or execution/testing of arbitrary software
- Any guarantee of compatibility outcomes — all output is advisory
- Exhaustive or guaranteed driver/anti-cheat detection
- A large, independently trained neural classifier (superseded by the retrieval-based approach)
- Cloud-hosted LLM inference of any kind
- Fabricated or uncalibrated compatibility confidence percentages
- Support for non-Windows operating systems
- `.msi` deep parsing (custom actions, embedded CAB extraction)
