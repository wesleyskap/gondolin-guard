-module(guard_breaker).
-behaviour(gen_statem).

-include("guard.hrl").

-export([
    start_link/2,
    stop/1,
    record_success/1,
    record_failure/1,
    status/1,
    trip/1,
    reset/1
]).

-export([
    init/1,
    callback_mode/0,
    terminate/3,
    code_change/4
]).

-export([
    closed/3,
    open/3,
    half_open/3
]).

-record(data, {
    name :: circuit_name(),
    config :: #circuit_config{},
    status :: #circuit_status{}
}).

-spec start_link(circuit_name(), #circuit_config{}) -> {ok, pid()} | {error, term()}.
start_link(Name, Config) ->
    gen_statem:start_link({local, Name}, ?MODULE, [Name, Config], []).

-spec stop(circuit_name() | pid()) -> ok.
stop(Target) ->
    gen_statem:stop(Target).

-spec record_success(circuit_name() | pid()) -> ok.
record_success(Target) ->
    gen_statem:cast(Target, record_success).

-spec record_failure(circuit_name() | pid()) -> ok.
record_failure(Target) ->
    gen_statem:cast(Target, record_failure).

-spec status(circuit_name() | pid()) -> #circuit_status{}.
status(Target) ->
    gen_statem:call(Target, status).

-spec trip(circuit_name() | pid()) -> ok.
trip(Target) ->
    gen_statem:call(Target, trip).

-spec reset(circuit_name() | pid()) -> ok.
reset(Target) ->
    gen_statem:call(Target, reset).
init([Name, Config]) ->
    guard_registry:set_state(Name, closed),
    Status = #circuit_status{
        name = Name,
        state = closed,
        current_timeout_ms = Config#circuit_config.reset_timeout_ms,
        last_state_change = erlang:system_time(millisecond)
    },
    Data = #data{name = Name, config = Config, status = Status},
    {ok, closed, Data}.

callback_mode() ->
    state_functions.
closed(cast, record_success, Data) ->
    Status = (Data#data.status)#circuit_status{failures = 0},
    {keep_state, Data#data{status = Status}};

closed(cast, record_failure, Data) ->
    CurrentFailures = (Data#data.status)#circuit_status.failures + 1,
    Config = Data#data.config,
    case CurrentFailures >= Config#circuit_config.failure_threshold of
        true ->
            trip_to_open(Data);
        false ->
            Status = (Data#data.status)#circuit_status{failures = CurrentFailures},
            {keep_state, Data#data{status = Status}}
    end;

closed({call, From}, status, Data) ->
    {keep_state_and_data, [{reply, From, Data#data.status}]};

closed({call, From}, trip, Data) ->
    trip_to_open_reply(From, Data);

closed({call, From}, reset, Data) ->
    {keep_state_and_data, [{reply, From, ok}]}.
open(state_timeout, reset_timeout, Data) ->
    transition_to_half_open(Data);

open(cast, _Event, _Data) ->
    keep_state_and_data;

open({call, From}, status, Data) ->
    {keep_state_and_data, [{reply, From, Data#data.status}]};

open({call, From}, trip, _Data) ->
    {keep_state_and_data, [{reply, From, ok}]};

open({call, From}, reset, Data) ->
    reset_to_closed_reply(From, Data).
half_open(cast, record_success, Data) ->
    Probes = (Data#data.status)#circuit_status.successful_probes + 1,
    Config = Data#data.config,
    case Probes >= Config#circuit_config.half_open_probes of
        true ->
            reset_to_closed(Data);
        false ->
            Status = (Data#data.status)#circuit_status{successful_probes = Probes},
            {keep_state, Data#data{status = Status}}
    end;

half_open(cast, record_failure, Data) ->
    trip_to_open_with_backoff(Data);

half_open({call, From}, status, Data) ->
    {keep_state_and_data, [{reply, From, Data#data.status}]};

half_open({call, From}, trip, Data) ->
    trip_to_open_reply(From, Data);

half_open({call, From}, reset, Data) ->
    reset_to_closed_reply(From, Data).