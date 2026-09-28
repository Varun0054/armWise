import pefile
from typing import Dict, Any, List

IMAGE_FILE_MACHINE_I386 = 0x014C
IMAGE_FILE_MACHINE_AMD64 = 0x8664
IMAGE_FILE_MACHINE_ARM64 = 0xAA64
IMAGE_FILE_MACHINE_ARM64EC = 0xA641

def parse_pe(file_bytes: bytes) -> Dict[str, Any]:
    try:
        pe = pefile.PE(data=file_bytes)
    except Exception as e:
        return {
            "valid_pe": False,
            "error": f"Invalid PE file: {str(e)}",
            "architecture": "unknown",
            "native_arm64": False,
            "imports": [],
            "dependency_count": 0,
            "has_signature": False,
            "publisher": "Unknown"
        }

    machine = pe.FILE_HEADER.Machine
    arch = "unknown"
    native_arm64 = False

    if machine == IMAGE_FILE_MACHINE_ARM64:
        arch = "ARM64"
        native_arm64 = True
    elif machine == IMAGE_FILE_MACHINE_ARM64EC:
        arch = "ARM64EC"
        native_arm64 = True
    elif machine == IMAGE_FILE_MACHINE_AMD64:
        arch = "x64"
        native_arm64 = False
    elif machine == IMAGE_FILE_MACHINE_I386:
        arch = "x86"
        native_arm64 = False
    else:
        arch = f"0x{machine:04x}"

    # Extract imports
    imports: List[str] = []
    if hasattr(pe, 'DIRECTORY_ENTRY_IMPORT'):
        for entry in pe.DIRECTORY_ENTRY_IMPORT:
            try:
                dll_name = entry.dll.decode('utf-8', errors='ignore').lower()
                imports.append(dll_name)
            except Exception:
                pass

    # Signature directory check (Security Directory)
    has_signature = False
    if hasattr(pe, 'OPTIONAL_HEADER') and hasattr(pe.OPTIONAL_HEADER, 'DATA_DIRECTORY'):
        if len(pe.OPTIONAL_HEADER.DATA_DIRECTORY) > 4:
            security_dir = pe.OPTIONAL_HEADER.DATA_DIRECTORY[4]
            if security_dir.VirtualAddress != 0 and security_dir.Size != 0:
                has_signature = True

    pe.close()

    return {
        "valid_pe": True,
        "error": None,
        "architecture": arch,
        "native_arm64": native_arm64,
        "imports": imports,
        "dependency_count": len(imports),
        "has_signature": has_signature,
        "publisher": "Verified Publisher" if has_signature else "Unknown / Unsigned"
    }
