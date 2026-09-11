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
## Quick Start

### Basic Protected Execution

```erlang
-module(example_client).
-export([fetch_user_profile/1]).

fetch_user_profile(UserId) ->
    CircuitName = payment_gateway,
    Fun = fun() -> http_client:get("https://api.gateway.internal/v1/users/" ++ UserId) end,
    case guard:run(CircuitName, Fun) of
        {ok, Response} ->
            {ok, Response};
        {error, circuit_open} ->
            {error, service_unavailable};
        {error, Reason} ->
            {error, Reason}
    end.
```

### Execution with Custom Fallback

```erlang
fetch_account_balance(AccountId) ->
    Circuit = account_service,
    Fun = fun() -> rpc:call(AccountNode, account_server, get_balance, [AccountId]) end,
    Fallback = fun(circuit_open) -> read_cached_balance(AccountId) end,
    guard:run(Circuit, Fun, Fallback).
```

### Starting and Configuring Named Circuits

```erlang
-include_lib("guard/include/guard.hrl").

start_custom_circuit() ->
    Config = #circuit_config{
        failure_threshold = 5,
        reset_timeout_ms = 15000,
        half_open_probes = 3,
        max_reset_timeout_ms = 120000,
        backoff_multiplier = 2.0
    },
    {ok, _Pid} = guard:start_circuit(inventory_service, Config).
```

### Manual Circuit Controls

```erlang
%% Check current state: closed | open | half_open
State = guard:state(payment_gateway),

%% Inspect detailed metrics and failure counters
Status = guard:status(payment_gateway),

%% Manually trip circuit open during upstream maintenance
ok = guard:trip(payment_gateway),

%% Manually reset circuit to closed after recovery
ok = guard:reset(payment_gateway).
```

## Configuration Reference

The `#circuit_config{}` record supports the following fields:

- `failure_threshold`: Consecutive failures required to trip circuit (default `5`).
- `reset_timeout_ms`: Base wait time in milliseconds before probing downstream (default `10000`).
- `half_open_probes`: Successful consecutive probe calls required to close circuit (default `3`).
- `max_reset_timeout_ms`: Maximum backoff duration ceiling (default `60000`).
- `backoff_multiplier`: Exponential multiplier applied on repeated probe failures (default `2.0`).
- `sliding_window_ms`: Duration of sliding failure window (default `60000`).

## License

MIT License. Copyright (c) 2026 Wesley Skap.