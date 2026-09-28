from typing import List, Dict, Any

KNOWN_DRIVER_DLLS = {
    "ntoskrnl.exe",
    "wdfldr.sys",
    "hal.dll",
    "fltlib.dll",
    "storport.sys",
    "ndis.sys"
}

def detect_driver_indicators(imports: List[str], raw_bytes: bytes = b"") -> Dict[str, Any]:
    found_driver_dlls = [dll for dll in imports if dll.lower() in KNOWN_DRIVER_DLLS or dll.lower().endswith(".sys")]
    
    # Simple binary string search for driver signatures if raw_bytes supplied
    sys_reference = False
    if raw_bytes:
        if b".sys" in raw_bytes.lower() or b"driverentry" in raw_bytes.lower():
            sys_reference = True

    detected = len(found_driver_dlls) > 0 or sys_reference

    return {
        "driver_indicators": detected,
        "matched_indicators": found_driver_dlls,
        "detection_confidence": "best-effort"
    }
