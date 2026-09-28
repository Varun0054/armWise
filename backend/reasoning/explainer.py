"""
backend/reasoning/explainer.py

Explanation generator and follow-up Q&A.
- Uses llm_service.ask_grounded / generate_ai_explanation when OpenRouter is available.
- Falls back to deterministic template generation when OpenRouter is unavailable.
"""
import logging
from typing import Dict, Any, List, Tuple

from reasoning.llm_service import ask_grounded, generate_ai_explanation

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Deterministic fallback – no network, no LLM
# ---------------------------------------------------------------------------

def generate_explanation_fallback(
    application: str,
    evidence: Dict[str, Any],
    category: str,
    retrieved_cases: List[Dict[str, Any]],
    insufficient_evidence: bool,
) -> str:
    """Template-based explanation used when OpenRouter is unavailable."""
    arch = evidence.get("architecture", "Unknown")
    drivers = evidence.get("driver_indicators", False)
    anticheat = evidence.get("anti_cheat_indicators", False)

    parts = []

    if category == "Native":
        parts.append(
            f"'{application}' is built natively for Windows on ARM ({arch}). "
            "It will run directly on Snapdragon silicon without emulation overhead."
        )
    elif category == "High Risk":
        reasons = []
        if drivers:
            reasons.append(
                "kernel-mode driver indicators detected (best-effort) — "
                "Windows 11 on ARM cannot emulate x86/x64 kernel drivers"
            )
        if anticheat:
            reasons.append(
                "anti-cheat indicators detected (best-effort) — "
                "anti-cheat components commonly fail under x64 emulation"
            )
        if not reasons:
            reasons.append(
                "retrieved Knowledge Base cases indicate execution failures on ARM64"
            )
        parts.append(
            f"'{application}' is classified as High Risk. "
            "Detected risk factors: " + "; ".join(reasons) + "."
        )
    elif category == "Likely Compatible":
        parts.append(
            f"'{application}' is an {arch} executable. "
            "No kernel driver or anti-cheat indicators were detected by the current "
            "best-effort analysis. It is expected to operate through the Windows-on-ARM "
            "Prism emulation path."
        )
    else:  # Uncertain
        parts.append(
            f"'{application}' is an {arch} executable. "
            "Available evidence is insufficient to establish reliable compatibility. "
            "Windows Prism emulation may allow basic functionality, but limitations "
            "cannot be confirmed from the current analysis."
        )

    if retrieved_cases:
        summaries = [
            f"- {c.get('application')} ({c.get('observed_result')}): "
            f"{c.get('source')} ({c.get('source_date')})"
            for c in retrieved_cases
        ]
        parts.append("Similar cases from Knowledge Base:\n" + "\n".join(summaries))

    if insufficient_evidence and category == "Uncertain":
        parts.append(
            "Note: No sufficiently relevant Knowledge Base cases were retrieved. "
            "Assessment is based solely on PE binary indicators."
        )

    return "\n\n".join(parts)


