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