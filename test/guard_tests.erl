-module(guard_tests).
-include_lib("eunit/include/eunit.hrl").
-include("guard.hrl").

config_record_defaults_test() ->
    Config = #circuit_config{},
    ?assertEqual(5, Config#circuit_config.failure_threshold),
    ?assertEqual(10000, Config#circuit_config.reset_timeout_ms),
    ?assertEqual(3, Config#circuit_config.half_open_probes),
    ?assertEqual(60000, Config#circuit_config.max_reset_timeout_ms),
    ?assertEqual(2.0, Config#circuit_config.backoff_multiplier).
registry_lifecycle_test() ->
    guard_registry:init_table(),
    ?assertEqual(not_found, guard_registry:lookup_state(unknown_circuit)),
    ok = guard_registry:set_state(test_c, open),
    ?assertEqual(open, guard_registry:lookup_state(test_c)),
    ok = guard_registry:delete_circuit(test_c),
    ?assertEqual(not_found, guard_registry:lookup_state(test_c)).
breaker_state_transitions_test() ->
    guard_registry:init_table(),
    Name = breaker_trans_test,
    Config = #circuit_config{failure_threshold = 2, reset_timeout_ms = 100},
    {ok, Pid} = guard_breaker:start_link(Name, Config),
    ?assertEqual(closed, (guard_breaker:status(Pid))#circuit_status.state),
    guard_breaker:record_failure(Pid),
    ?assertEqual(closed, (guard_breaker:status(Pid))#circuit_status.state),
    guard_breaker:record_failure(Pid),
    timer:sleep(20),
    ?assertEqual(open, (guard_breaker:status(Pid))#circuit_status.state),
    guard_breaker:stop(Pid).
breaker_manual_controls_test() ->
    guard_registry:init_table(),
    Name = breaker_ctrl_test,
    {ok, Pid} = guard_breaker:start_link(Name, #circuit_config{}),
    ok = guard_breaker:trip(Pid),
    ?assertEqual(open, (guard_breaker:status(Pid))#circuit_status.state),
    ok = guard_breaker:reset(Pid),
    ?assertEqual(closed, (guard_breaker:status(Pid))#circuit_status.state),
    guard_breaker:stop(Pid).