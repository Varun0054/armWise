import pytest
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from evidence.pe_parser import parse_pe
from evidence.drivers import detect_driver_indicators
from evidence.anticheat import detect_anticheat_indicators
from evidence.engine import analyze_executable
from reasoning.classifier import classify_compatibility

def test_invalid_pe():
    result = parse_pe(b"NOT_A_VALID_PE_HEADER")
    assert result["valid_pe"] is False
    assert result["architecture"] == "unknown"

def test_driver_detection():
    driver_res = detect_driver_indicators(["ntoskrnl.exe", "kernel32.dll"])
    assert driver_res["driver_indicators"] is True
    assert "ntoskrnl.exe" in driver_res["matched_indicators"]

def test_anticheat_detection():
    ac_res = detect_anticheat_indicators("EasyAntiCheat_x64.exe", ["kernel32.dll"])
    assert ac_res["anti_cheat_indicators"] is True

def test_classifier_native():
    evidence = {"native_arm64": True, "architecture": "ARM64", "driver_indicators": False, "anti_cheat_indicators": False}
    category, insufficient = classify_compatibility(evidence, [])
    assert category == "Native"
    assert insufficient is False

def test_classifier_high_risk_driver():
    evidence = {"native_arm64": False, "architecture": "x64", "driver_indicators": True, "anti_cheat_indicators": False}
    category, insufficient = classify_compatibility(evidence, [])
    assert category == "High Risk"
    assert insufficient is False
