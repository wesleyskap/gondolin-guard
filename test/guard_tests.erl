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