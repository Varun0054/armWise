import numpy as np
from typing import List, Dict, Any
from database.db import get_connection
from .embedder import generate_embedding, blob_to_embedding

def compute_cosine_similarity(vec1: np.ndarray, vec2: np.ndarray) -> float:
    dot_product = np.dot(vec1, vec2)
    norm1 = np.linalg.norm(vec1)
    norm2 = np.linalg.norm(vec2)
    if norm1 == 0 or norm2 == 0:
        return 0.0
    return float(dot_product / (norm1 * norm2))

def retrieve_similar_cases(evidence: Dict[str, Any], top_k: int = 3, threshold: float = 0.5) -> List[Dict[str, Any]]:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT id, application, architecture, native_arm64, driver_indicators, anti_cheat_indicators, category, observed_result, source, source_date, embedding FROM compatibility_cases")
    rows = cursor.fetchall()
    conn.close()

    if not rows:
        return []

    target_vec = generate_embedding(evidence)
    results = []

    for row in rows:
        kb_vec = blob_to_embedding(row["embedding"])
        sim = compute_cosine_similarity(target_vec, kb_vec)
        
        # Boost similarity score slightly if exact architecture / anti-cheat alignment exists
        if row["driver_indicators"] == evidence.get("driver_indicators") and row["anti_cheat_indicators"] == evidence.get("anti_cheat_indicators"):
            sim = min(1.0, sim + 0.05)

        if sim >= threshold:
            results.append({
                "id": row["id"],
                "application": row["application"],
                "architecture": row["architecture"],
                "native_arm64": bool(row["native_arm64"]),
                "driver_indicators": bool(row["driver_indicators"]),
                "anti_cheat_indicators": bool(row["anti_cheat_indicators"]),
                "category": row["category"],
                "observed_result": row["observed_result"],
                "source": row["source"],
                "source_date": row["source_date"],
                "similarity": round(float(sim), 4)
            })

    # Sort descending by similarity
    results.sort(key=lambda x: x["similarity"], reverse=True)
    return results[:top_k]
