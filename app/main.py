"""Flask-based CI Pipeline Demo Application"""

from typing import Any, Tuple

from flask import Flask, Response, jsonify, request
from flask_cors import CORS
import os
import platform

from .logic import process_data

app = Flask(__name__)
CORS(app)


@app.route("/health", methods=["GET"])
def health() -> Tuple[Response, int]:
    """Health check endpoint for Kubernetes/load balancer probes."""
    return jsonify({"status": "healthy", "version": "1.0.0", "uptime": "N/A"}), 200


@app.route("/api/info", methods=["GET"])
def info() -> Tuple[Response, int]:
    """Application information endpoint."""
    return (
        jsonify(
            {
                "name": "ci-pipeline-demo",
                "version": "1.0.0",
                "environment": os.getenv("ENVIRONMENT", "development"),
                "python_version": platform.python_version(),
                "status": "operational",
            }
        ),
        200,
    )


@app.route("/api/process", methods=["POST"])
def process_numbers() -> Tuple[Response, int]:
    """Data processing endpoint."""
    try:
        payload = request.get_json(silent=True) or {}
        numbers = payload.get("numbers", [])

        if not isinstance(numbers, list):
            return jsonify({"error": "numbers must be a list"}), 400

        result = process_data(numbers)
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/", methods=["GET"])
def root() -> Tuple[Response, int]:
    """Root endpoint."""
    return (
        jsonify(
            {
                "service": "ci-pipeline-demo",
                "version": "1.0.0",
                "endpoints": ["/health", "/api/info", "/api/process"],
                "docs": "/health for health check",
            }
        ),
        200,
    )


# WSGI entry point
wsgi_app = app

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8080))
    debug = os.getenv("DEBUG", "false").lower() == "true"
    app.run(host="0.0.0.0", port=port, debug=debug)
