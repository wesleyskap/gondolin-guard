# gondolin-guard

High-performance, zero-dependency Circuit Breaker and fault-tolerance toolkit for Erlang/OTP 27+.

## Overview

`gondolin-guard` is an Erlang/OTP resilience library designed to protect distributed BEAM applications from cascading failures and remote dependency outages. By combining `gen_statem` finite state machines, OTP supervision hierarchies, and concurrent ETS lookup tables (`read_concurrency, true`), `gondolin-guard` delivers sub-microsecond state validation on critical execution paths without message queue contention.

## Features

- Tri-state circuit breaker pattern (`closed`, `open`, `half_open`).
- Sub-microsecond state checks via concurrent ETS shared memory tables.
- Zero external dependencies. Built strictly on top of the Erlang/OTP standard library.
- Controlled half-open probing to safely test downstream recovery.
- Configurable exponential backoff with ceiling limits on repeated failures.
- Native OTP supervision trees with dynamic child breaker management.
- Synchronous and asynchronous execution wrappers with custom fallback handlers.
- Safe fault containment with full stacktrace capture on caught exceptions.