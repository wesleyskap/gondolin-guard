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