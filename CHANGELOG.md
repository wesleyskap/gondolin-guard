# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-09-12

### Added
- Core gen_statem circuit breaker state machine with closed, open, and half_open states.
- High-concurrency ETS state cache with read_concurrency enabling sub-microsecond validation.
- OTP supervision tree structure with root supervisor and dynamic worker breaker supervisor.
- Public client API with run/2, run/3, call/2, and call/3 execution wrappers.
- Configurable failure threshold, probe counts, and reset timeouts.
- Exponential backoff with ceiling caps on repeated probe failures.
- Fallback function execution support during open circuit conditions.
- Comprehensive EUnit test suite and concurrency benchmark suite.