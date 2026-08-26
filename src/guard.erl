-module(guard).

-include("guard.hrl").

-export([
    start_circuit/1,
    start_circuit/2,
    stop_circuit/1,
    state/1,
    status/1,
    trip/1,
    reset/1
]).

-spec start_circuit(circuit_name()) -> {ok, pid()} | {error, term()}.
start_circuit(Name) ->
    start_circuit(Name, #circuit_config{}).

-spec start_circuit(circuit_name(), #circuit_config{}) -> {ok, pid()} | {error, term()}.
start_circuit(Name, Config) ->
    guard_registry:init_table(),
    guard_breaker_sup:start_breaker(Name, Config).

-spec stop_circuit(circuit_name()) -> ok | {error, term()}.
stop_circuit(Name) ->
    guard_breaker_sup:stop_breaker(Name).

-spec state(circuit_name()) -> circuit_state() | not_found.
state(Name) ->
    guard_registry:lookup_state(Name).

-spec status(circuit_name()) -> #circuit_status{}.
status(Name) ->
    guard_breaker:status(Name).

-spec trip(circuit_name()) -> ok.
trip(Name) ->
    guard_breaker:trip(Name).

-spec reset(circuit_name()) -> ok.
reset(Name) ->
    guard_breaker:reset(Name).