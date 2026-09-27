-ifndef(GUARD_HRL).
-define(GUARD_HRL, true).

-type circuit_name() :: atom() | binary().
-type circuit_state() :: closed | open | half_open.

-record(circuit_config, {
    failure_threshold = 5 :: pos_integer(),
    reset_timeout_ms = 10000 :: pos_integer(),
    half_open_probes = 3 :: pos_integer(),
    max_reset_timeout_ms = 60000 :: pos_integer(),
    backoff_multiplier = 2.0 :: float()
}).
-record(circuit_status, {
    name :: circuit_name(),
    state = closed :: circuit_state(),
    failures = 0 :: non_neg_integer(),
    successful_probes = 0 :: non_neg_integer(),
    current_timeout_ms = 10000 :: pos_integer(),
    last_state_change = 0 :: integer()
}).

-define(REGISTRY_TABLE, guard_registry).

-endif.