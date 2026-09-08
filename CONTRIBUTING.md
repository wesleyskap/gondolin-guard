# Contributing to gondolin-guard

Thank you for your interest in contributing to gondolin-guard.

## Development Standards

1. Code Quality
   - Follow standard Erlang/OTP conventions and idiom.
   - Maintain function lengths between 4 and 20 lines. Split longer operations into dedicated sub-functions.
   - Ensure all public functions define explicit -spec types.
   - Keep files focused and under 500 lines of code.

2. Testing and Benchmarks
   - All bug fixes and enhancements must include EUnit tests under test/.
   - Any modifications to the hot path must verify sub-microsecond latency.

3. Git Commits and Messages
   - Use Conventional Commits formatting (feat:, fix:, test:, refactor:, docs:, chore:).
   - Write all commit messages and comments in clear English.
   - Do not use emojis in commit messages or code files.
   - Do not mention fictional lore or fantasy backstories in documentation or commit messages.