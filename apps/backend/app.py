import os
from flask import Flask, jsonify
import psycopg2
from psycopg2.extras import RealDictCursor

app = Flask(__name__)

DB_HOST = os.getenv("DB_HOST", "postgres.test-demo.svc.cluster.local")
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_NAME = os.getenv("DB_NAME", "cars")
DB_USER = os.getenv("DB_USER", "carsapp")
DB_PASSWORD = os.getenv("DB_PASSWORD", "carsapp")


def get_conn():
    return psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
    )


@app.get("/healthz")
def healthz():
    return {"status": "ok"}


@app.get("/api/cars")
def cars():
    with get_conn() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("SELECT id, make, model, year FROM cars ORDER BY id")
            rows = cur.fetchall()
    return jsonify({"cars": rows})


if __name__ == "__main__":
    port = int(os.getenv("PORT", "5000"))
    app.run(host="0.0.0.0", port=port)
