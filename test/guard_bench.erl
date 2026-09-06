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