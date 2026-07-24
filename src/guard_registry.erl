-module(guard_registry).

-include("guard.hrl").

-export([
    init_table/0,
    set_state/2,
    lookup_state/1,
    delete_circuit/1,
    list_circuits/0
]).

-define(TABLE_OPTIONS, [
    named_table,
    public,
    set,
    {read_concurrency, true},
    {write_concurrency, true}
]).

-spec init_table() -> ok.
init_table() ->
    case ets:info(?REGISTRY_TABLE) of
        undefined ->
            ets:new(?REGISTRY_TABLE, ?TABLE_OPTIONS),
            ok;
        _ ->
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