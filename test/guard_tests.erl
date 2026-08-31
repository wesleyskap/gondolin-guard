-module(guard_tests).
-include_lib("eunit/include/eunit.hrl").
-include("guard.hrl").

setup() ->
    guard_registry:init_table(),
    case whereis(guard_breaker_sup) of
        undefined ->
            {ok, _} = guard_breaker_sup:start_link();
        _ ->
            ok
    end,
    ok.

cleanup(_) ->
    ok.

circuit_breaker_test_() ->
    {setup,
     fun setup/0,
     fun cleanup/1,
     [
        {"initial state is closed", fun test_initial_state/0},
        {"successful execution passes through", fun test_successful_run/0},
        {"circuit trips to open on threshold failures", fun test_trip_on_failure_threshold/0},
        {"open circuit executes fallback", fun test_open_circuit_fallback/0},
        {"manual trip and manual reset", fun test_manual_trip_and_reset/0},
        {"half open probing and recovery", fun test_half_open_recovery/0}
     ]}.

test_initial_state() ->
    Circuit = test_circuit_1,
    Config = #circuit_config{failure_threshold = 3},
    {ok, _Pid} = guard:start_circuit(Circuit, Config),
    ?assertEqual(closed, guard:state(Circuit)),
    guard:stop_circuit(Circuit).

test_successful_run() ->
    Circuit = test_circuit_2,
    {ok, _Pid} = guard:start_circuit(Circuit),
    Res = guard:run(Circuit, fun() -> 42 end),
    ?assertEqual({ok, 42}, Res),
    ?assertEqual(closed, guard:state(Circuit)),
    guard:stop_circuit(Circuit).

test_trip_on_failure_threshold() ->
    Circuit = test_circuit_3,
    Config = #circuit_config{failure_threshold = 2, reset_timeout_ms = 500},
    {ok, _Pid} = guard:start_circuit(Circuit, Config),
    FailFun = fun() -> {error, remote_failure} end,
    _ = guard:run(Circuit, FailFun),
    ?assertEqual(closed, guard:state(Circuit)),
    _ = guard:run(Circuit, FailFun),
    timer:sleep(20),
    ?assertEqual(open, guard:state(Circuit)),
    guard:stop_circuit(Circuit).

test_open_circuit_fallback() ->
    Circuit = test_circuit_4,
    {ok, _Pid} = guard:start_circuit(Circuit),
    guard:trip(Circuit),
    ?assertEqual(open, guard:state(Circuit)),
    CalledRef = {ref, erlang:make_ref()},
    RunRes = guard:run(Circuit, fun() -> CalledRef end),
    ?assertEqual({error, circuit_open}, RunRes),
    FallbackRes = guard:run(Circuit, fun() -> ok end, fun(_) -> cached_fallback end),
    ?assertEqual(cached_fallback, FallbackRes),
    guard:stop_circuit(Circuit).

test_manual_trip_and_reset() ->
    Circuit = test_circuit_5,
    {ok, _Pid} = guard:start_circuit(Circuit),
    ?assertEqual(closed, guard:state(Circuit)),
    guard:trip(Circuit),
    ?assertEqual(open, guard:state(Circuit)),
    guard:reset(Circuit),
    ?assertEqual(closed, guard:state(Circuit)),
    guard:stop_circuit(Circuit).

test_half_open_recovery() ->
    Circuit = test_circuit_6,
    Config = #circuit_config{
        failure_threshold = 1,
        reset_timeout_ms = 50,
        half_open_probes = 2
    },
    {ok, _Pid} = guard:start_circuit(Circuit, Config),
    _ = guard:run(Circuit, fun() -> {error, boom} end),
    timer:sleep(20),
    ?assertEqual(open, guard:state(Circuit)),
    timer:sleep(70),
    ?assertEqual(half_open, guard:state(Circuit)),
    _ = guard:run(Circuit, fun() -> ok end),
    timer:sleep(10),
    ?assertEqual(half_open, guard:state(Circuit)),
    _ = guard:run(Circuit, fun() -> ok end),
    timer:sleep(10),
    ?assertEqual(closed, guard:state(Circuit)),
    guard:stop_circuit(Circuit).