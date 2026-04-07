---
name: write-tests
description: Generate focused tests for use cases, repositories, and presentation state in the podcast transcript app.
---

Use this skill when adding or improving tests.

Test priorities:
1. Domain use cases
2. Presentation state transitions
3. Repository mapping behavior
4. Persistence behavior for favorites

For each feature:
- define success path
- define failure path
- define empty path
- define edge cases

Important scenarios:
- search returns channels
- search returns nothing
- episode list loads successfully
- episode list fails
- transcript exists
- transcript unavailable
- favorite add/remove works
- copy/share/export action triggers correctly

Avoid:
- low-value tests that mirror implementation details
- excessive UI-only tests
- fragile snapshot dependence unless explicitly requested

Output format:
1. feature under test
2. missing test coverage
3. test case list
4. code
5. regression checklist
