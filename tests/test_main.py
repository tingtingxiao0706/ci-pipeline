"""Test module for main"""

import unittest
from app.logic import calculate_sum, find_max, process_data

class TestMain(unittest.TestCase):
    def test_calculate_sum(self):
        self.assertEqual(calculate_sum([1, 2, 3]), 6)
        self.assertEqual(calculate_sum([]), 0)

    def test_find_max(self):
        self.assertEqual(find_max([1, 2, 3]), 3)
        self.assertIsNone(find_max([]))

    def test_process_data(self):
        result = process_data([1, 2, 3])
        self.assertEqual(result["total"], 6)
        self.assertEqual(result["max"], 3)
        self.assertEqual(result["average"], 2.0)

if __name__ == '__main__':
    unittest.main()
