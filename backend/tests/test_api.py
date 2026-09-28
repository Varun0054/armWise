import pytest
from fastapi.testclient import TestClient
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from main import app

client = TestClient(app)

def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    json_data = response.json()
    assert json_data["status"] == "ok"

def test_scan_exe_endpoint():
    # Send mock executable bytes
    files = {"file": ("test_app.exe", b"MZDummyPEData", "application/octet-stream")}
    response = client.post("/scan/exe", files=files)
    assert response.status_code == 200
    json_data = response.json()
    assert "application" in json_data
    assert "evidence" in json_data
    assert "category" in json_data
    assert "explanation" in json_data

def test_dashboard_summary():
    response = client.get("/dashboard/summary")
    assert response.status_code == 200
    json_data = response.json()
    assert "total" in json_data

def test_ask_endpoint():
    response = client.post("/ask", json={"context_id": "test_app.exe", "question": "Why?"})
    assert response.status_code == 200
    json_data = response.json()
    assert "answer" in json_data
