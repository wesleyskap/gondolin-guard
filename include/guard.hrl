-ifndef(GUARD_HRL).
-define(GUARD_HRL, true).

-type circuit_name() :: atom() | binary().
-type circuit_state() :: closed | open | half_open.

-record(circuit_config, {
    failure_threshold = 5 :: pos_integer(),
    reset_timeout_ms = 10000 :: pos_integer(),
    half_open_probes = 3 :: pos_integer(),
    max_reset_timeout_ms = 60000 :: pos_integer(),
    backoff_multiplier = 2.0 :: float(),
    sliding_window_ms = 60000 :: pos_integer()
}).