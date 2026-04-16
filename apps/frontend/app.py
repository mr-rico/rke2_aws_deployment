import os
import requests
from flask import Flask, render_template

app = Flask(__name__)
BACKEND_URL = os.getenv("BACKEND_URL", "http://backend.test-demo.svc.cluster.local:5000/api/cars")
TIMEOUT = float(os.getenv("BACKEND_TIMEOUT", "5"))


@app.route("/")
def home():
    payload = {"cars": [], "error": None}
    try:
        response = requests.get(BACKEND_URL, timeout=TIMEOUT)
        response.raise_for_status()
        payload = response.json()
    except Exception as exc:
        payload["error"] = str(exc)
    return render_template("index.html", payload=payload, backend_url=BACKEND_URL)


if __name__ == "__main__":
    port = int(os.getenv("PORT", "5000"))
    app.run(host="0.0.0.0", port=port)
