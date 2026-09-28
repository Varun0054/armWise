# Product Requirements Document (PRD)

## Product

ARMWise — an on-device Windows-on-ARM compatibility advisor for Snapdragon®-powered HP PCs.

## Problem

Snapdragon-powered Windows-on-ARM laptops run Windows 11 on ARM64 silicon instead of x86/x64. Microsoft's Prism emulation layer lets many x86/x64 apps run, but compatibility isn't guaranteed and falls into distinct outcomes: runs natively, runs under emulation, runs with limitations, or fails outright (most often due to kernel-mode drivers or anti-cheat, which Windows can't emulate).

There's currently no reliable way to know, before installing a specific app, which outcome to expect. Microsoft doesn't maintain a comprehensive compatibility list; what exists is fragmented across developer docs, community trackers, and forum reports — sparse, inconsistently labelled, hard to search. This is the most-repeated complaint in user reports about Snapdragon Windows PCs.

**Guiding question:** *"Before I install this application, how likely is it to work properly on my Snapdragon Windows PC, and why?"*

## Goals

- Give users an evidence-based compatibility assessment before installing software
- Ground every AI-generated explanation in retrieved, sourced evidence — never the model's unverified internal knowledge
- Run the entire pipeline on-device, NPU-accelerated, zero cloud dependency, zero telemetry
- Explicitly communicate uncertainty rather than presenting fabricated confidence
- Demonstrate a genuine, defensible use of on-device AI for the Snapdragon AI Lab Build & Present Challenge

## Non-goals (MVP)

- An exhaustive compatibility database covering tens of thousands of apps
- Guaranteeing compatibility outcomes — all output is advisory
- Automatically installing or executing arbitrary software
- Cloud-hosted inference of any kind

## Target users

| Segment | Need |
|---|---|
| Students/professionals considering or owning a Snapdragon PC | Verify existing software toolchain before switching |
| IT administrators | Assess compatibility risk across a standard software image before fleet deployment |
| Developers/enthusiasts | Curiosity about ARM64/emulation status of specific apps |

## User stories

- As a user, I can drag an `.exe` onto ARMWise and get a compatibility category with evidence and an explanation, so I know what to expect before installing.
- As a user, I can run a bulk scan of my installed apps and see a dashboard of how many are Native / Likely Compatible / Uncertain / High Risk.
- As a user, I can ask a free-form follow-up question about a result ("Why does this fail?") and get an answer grounded in the evidence already shown.
- As a user, when ARMWise doesn't have enough evidence, I'm told that plainly rather than given a guess dressed up as a percentage.
- As a user, I can see where a piece of evidence or a similar case came from (source + date), so I can judge its credibility myself.

## Success metrics (for the challenge submission)

- Live demo completes all five scenes (native / emulated / high-risk / ask-follow-up / architecture reveal) without falling back to a cloud call or a fabricated result
- A single scan completes within a few seconds on NPU hardware (NFR-2)
- Knowledge Base reaches 50–100 verified, source-attributed cases before the demo
- Every AI statement in the demo is traceable to evidence visible on screen (NFR-3)

## Requirements

Full functional (FR-1–FR-11) and non-functional (NFR-1–NFR-6) requirements, and the four-way compatibility classification logic, are specified in the SRS — see the uploaded `ARMWise_SRS.pdf` and [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the condensed version.

## Risks

See [`docs/LIMITATIONS.md`](docs/LIMITATIONS.md) for the full risk/mitigation table (static-analysis blind spots, sparse Knowledge Base coverage, no local Snapdragon hardware during dev, etc.).

## Open questions

- Final embedding model choice — pending confirmation of current Qualcomm AI Hub text-embedding model availability for Windows/ARM64
- Whether Llama-v3.2-1B-Instruct's response quality is sufficient, or whether the 3B fallback is needed for the demo
- Installer format (Inno Setup vs. MSIX) — see [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md)
