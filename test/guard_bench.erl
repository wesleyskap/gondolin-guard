-module(guard_bench).

-include("guard.hrl").

-export([bench_read_throughput/2, bench_run_loop/2]).

bench_read_throughput(CircuitName, Iterations) ->
    guard_registry:init_table(),
    guard_registry:set_state(CircuitName, closed),
    Start = erlang:system_time(microsecond),
    run_read_loop(CircuitName, Iterations),
    ElapsedUs = erlang:system_time(microsecond) - Start,
    UsPerOp = ElapsedUs / Iterations,
    OpsPerSec = (Iterations / ElapsedUs) * 1000000,
    #{
        iterations => Iterations,
        total_time_us => ElapsedUs,
        us_per_op => UsPerOp,
        ops_per_sec => erlang:round(OpsPerSec)
    }.
bench_run_loop(CircuitName, Iterations) ->
    guard_registry:init_table(),
    guard_registry:set_state(CircuitName, open),
    Start = erlang:system_time(microsecond),
    run_fast_fail_loop(CircuitName, Iterations),
    ElapsedUs = erlang:system_time(microsecond) - Start,
    UsPerOp = ElapsedUs / Iterations,
    OpsPerSec = (Iterations / ElapsedUs) * 1000000,
    #{
        iterations => Iterations,
        total_time_us => ElapsedUs,
        us_per_op => UsPerOp,
        ops_per_sec => erlang:round(OpsPerSec)
    }.

run_read_loop(_Circuit, 0) ->
    ok;
run_read_loop(Circuit, N) ->
    _ = guard_registry:lookup_state(Circuit),
    run_read_loop(Circuit, N - 1).

run_fast_fail_loop(_Circuit, 0) ->
    ok;
run_fast_fail_loop(Circuit, N) ->
    _ = guard:run(Circuit, fun() -> ok end),
    run_fast_fail_loop(Circuit, N - 1).