import pytest
from fastapi.testclient import TestClient
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from main import app

client = TestClient(app)

def test_scenario_1_native_arm64():
    """Scenario 1: Drop a native ARM64 application -> Expect Native category."""
    # PE Header stub with ARM64 machine code 0xAA64
    # MZ header (2 bytes) + offset 0x3C to PE signature + PE signature + File Header (Machine=0xAA64)
    pe_header = bytearray(512)
    pe_header[0:2] = b"MZ"
    pe_header[0x3C:0x40] = (0x80).to_bytes(4, byteorder="little") # PE header offset at 0x80
    pe_header[0x80:0x84] = b"PE\x00\x00"
    pe_header[0x84:0x86] = (0xAA64).to_bytes(2, byteorder="little") # Machine ARM64

    files = {"file": ("native_tool.exe", bytes(pe_header), "application/octet-stream")}
    response = client.post("/scan/exe", files=files)
    assert response.status_code == 200
    data = response.json()
    assert data["category"] == "Native"
    assert data["evidence"]["native_arm64"] is True

def test_scenario_2_likely_compatible_x64():
    """Scenario 2: Drop a standard x64 application -> Expect Likely Compatible category."""
    pe_header = bytearray(512)
    pe_header[0:2] = b"MZ"
    pe_header[0x3C:0x40] = (0x80).to_bytes(4, byteorder="little")
    pe_header[0x80:0x84] = b"PE\x00\x00"
    pe_header[0x84:0x86] = (0x8664).to_bytes(2, byteorder="little") # Machine x64

    files = {"file": ("utility_app.exe", bytes(pe_header), "application/octet-stream")}
    response = client.post("/scan/exe", files=files)
    assert response.status_code == 200
    data = response.json()
    assert data["category"] in ("Likely Compatible", "Uncertain")
    assert data["evidence"]["driver_indicators"] is False

def test_scenario_3_high_risk_driver():
    """Scenario 3: Drop executable with kernel driver / anti-cheat -> Expect High Risk category."""
    files = {"file": ("EasyAntiCheat_x64.exe", b"MZDummyDataEasyAntiCheat", "application/octet-stream")}
    response = client.post("/scan/exe", files=files)
    assert response.status_code == 200
    data = response.json()
    assert data["category"] == "High Risk"
    assert data["evidence"]["anti_cheat_indicators"] is True

def test_scenario_4_ask_followup():
    """Scenario 4: Ask free-form follow-up question -> Expect grounded answer."""
    # First scan
    files = {"file": ("EasyAntiCheat_x64.exe", b"MZDummyDataEasyAntiCheat", "application/octet-stream")}
    scan_resp = client.post("/scan/exe", files=files).json()
    
    ask_resp = client.post("/ask", json={"context_id": "EasyAntiCheat_x64.exe", "question": "Why does this fail?"})
    assert ask_resp.status_code == 200
    answer = ask_resp.json()["answer"]
    assert "anti-cheat" in answer.lower() or "driver" in answer.lower() or "scanned" in answer.lower()

def test_scenario_5_dashboard_summary():
    """Scenario 5: Dashboard summary & system metrics."""
    response = client.get("/dashboard/summary")
    assert response.status_code == 200
    data = response.json()
    assert "native" in data
    assert "high_risk" in data
    assert "total" in data
