from flask import Flask, jsonify
import psycopg2
import os

app = Flask(__name__)

def get_db():
    return psycopg2.connect(
        host=os.environ.get("DB_HOST", "postgres"),
        port=os.environ.get("DB_PORT", 5432),
        dbname=os.environ.get("DB_NAME", "onboarding"),
        user=os.environ.get("DB_USER", "postgres"),
        password=os.environ.get("DB_PASSWORD", "postgres"),
    )

@app.route("/health")
def health():
    return jsonify({"status": "ok"})

@app.route("/db-check")
def db_check():
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT version();")
    version = cur.fetchone()[0]
    cur.close()
    conn.close()
    return jsonify({"status": "ok", "postgres_version": version})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
