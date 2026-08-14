-module(guard_breaker_sup).
-behaviour(supervisor).

-include("guard.hrl").

-export([
    start_link/0,
    start_breaker/2,
    stop_breaker/1
]).

-export([init/1]).

-spec start_link() -> {ok, pid()} | {error, term()}.
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

-spec start_breaker(circuit_name(), #circuit_config{}) -> {ok, pid()} | {error, term()}.
start_breaker(Name, Config) ->
    ChildSpec = #{
        id => Name,
        start => {guard_breaker, start_link, [Name, Config]},
        restart => transient,
        shutdown => 5000,
        type => worker,
        modules => [guard_breaker]
    },
    supervisor:start_child(?MODULE, ChildSpec).

-spec stop_breaker(circuit_name()) -> ok | {error, term()}.
stop_breaker(Name) ->
    _ = supervisor:terminate_child(?MODULE, Name),
    _ = supervisor:delete_child(?MODULE, Name),
    ok.

init([]) ->
    SupFlags = #{
        strategy => one_for_one,
        intensity => 10,
        period => 5
    },
    {ok, {SupFlags, []}}.