def answer_followup_question_fallback(context: Dict[str, Any], question: str) -> str:
    """Deterministic keyword-based Q&A fallback."""
    app = context.get("application", "the scanned application")
    category = context.get("category", "Uncertain")
    evidence = context.get("evidence", {})
    retrieved = context.get("retrieved_cases", [])

    q_lower = question.lower()

    if "why" in q_lower or "reason" in q_lower or "high risk" in q_lower:
        if evidence.get("driver_indicators"):
            return (
                f"'{app}' is High Risk because kernel-mode driver indicators were "
                "detected (best-effort). Windows 11 on ARM cannot emulate x86/x64 "
                "kernel-mode drivers."
            )
        if evidence.get("anti_cheat_indicators"):
            return (
                f"'{app}' is High Risk because anti-cheat indicators were detected "
                "(best-effort). Anti-cheat components typically require kernel access "
                "that is not supported under ARM64 emulation."
            )
        if category == "Native":
            return (
                f"'{app}' has a native ARM64 PE header. "
                "It can execute directly on Qualcomm Oryon/Hexagon cores without emulation."
            )
        if category == "Likely Compatible":
            return (
                f"'{app}' contains standard x64 instructions. "
                "No high-risk indicators were detected by the current analysis. "
                "It is expected to run via Windows Prism emulation."
            )

    if any(k in q_lower for k in ("source", "where", "evidence", "knowledge base")):
        if retrieved:
            srcs = [
                f"{c['application']} → {c['source']} ({c['source_date']})"
                for c in retrieved
            ]
            return (
                f"The assessment for '{app}' draws on these Knowledge Base cases: "
                + "; ".join(srcs) + "."
            )
        return f"The assessment for '{app}' is based solely on static PE binary analysis."

    if "driver" in q_lower:
        detected = evidence.get("driver_indicators", False)
        return (
            f"Kernel driver indicators {'were' if detected else 'were not'} detected "
            f"in '{app}' by the current best-effort signature analysis. "
            "A negative result does not guarantee that no drivers exist."
        )

    if "anti" in q_lower or "cheat" in q_lower:
        detected = evidence.get("anti_cheat_indicators", False)
        return (
            f"Anti-cheat indicators {'were' if detected else 'were not'} detected "
            f"in '{app}' by the current best-effort signature analysis. "
            "A negative result does not guarantee that no anti-cheat component exists."
        )

    return (
        f"Based on the scanned evidence: application='{app}', "
        f"classification={category}, "
        f"architecture={evidence.get('architecture', 'unknown')}, "
        f"driver_indicators={evidence.get('driver_indicators', False)}, "
        f"anti_cheat_indicators={evidence.get('anti_cheat_indicators', False)}."
    )


# ---------------------------------------------------------------------------
# Public API used by scan.py
# ---------------------------------------------------------------------------

def generate_explanation(
    application: str,
    evidence: Dict[str, Any],
    category: str,
    retrieved_cases: List[Dict[str, Any]],
    insufficient_evidence: bool,
) -> str:
    """
    Generate the initial compatibility explanation for a scan result.
    Tries Nemotron first; falls back to deterministic template.
    """
    scan_result = {
        "application": application,
        "evidence": evidence,
        "category": category,
        "retrieved_cases": retrieved_cases,
        "insufficient_evidence": insufficient_evidence,
    }

    ai_text, source = generate_ai_explanation(scan_result)

    if source == "nemotron" and ai_text:
        # Append sourced KB cases for UI consistency
        appendix = _build_kb_appendix(retrieved_cases, insufficient_evidence, category)
        return ai_text + appendix

    # Deterministic fallback
    return generate_explanation_fallback(
        application, evidence, category, retrieved_cases, insufficient_evidence
    )


def answer_followup_question(context: Dict[str, Any], question: str) -> str:
    """
    Answer a follow-up question grounded in the current scan context.
    Returns (answer_text, answer_source) in a backward-compatible way.
    The returned string is just the answer – source is tracked in scan.py.
    """
    ai_text, source = ask_grounded(context, question)

    if source == "nemotron" and ai_text:
        return ai_text

    if source == "invalid_question":
        return ai_text  # friendly clarification message

    # Deterministic fallback
    return answer_followup_question_fallback(context, question)


def answer_followup_question_with_source(
    context: Dict[str, Any], question: str
) -> Tuple[str, str]:
    """
    Same as answer_followup_question but also returns the answer source string.
    Used by the /ask endpoint to populate answer_source in the response.
    """
    ai_text, source = ask_grounded(context, question)

    if source == "nemotron" and ai_text:
        return ai_text, "nemotron"

    if source == "invalid_question":
        return ai_text, "invalid_question"

    return answer_followup_question_fallback(context, question), "deterministic_fallback"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _build_kb_appendix(
    retrieved_cases: List[Dict[str, Any]],
    insufficient_evidence: bool,
    category: str,
) -> str:
    parts = []
    if retrieved_cases:
        summaries = [
            f"- {c.get('application')} ({c.get('observed_result')}): "
            f"{c.get('source')} ({c.get('source_date')})"
            for c in retrieved_cases
        ]
        parts.append("\n\nSimilar cases from Knowledge Base:\n" + "\n".join(summaries))
    if insufficient_evidence and category == "Uncertain":
        parts.append(
            "\n\nNote: No sufficiently relevant Knowledge Base cases were retrieved. "
            "Assessment is based solely on PE binary indicators."
        )
    return "".join(parts)
