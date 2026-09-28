import json
import argparse
import os
import sys

# Ensure backend package imports work
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from database.db import get_connection, init_db
from retrieval.embedder import generate_embedding, embedding_to_blob

def seed_database(json_path: str, db_path: str = None):
    init_db(db_path)
    
    if not os.path.exists(json_path):
        print(f"Error: Seed file not found at {json_path}")
        sys.exit(1)

    with open(json_path, "r", encoding="utf-8") as f:
        cases = json.load(f)

    conn = get_connection(db_path)
    cursor = conn.cursor()

    # Clear existing entries
    cursor.execute("DELETE FROM compatibility_cases")

    inserted = 0
    for case in cases:
        embedding_vec = generate_embedding(case)
        embedding_blob = embedding_to_blob(embedding_vec)

        cursor.execute("""
            INSERT INTO compatibility_cases (
                application, architecture, native_arm64, driver_indicators,
                anti_cheat_indicators, category, observed_result, source, source_date, embedding
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            case["application"],
            case["architecture"],
            case["native_arm64"],
            case["driver_indicators"],
            case["anti_cheat_indicators"],
            case["category"],
            case["observed_result"],
            case["source"],
            case["source_date"],
            embedding_blob
        ))
        inserted += 1

    conn.commit()
    conn.close()
    print(f"Successfully seeded {inserted} compatibility cases into Knowledge Base.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Seed ARMWise Knowledge Base database.")
    parser.add_argument("--source", default="data/kb_seed.json", help="Path to kb_seed.json")
    parser.add_argument("--db", default=None, help="Path to SQLite database file")
    args = parser.parse_args()

    # Resolve paths relative to backend root
    backend_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    source_path = os.path.join(backend_root, args.source) if not os.path.isabs(args.source) else args.source

    seed_database(source_path, args.db)
