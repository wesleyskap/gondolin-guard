-module(guard_sup).
-behaviour(supervisor).

-include("guard.hrl").

-export([start_link/0]).
-export([init/1]).

-spec start_link() -> {ok, pid()} | {error, term()}.
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    SupFlags = #{
        strategy => rest_for_one,
        intensity => 5,
        period => 10
    },
    ChildSpecs = [
        #{
            id => guard_registry,
            start => {guard_registry, start_link, []},
            restart => permanent,
            shutdown => 5000,
            type => worker,
            modules => [guard_registry]
        },
        #{
            id => guard_breaker_sup,
            start => {guard_breaker_sup, start_link, []},
            restart => permanent,
            shutdown => 10000,
            type => supervisor,
            modules => [guard_breaker_sup]
        }
    ],
    {ok, {SupFlags, ChildSpecs}}.