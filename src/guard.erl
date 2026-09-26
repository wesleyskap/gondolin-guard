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

%% @doc Starts a circuit breaker worker process using default configuration.
%% Example:
%% ```
%% {ok, _Pid} = guard:start_circuit(payment_gateway).
%% '''
-spec start_circuit(circuit_name()) -> {ok, pid()} | {error, term()}.
start_circuit(Name) ->
    start_circuit(Name, #circuit_config{}).

%% @doc Starts a circuit breaker worker process with custom configuration.
%% Example:
%% ```
%% Config = #circuit_config{failure_threshold = 3, reset_timeout_ms = 5000},
%% {ok, _Pid} = guard:start_circuit(payment_gateway, Config).
%% '''
-spec start_circuit(circuit_name(), #circuit_config{}) -> {ok, pid()} | {error, term()}.
start_circuit(Name, Config) ->
    guard_registry:init_table(),
    guard_breaker_sup:start_breaker(Name, Config).

%% @doc Stops a circuit breaker worker process and removes its entry from the registry table.
%% Example:
%% ```
%% ok = guard:stop_circuit(payment_gateway).
%% '''
-spec stop_circuit(circuit_name()) -> ok | {error, term()}.
stop_circuit(Name) ->
    guard_breaker_sup:stop_breaker(Name).

%% @doc Looks up the current state of a circuit breaker in the ETS cache table.
%% Example:
%% ```
%% closed = guard:state(payment_gateway).
%% '''
-spec state(circuit_name()) -> circuit_state() | not_found.
state(Name) ->
    guard_registry:lookup_state(Name).

%% @doc Retrieves detailed status of the circuit breaker from its gen_statem process.
%% Example:
%% ```
%% Status = guard:status(payment_gateway).
%% '''
-spec status(circuit_name()) -> #circuit_status{}.
status(Name) ->
    guard_breaker:status(Name).

%% @doc Manually trips the circuit breaker to the open state.
%% Example:
%% ```
%% ok = guard:trip(payment_gateway).
%% '''
-spec trip(circuit_name()) -> ok.
trip(Name) ->
    guard_breaker:trip(Name).

%% @doc Manually resets the circuit breaker to the closed state.
%% Example:
%% ```
%% ok = guard:reset(payment_gateway).
%% '''
-spec reset(circuit_name()) -> ok.
reset(Name) ->
    guard_breaker:reset(Name).

%% @doc Executes a protected operation through the circuit breaker with a default failure fallback.
%% Example:
%% ```
%% {ok, Result} = guard:run(payment_gateway, fun() -> http_client:post(Url, Payload) end).
%% '''
-spec run(circuit_name(), fun(() -> Result)) -> {ok, Result} | {error, term()}.
run(Name, Fun) ->
    run(Name, Fun, fun(circuit_open) -> {error, circuit_open} end).

%% @doc Executes a protected operation through the circuit breaker with a custom fallback function.
%% Example:
%% ```
%% Fallback = fun(circuit_open) -> {ok, cached_response} end,
%% Result = guard:run(payment_gateway, fun() -> http_client:post(Url, Payload) end, Fallback).
%% '''
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

%% @doc Alias for run/2.
%% Example:
%% ```
%% {ok, Result} = guard:call(payment_gateway, fun() -> fetch_data() end).
%% '''
-spec call(circuit_name(), fun(() -> Result)) -> {ok, Result} | {error, term()}.
call(Name, Fun) ->
    run(Name, Fun).

%% @doc Alias for run/3.
%% Example:
%% ```
%% Result = guard:call(payment_gateway, fun() -> fetch_data() end, fun(_) -> fallback end).
%% '''
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