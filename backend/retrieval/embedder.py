import numpy as np
from typing import Dict, Any, List, Union

_model = None

def get_model():
    global _model
    if _model is None:
        try:
            from sentence_transformers import SentenceTransformer
            _model = SentenceTransformer('all-MiniLM-L6-v2')
        except Exception as e:
            # Fallback deterministic pseudo-embedding generator for test/dev environments without torch/huggingface network
            _model = "stub"
    return _model

def format_evidence_text(item: Union[Dict[str, Any], Any]) -> str:
    """Format structured evidence or DB case into text representation for embedding."""
    if isinstance(item, dict):
        app = item.get("application", "")
        arch = item.get("architecture", "")
        driver = "driver_detected" if item.get("driver_indicators") else "no_driver"
        anticheat = "anticheat_detected" if item.get("anti_cheat_indicators") else "no_anticheat"
        cat = item.get("category", "")
        return f"Application: {app}, Architecture: {arch}, Drivers: {driver}, AntiCheat: {anticheat}, Category: {cat}"
    return str(item)

def generate_embedding(text_or_dict: Union[str, Dict[str, Any]]) -> np.ndarray:
    text = format_evidence_text(text_or_dict)
    model = get_model()
    
    if model == "stub":
        # Deterministic 384-dim pseudo-vector from hash for dev fallback
        np.random.seed(abs(hash(text)) % (2**32))
        vec = np.random.randn(384).astype(np.float32)
        norm = np.linalg.norm(vec)
        return vec / norm if norm > 0 else vec
    
    vec = model.encode(text, convert_to_numpy=True).astype(np.float32)
    norm = np.linalg.norm(vec)
    return vec / norm if norm > 0 else vec

def embedding_to_blob(vec: np.ndarray) -> bytes:
    return vec.tobytes()

def blob_to_embedding(blob: bytes) -> np.ndarray:
    return np.frombuffer(blob, dtype=np.float32)
