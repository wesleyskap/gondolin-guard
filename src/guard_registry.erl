-module(guard_registry).
-behaviour(gen_server).

-include("guard.hrl").

-export([
    start_link/0,
    init_table/0,
    set_state/2,
    lookup_state/1,
    delete_circuit/1,
    list_circuits/0
]).

-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-define(TABLE_OPTIONS, [
    named_table,
    public,
    set,
    {read_concurrency, true},
    {write_concurrency, true}
]).

-spec start_link() -> {ok, pid()} | {error, term()}.
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

-spec init_table() -> ok.
init_table() ->
    case whereis(?MODULE) of
        undefined ->
            ensure_table_exists();
        _Pid ->
            ok
    end.

-spec set_state(circuit_name(), circuit_state()) -> ok.
set_state(CircuitName, State) ->
    ets:insert(?REGISTRY_TABLE, {CircuitName, State}),
    ok.

-spec lookup_state(circuit_name()) -> circuit_state() | not_found.
lookup_state(CircuitName) ->
    try ets:lookup(?REGISTRY_TABLE, CircuitName) of
        [{CircuitName, State}] -> State;
        [] -> not_found
    catch
        error:badarg -> not_found
    end.

-spec delete_circuit(circuit_name()) -> ok.
delete_circuit(CircuitName) ->
    catch ets:delete(?REGISTRY_TABLE, CircuitName),
    ok.

-spec list_circuits() -> [{circuit_name(), circuit_state()}].
list_circuits() ->
    try ets:tab2list(?REGISTRY_TABLE)
    catch error:badarg -> [] end.

%% gen_server callbacks

init([]) ->
    Options = [{heir, whereis(guard_sup), ?REGISTRY_TABLE} | ?TABLE_OPTIONS],
    case ets:info(?REGISTRY_TABLE) of
        undefined ->
            ets:new(?REGISTRY_TABLE, Options);
        _ ->
            catch ets:setopts(?REGISTRY_TABLE, [{heir, whereis(guard_sup), ?REGISTRY_TABLE}])
    end,
    {ok, #{table => ?REGISTRY_TABLE}}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info({'ETS-TRANSFER', ?REGISTRY_TABLE, _FromPid, _Data}, State) ->
    catch ets:setopts(?REGISTRY_TABLE, [{heir, whereis(guard_sup), ?REGISTRY_TABLE}]),
    {noreply, State};
handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

ensure_table_exists() ->
    case ets:info(?REGISTRY_TABLE) of
        undefined ->
            ets:new(?REGISTRY_TABLE, ?TABLE_OPTIONS),
            ok;
        _ ->
            ok
    end.