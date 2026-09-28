from typing import Dict, Any, List, Tuple

def classify_compatibility(evidence: Dict[str, Any], retrieved_cases: List[Dict[str, Any]]) -> Tuple[str, bool]:
    """
    Returns (category, insufficient_evidence)
    Categories: 'Native', 'Likely Compatible', 'Uncertain', 'High Risk'
    """
    # Rule 1: Native architecture check
    if evidence.get("native_arm64") or evidence.get("architecture") in ("ARM64", "ARM64EC"):
        return "Native", False

    # Rule 2: High Risk indicators (kernel driver or anti-cheat)
    if evidence.get("driver_indicators") or evidence.get("anti_cheat_indicators"):
        return "High Risk", False

    # Check retrieved cases
    if not retrieved_cases:
        return "Uncertain", True

    failing_cases = [c for c in retrieved_cases if c.get("observed_result") == "fails"]
    working_cases = [c for c in retrieved_cases if c.get("observed_result") in ("works", "works_with_limitations")]

    if len(failing_cases) > len(working_cases):
        return "High Risk", False

    if len(working_cases) > 0:
        return "Likely Compatible", False

    return "Uncertain", True
