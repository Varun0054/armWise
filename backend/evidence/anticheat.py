from typing import List, Dict, Any

KNOWN_ANTICHEAT_PATTERNS = [
    "easyanticheat",
    "eac_",
    "battleye",
    "beclient",
    "beservice",
    "vanguard",
    "vgk",
    "ricochet",
    "gameguard",
    "nprotect",
    "xigncode",
    "equ8",
    "denuvo"
]

def detect_anticheat_indicators(file_name: str, imports: List[str], raw_bytes: bytes = b"") -> Dict[str, Any]:
    matched = []
    file_name_lower = file_name.lower()

    for pattern in KNOWN_ANTICHEAT_PATTERNS:
        if pattern in file_name_lower:
            matched.append(f"Filename pattern: {pattern}")
        for imp in imports:
            if pattern in imp.lower():
                matched.append(f"Import pattern: {pattern} in {imp}")

    if raw_bytes and not matched:
        lower_bytes = raw_bytes.lower()
        for pattern in KNOWN_ANTICHEAT_PATTERNS:
            if pattern.encode("ascii") in lower_bytes:
                matched.append(f"Binary string match: {pattern}")
                break

    detected = len(matched) > 0

    return {
        "anti_cheat_indicators": detected,
        "matched_patterns": matched,
        "detection_confidence": "best-effort"
    }
