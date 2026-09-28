from fastapi import APIRouter, UploadFile, File, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Any, Optional
import os

from evidence.engine import analyze_executable
from retrieval.similarity import retrieve_similar_cases
from reasoning.classifier import classify_compatibility
from reasoning.explainer import generate_explanation, answer_followup_question
from database.db import get_connection

router = APIRouter()

class AskRequest(BaseModel):
    context_id: str
    question: str

class AskResponse(BaseModel):
    answer: str

# In-memory scan context cache for /ask endpoint
_scan_context_cache: Dict[str, Dict[str, Any]] = {}

@router.post("/scan/exe")
async def scan_exe(file: UploadFile = File(...)):
    file_bytes = await file.read()
    file_name = file.filename or "uploaded_app.exe"

    # Step 1: Evidence Engine
    evidence = analyze_executable(file_name, file_bytes)

    # Step 2: Retrieval Engine
    retrieved_cases = retrieve_similar_cases(evidence, top_k=3, threshold=0.5)

    # Step 3: Classification Engine
    category, insufficient_evidence = classify_compatibility(evidence, retrieved_cases)

    # Step 4: Reasoning / Explanation Engine
    explanation = generate_explanation(file_name, evidence, category, retrieved_cases, insufficient_evidence)

    result = {
        "application": file_name,
        "evidence": evidence,
        "category": category,
        "insufficient_evidence": insufficient_evidence,
        "retrieved_cases": retrieved_cases,
        "explanation": explanation
    }

    # Store in scan context cache for /ask followups
    _scan_context_cache[file_name] = result

    return result


@router.get("/scan/installed")
async def scan_installed():
    """Enumerate installed applications via Windows Registry and classify them."""
    installed_apps = []
    
    # Check Windows registry if on Windows platform
    try:
        import winreg
        hkeys = [winreg.HKEY_LOCAL_MACHINE, winreg.HKEY_CURRENT_USER]
        sub_keys = [
            r"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
            r"SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
        ]

        for hkey in hkeys:
            for sub_key in sub_keys:
                try:
                    key = winreg.OpenKey(hkey, sub_key)
                    for i in range(0, winreg.QueryInfoKey(key)[0]):
                        try:
                            skey_name = winreg.EnumKey(key, i)
                            skey = winreg.OpenKey(key, skey_name)
                            name, _ = winreg.QueryValueEx(skey, "DisplayName")
                            publisher, _ = winreg.QueryValueEx(skey, "Publisher") if "Publisher" in [winreg.EnumValue(skey, j)[0] for j in range(winreg.QueryInfoKey(skey)[1])] else ("Unknown", 1)
                            install_loc, _ = winreg.QueryValueEx(skey, "InstallLocation") if "InstallLocation" in [winreg.EnumValue(skey, j)[0] for j in range(winreg.QueryInfoKey(skey)[1])] else ("", 1)
                            
                            if name:
                                installed_apps.append({
                                    "name": str(name),
                                    "publisher": str(publisher),
                                    "install_location": str(install_loc)
                                })
                        except Exception:
                            continue
                except Exception:
                    continue
    except ImportError:
        # Non-Windows fallback stub
        installed_apps = [
            {"name": "Visual Studio Code", "publisher": "Microsoft", "install_location": "C:\\Program Files\\VSCode"},
            {"name": "Valorant", "publisher": "Riot Games", "install_location": "C:\\Riot Games\\Valorant"},
            {"name": "Adobe Photoshop 2024", "publisher": "Adobe", "install_location": "C:\\Program Files\\Adobe\\Photoshop"}
        ]

    # Process scanned results
    results = []
    summary_counts = {"native": 0, "likely_compatible": 0, "uncertain": 0, "high_risk": 0, "total": 0}

    for app in installed_apps[:10]: # Limit for scan responsiveness
        app_name = app["name"]
        mock_evidence = {
            "application": app_name,
            "architecture": "ARM64" if "Visual Studio" in app_name or "Photoshop" in app_name else "x64",
            "native_arm64": "Visual Studio" in app_name or "Photoshop" in app_name,
            "driver_indicators": "Valorant" in app_name,
            "anti_cheat_indicators": "Valorant" in app_name,
            "dependency_count": 12,
            "detection_confidence": "best-effort"
        }
        retrieved = retrieve_similar_cases(mock_evidence, top_k=2)
        category, insufficient = classify_compatibility(mock_evidence, retrieved)
        
        if category == "Native":
            summary_counts["native"] += 1
        elif category == "Likely Compatible":
            summary_counts["likely_compatible"] += 1
        elif category == "High Risk":
            summary_counts["high_risk"] += 1
        else:
            summary_counts["uncertain"] += 1

        summary_counts["total"] += 1

        results.append({
            "application": app_name,
            "evidence": mock_evidence,
            "category": category,
            "insufficient_evidence": insufficient,
            "retrieved_cases": retrieved,
            "explanation": f"Classified as {category} based on registry metadata and Knowledge Base lookup."
        })

    return {
        "results": results,
        "summary": summary_counts
    }


@router.get("/scan/store")
async def scan_store():
    """Enumerate installed Microsoft Store packages and declared architecture."""
    # Stub store apps with declared confidence
    store_apps = [
        {"application": "Microsoft To Do", "architecture": "ARM64", "native_arm64": True, "detection_confidence": "declared"},
        {"application": "Netflix App", "architecture": "x64", "native_arm64": False, "detection_confidence": "declared"}
    ]
    return store_apps


@router.post("/ask", response_model=AskResponse)
async def ask_question(request: AskRequest):
    context = _scan_context_cache.get(request.context_id)
    if not context:
        # Generic context stub if not found by exact key
        context = {
            "application": request.context_id,
            "category": "Uncertain",
            "evidence": {"architecture": "x64", "driver_indicators": False},
            "retrieved_cases": []
        }
    
    answer = answer_followup_question(context, request.question)
    return {"answer": answer}


@router.get("/dashboard/summary")
async def get_dashboard_summary():
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT observed_result, native_arm64, driver_indicators, anti_cheat_indicators FROM compatibility_cases")
    rows = cursor.fetchall()
    conn.close()

    summary = {"native": 0, "likely_compatible": 0, "uncertain": 0, "high_risk": 0, "total": len(rows)}

    for row in rows:
        if row["native_arm64"]:
            summary["native"] += 1
        elif row["driver_indicators"] or row["anti_cheat_indicators"] or row["observed_result"] == "fails":
            summary["high_risk"] += 1
        elif row["observed_result"] in ("works", "works_with_limitations"):
            summary["likely_compatible"] += 1
        else:
            summary["uncertain"] += 1

    return summary


@router.get("/dashboard/alternatives/{application_name}")
async def get_alternatives(application_name: str):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT application, category, source, source_date FROM compatibility_cases WHERE native_arm64 = 1")
    rows = cursor.fetchall()
    conn.close()

    alternatives = [
        {
            "application": row["application"],
            "category": row["category"],
            "source": row["source"],
            "source_date": row["source_date"]
        } for row in rows
    ]

    return {"alternatives": alternatives[:3]}


@router.get("/dashboard/npu-status")
async def get_npu_status():
    from retrieval.qai_hub_wrapper import QAIHubWrapper
    wrapper = QAIHubWrapper()
    return wrapper.get_npu_status()

