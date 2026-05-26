"""
NutriLait – Muzzle-photo registration server
Run with:  uvicorn server:app --host 0.0.0.0 --port 8000 --reload

Folder layout expected (set COW_DB_PATH below):
  cow_db/
    Bessie/
      photo01.jpg
      photo02.jpg
    ...
"""

import os
import json
from fastapi import FastAPI, File, Form, UploadFile
from fastapi.middleware.cors import CORSMiddleware

# ── Configuration ─────────────────────────────────────────────────────────────
COW_DB_PATH = os.path.join(os.path.dirname(__file__), "cow_db")
os.makedirs(COW_DB_PATH, exist_ok=True)

app = FastAPI(title="NutriLait Muzzle-ID Server")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── In-memory database (reloaded on demand) ───────────────────────────────────
_cow_db: dict[str, list[str]] = {}


def load_cow_database() -> None:
    """Scan COW_DB_PATH and rebuild the in-memory index."""
    global _cow_db
    _cow_db = {}
    if not os.path.isdir(COW_DB_PATH):
        return
    for cow_name in sorted(os.listdir(COW_DB_PATH)):
        cow_dir = os.path.join(COW_DB_PATH, cow_name)
        if not os.path.isdir(cow_dir):
            continue
        photos = sorted(
            f for f in os.listdir(cow_dir)
            if f.lower().endswith(('.jpg', '.jpeg', '.png'))
        )
        _cow_db[cow_name] = photos

    print(f"🐄 Database loaded: {len(_cow_db)} cows, "
          f"{sum(len(v) for v in _cow_db.values())} photos total")


# Load once at startup
load_cow_database()


# ── Endpoints ─────────────────────────────────────────────────────────────────

@app.get("/status")
async def status():
    """Return list of cows and their photo counts."""
    return [
        {"name": name, "count": len(photos)}
        for name, photos in _cow_db.items()
    ]


@app.post("/register")
async def register(
    cow_name: str = Form(...),
    file: UploadFile = File(...),
):
    """Register a new muzzle photo for a cow."""
    if not cow_name.strip():
        return {"status": "error", "message": "cow_name is required"}

    cow_dir = os.path.join(COW_DB_PATH, cow_name.strip())
    os.makedirs(cow_dir, exist_ok=True)

    existing = [
        f for f in os.listdir(cow_dir)
        if f.lower().endswith(('.jpg', '.jpeg', '.png'))
    ]
    next_num = len(existing) + 1
    filename = f"photo{next_num:02d}.jpg"
    filepath = os.path.join(cow_dir, filename)

    contents = await file.read()
    with open(filepath, "wb") as f:
        f.write(contents)

    total = len([
        f for f in os.listdir(cow_dir)
        if f.lower().endswith(('.jpg', '.jpeg', '.png'))
    ])

    print(f"✅ Registered {cow_name}: {filename} ({total} total)")
    load_cow_database()

    return {
        "status": "ok",
        "cow":    cow_name.strip(),
        "file":   filename,
        "photos": total,
    }


@app.post("/reload")
async def reload():
    """Force a database reload (called automatically after each upload)."""
    load_cow_database()
    return {
        "status": "reloaded",
        "cows":   len(_cow_db),
        "photos": sum(len(v) for v in _cow_db.values()),
    }
