# Testing

## Strategy overview

Testing is split by which components are hardware-independent versus NPU-dependent, since most development happens away from target hardware.

## 1. Evidence Engine — unit tests (fully local, no special hardware)

- Feed known `.exe` files with known architecture/signature/dependency profiles; assert the output evidence object matches expectations.
- Cover: native ARM64 binary, x64 binary, unsigned binary, binary with known driver-signature match, binary with known anti-cheat–signature match.
- Test Registry enumeration and `Get-AppxPackage` parsing against a small set of real installed apps on the dev machine.
- These tests should be fast and run on every commit (no NPU, no network).

## 2. Knowledge Base & retrieval — unit + integration tests (local)

- Seed a small fixture Knowledge Base (10–15 records) with known similarity relationships.
- Assert that retrieval returns the expected top-k cases in the expected order for known evidence inputs.
- Assert `insufficient_evidence` is returned (not a fabricated category) when no comparable case exists in the fixture set.
- Run with `inference_backend: cpu` (`all-MiniLM-L6-v2`) — these tests validate retrieval *logic*, not NPU performance.

## 3. LLM reasoning — prompt/output tests (local, CPU stub)

- Assert the LLM only references evidence and cases actually present in the prompt (spot-check for hallucinated facts).
- Assert explanations correctly cite category, evidence fields, and source/source_date for retrieved cases (FR-9).
- Assert follow-up questions (`/ask`) stay grounded in the context provided, not general knowledge.
- These are functional/correctness tests using the CPU-stub model — they validate the reasoning *pipeline*, not final NPU throughput or output quality at production scale.

## 4. NPU validation — via Qualcomm AI Hub remote profiling

Cannot be done on non-Snapdragon dev hardware. Before each milestone/demo rehearsal:

- Upload the finalized embedding and LLM ONNX models to Qualcomm AI Hub.
- Run against remote-hosted Snapdragon X Elite / X2 devices.
- Validate:
  - NFR-2: single scan (evidence + retrieval + explanation) completes within a few seconds
  - Output quality matches what was validated with the CPU stub (same prompts, compare outputs)
  - Reported throughput matches SRS expectations (~34–37 tok/s for Llama-v3.2-1B-Instruct)

## 5. UI tests (Flutter, local)

- Widget tests for the drag-and-drop zone, result panel, and dashboard summary view.
- Integration test: drop a known `.exe` fixture → assert the result panel renders the expected category, evidence fields, and retrieved cases.

## 6. End-to-end demo rehearsal

Map directly to the SRS demonstration plan (Section 11) — rehearse each scene as a manual/scripted test before presenting:

| Scene | Scenario | Expected result |
|---|---|---|
| 1 | Drag a native ARM64 app | `Native`, no emulation required |
| 2 | Drag a standard x64 app | `Likely Compatible`, Prism emulation noted |
| 3 | Drag an app with known driver/anti-cheat indicators | `High Risk`, retrieved similar cases shown |
| 4 | Ask a free-form follow-up ("Why?") | LLM answers grounded in evidence already shown |
| 5 | Show the architecture pipeline diagram | Confirms "where is the AI?" is answerable |

## What NOT to test on the CPU stub

Don't treat CPU-stub latency or the small quantized model's output quality as representative of the final product — it exists only to validate logic and wiring. Reserve any performance or quality claims for AI-Hub-validated results.
