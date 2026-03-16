"""Test module for application logic and Flask routes"""

import json
import unittest

from app.logic import calculate_sum, find_max, process_data
from app.main import app


class TestLogic(unittest.TestCase):
    def test_calculate_sum(self) -> None:
        self.assertEqual(calculate_sum([1, 2, 3]), 6)
        self.assertEqual(calculate_sum([]), 0)

    def test_calculate_sum_negative(self) -> None:
        self.assertEqual(calculate_sum([-1, -2, 3]), 0)

    def test_find_max(self) -> None:
        self.assertEqual(find_max([1, 2, 3]), 3)
        self.assertIsNone(find_max([]))

    def test_find_max_negative(self) -> None:
        self.assertEqual(find_max([-5, -1, -3]), -1)

    def test_process_data(self) -> None:
        result = process_data([1, 2, 3])
        self.assertEqual(result["total"], 6)
        self.assertEqual(result["max"], 3)
        self.assertEqual(result["average"], 2.0)
        self.assertEqual(result["count"], 3)

    def test_process_data_empty(self) -> None:
        result = process_data([])
        self.assertEqual(result["total"], 0)
        self.assertIsNone(result["max"])
        self.assertEqual(result["average"], 0)
        self.assertEqual(result["count"], 0)


class TestFlaskRoutes(unittest.TestCase):
    def setUp(self) -> None:
        self.client = app.test_client()

    def test_health(self) -> None:
        resp = self.client.get("/health")
        self.assertEqual(resp.status_code, 200)
        data = resp.get_json()
        self.assertEqual(data["status"], "healthy")
        self.assertIn("version", data)

    def test_info(self) -> None:
        resp = self.client.get("/api/info")
        self.assertEqual(resp.status_code, 200)
        data = resp.get_json()
        self.assertEqual(data["name"], "ci-pipeline-demo")
        self.assertIn("python_version", data)

    def test_root(self) -> None:
        resp = self.client.get("/")
        self.assertEqual(resp.status_code, 200)
        data = resp.get_json()
        self.assertEqual(data["service"], "ci-pipeline-demo")
        self.assertIn("/health", data["endpoints"])

    def test_process_valid(self) -> None:
        resp = self.client.post(
            "/api/process",
            data=json.dumps({"numbers": [10, 20, 30]}),
            content_type="application/json",
        )
        self.assertEqual(resp.status_code, 200)
        data = resp.get_json()
        self.assertEqual(data["total"], 60)
        self.assertEqual(data["max"], 30)
        self.assertEqual(data["average"], 20.0)

    def test_process_empty_list(self) -> None:
        resp = self.client.post(
            "/api/process",
            data=json.dumps({"numbers": []}),
            content_type="application/json",
        )
        self.assertEqual(resp.status_code, 200)
        data = resp.get_json()
        self.assertEqual(data["total"], 0)

    def test_process_invalid_type(self) -> None:
        resp = self.client.post(
            "/api/process",
            data=json.dumps({"numbers": "not a list"}),
            content_type="application/json",
        )
        self.assertEqual(resp.status_code, 400)
        data = resp.get_json()
        self.assertIn("error", data)

    def test_process_no_body(self) -> None:
        resp = self.client.post("/api/process", content_type="application/json")
        self.assertEqual(resp.status_code, 200)


if __name__ == "__main__":
    unittest.main()
