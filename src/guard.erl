-module(guard).

-include("guard.hrl").

-export([
    start_circuit/1,
    start_circuit/2,
    stop_circuit/1,
    run/2,
    run/3,
    call/2,
    call/3,
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

-spec run(circuit_name(), fun(() -> Result)) -> {ok, Result} | {error, term()}.
run(Name, Fun) ->
    run(Name, Fun, fun(circuit_open) -> {error, circuit_open} end).

-spec run(circuit_name(), fun(() -> Result), fun((term()) -> FallbackResult)) ->
    {ok, Result} | FallbackResult | {error, term()}.
run(Name, Fun, FallbackFun) ->
    case guard_registry:lookup_state(Name) of
        open ->
            FallbackFun(circuit_open);
        not_found ->
            {error, circuit_not_found};
        _OtherState ->
            execute_guarded(Name, Fun, FallbackFun)
    end.

-spec call(circuit_name(), fun(() -> Result)) -> {ok, Result} | {error, term()}.
call(Name, Fun) ->
    run(Name, Fun).

-spec call(circuit_name(), fun(() -> Result), fun((term()) -> FallbackResult)) ->
    {ok, Result} | FallbackResult | {error, term()}.
call(Name, Fun, FallbackFun) ->
    run(Name, Fun, FallbackFun).

execute_guarded(Name, Fun, _FallbackFun) ->
    try Fun() of
        {error, _Reason} = Error ->
            guard_breaker:record_failure(Name),
            Error;
        Result ->
            guard_breaker:record_success(Name),
            {ok, Result}
    catch
        Class:Reason:Stacktrace ->
            guard_breaker:record_failure(Name),
            {error, {Class, Reason, Stacktrace}}
    end.