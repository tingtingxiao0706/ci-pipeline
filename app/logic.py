"""CI Pipeline Demo Application - Core logic"""

from typing import List, Optional

def calculate_sum(numbers: List[int]) -> int:
    """Calculate the sum of a list of numbers."""
    return sum(numbers)

def find_max(numbers: List[int]) -> Optional[int]:
    """Find the maximum value in a list. Returns None if empty."""
    if not numbers:
        return None
    return max(numbers)

def process_data(data: List[int]) -> dict:
    """Process data and return statistics."""
    total = calculate_sum(data)
    maximum = find_max(data)
    return {
        "total": total,
        "max": maximum,
        "average": total / len(data) if data else 0,
        "count": len(data)
    }
