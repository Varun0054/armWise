from typing import Dict, Any
from .pe_parser import parse_pe
from .drivers import detect_driver_indicators
from .anticheat import detect_anticheat_indicators

def analyze_executable(file_name: str, file_bytes: bytes) -> Dict[str, Any]:
    pe_result = parse_pe(file_bytes)
    driver_result = detect_driver_indicators(pe_result.get("imports", []), file_bytes)
    anticheat_result = detect_anticheat_indicators(file_name, pe_result.get("imports", []), file_bytes)

    evidence = {
        "application": file_name,
        "valid_pe": pe_result["valid_pe"],
        "architecture": pe_result["architecture"],
        "native_arm64": pe_result["native_arm64"],
        "has_signature": pe_result["has_signature"],
        "publisher": pe_result["publisher"],
        "dependency_count": pe_result["dependency_count"],
        "imports": pe_result["imports"],
        "driver_indicators": driver_result["driver_indicators"],
        "driver_details": driver_result["matched_indicators"],
        "anti_cheat_indicators": anticheat_result["anti_cheat_indicators"],
        "anti_cheat_details": anticheat_result["matched_patterns"],
        "detection_confidence": "best-effort"
    }

    return evidence
