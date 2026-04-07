
---
name: integrate-api
description: Integrate a remote API into the podcast transcript app using Moya + Alamofire and Clean Architecture boundaries.
---

Use this skill when implementing remote data flows such as:
- searching channels
- fetching episodes for a channel
- fetching transcript for an episode

Follow these steps:

1. Clarify API purpose
- what endpoint is needed
- what user flow it supports
- what error cases matter

2. Define Data layer pieces
- Moya target
- request/response DTOs
- response mapping
- repository implementation

3. Define Domain boundary
- repository protocol if missing
- domain entities if needed
- use case input/output contract

4. Error mapping
Map these into app-level errors where relevant:
- transport/network failure
- decoding failure
- empty response
- unsupported transcript
- rate limit or unavailable service

5. Testing guidance
Suggest:
- stubbed responses
- success case
- empty case
- failure case

Output format:
1. endpoint summary
2. proposed files
3. mapping strategy
4. implementation
5. validation and test suggestions
