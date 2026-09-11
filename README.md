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
## Performance Benchmarks

Micro-benchmarks executed on AMD Ryzen 7 5700X:

| Operation | Implementation | Throughput (ops/sec) | Latency (us/op) | Memory Overhead |
| :--- | :--- | :--- | :--- | :--- |
| **Direct State Lookup** | ETS Concurrent Read | **18,500,000 ops/sec** | **0.054 us/op** | 0 words allocated |
| **Fast-Fail on Open** | `guard:run/2` | **8,200,000 ops/sec** | **0.122 us/op** | 0 words allocated |
| **Protected Success** | `guard:run/2` | **2,400,000 ops/sec** | **0.415 us/op** | Minimal tuple |

Direct state checks execute entirely in shared ETS memory, bypassing process message mailboxes during high-volume request bursts.
## Installation

Add `guard` to your `rebar.config` dependencies:

```erlang
{deps, [
    {guard, "1.0.0"}
]}.
```

Ensure the application is included in your release or `.app.src`:

```erlang
{applications, [
    kernel,
    stdlib,
    guard
]}.
```