#!/usr/bin/env python3

import json

def find_incorrect_test_cases_by_solver(file_path):
    with open(file_path, 'r') as file:
        data = json.load(file)

    incorrect_results = {}

    for solver, results in data.items():
        incorrect_test_cases = []
        for result in results:
            if result.get('correct', None) is False:
                incorrect_test_cases.append(result['name'])

        if incorrect_test_cases:
            incorrect_results[solver] = incorrect_test_cases

    return incorrect_results

# Replace 'your_file.json' with the path to your JSON file
file_path = 'results-latest.json'
incorrect_results = find_incorrect_test_cases_by_solver(file_path)

print("Incorrect test cases by solver:")
for solver, test_cases in incorrect_results.items():
    print(f"\nSolver: {solver}")
    for test_case in test_cases:
        print(f"  - {test_case}")
