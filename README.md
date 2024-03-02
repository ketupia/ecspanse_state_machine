# EcspanseStateMachine

<!-- MDOC !-->

`ECSpanse State Machine` is a state machine implementation for [`ECSpanse`](https://hexdocs.pm/ecspanse).

<img src="https://github.com/ketupia/ecspanse_state_machine/blob/127356360085810df51a5574f8d2a637002891d1/priv/static/images/sample_mermaid_chart.png" width="300" alt="Sample Mermaid Chart">

<!-- MDOC !-->

## Features

- Multiple graphs executing simultaneously - create and start
- Register for Node transition events
- Graph validation - all nodes defined and reachable
- Node transitions on request or timeout
- Mermaid state diagram generation

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ecspanse_state_machine` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecspanse_state_machine, "~> 0.1.0"}
  ]
end
```

## How to use

### Register ESCpanse State Machine Systems

As part of your ESCpanse setup, you will have defined a `manager` with a `setup(data)` function. In that function, chain a call to the `ESCpanseStateMachine.Manager.setup`

```elixir
  def setup(data) do
    data
    |> EcspanseStateMachine.Manager.setup()
    # register your systems too
```

ECSpanseStateMachine will add the systems it needs for you.

### Spawn a graph and nodes

A graph is a collection of nodes along with some state such as the starting node name and is running. Nodes represent the states in the state machine. Nodes have a name, a list of allowed exit transitions, and may have a timeout timer.

The `ECSpanse State Machine System Api` exposes functions to spawn a graph and it's nodes. Since you will be spawning nodes, you can only call these functions from within an `ECSpanse System`.

#### Spawn a graph

Here's an example of creating a graph.

```elixir
    {:ok, graph_entity} =
      EcspanseStateMachine.SystemsApi.spawn_graph(
        :battle_123,
        :battle_start,
        %{battle_entity_id: battle_entity.id}
      )
```

`:battle_123` is the name of the graph. Graph names are atoms and needs to be unique and is one of the primary ways you'll interact with the state machine.

`:battle_start` is the name of the node the graph will start in. That is, when you request a graph start, a transition to this node will happen. You will spawn this node in a moment.

The last parameter, `%{battle_entity_id: battle_entity.id}`, is a reference for you to provide to the state machine. It can be `any()` data you want. This data will be provided back to you in events. This sample is from a system with many graphs running many battles. When a `NodeTransition` event is received, the reference provides quick access to look up the battle.

#### Spawn a node without a timer

Here's an example of spawning a node into the graph without a timeout timer. You will need to request a node transition to move from this state to one of the exit states.

```elixir
    EcspanseStateMachine.SystemsApi.spawn_node(
      graph_entity,
      :action_phase_end,
      [:decision_phase, :battle_end]
    )
```

The graph*entity is returned from the spawn_graph call above. `:action_phase_end` is the name of the node. Node names must be atoms and must be unique \_within* a graph. `[:decision_phase, :battle_end]` are the allowed exit transitions, the names of the nodes you can transition to from this node.

#### Spawn a node with a timeout timer ⏲️

Here's an example of spawning a node into the graph with a timeout timer. You can request a node transition to move from this state to one of the exit states or a state transition will automatically occur if the timer elapses.

```elixir
    EcspanseStateMachine.SystemsApi.spawn_node(
      graph_entity,
      :combatants_attack,
      [:combatants_move],
      :timer.seconds(1),
      :combatants_move
    )
```

The first 3 parameters are the same as before. This node is named `:combatants_attack` and there is only one allowed exit node specified `[:combatants_move]`. This node will automatically transition to `:combatants_move` after `:timer.seconds(1)`. The fourth parameter, `:timer.seconds(1)`, is the timer duration and the final parameter, `:combatants_move`, is the timeout node name. The timeout node name must be in the list of allowed exists.

### Interacting with the graph

The `ECSpanse State Machine Api` exposes functions to request a graph start, request a node tranistion, and generate a mermaid graph. This is safe to be called anywhere.

#### Start your graph

```elixir
  EcspanseStateMachine.Api.submit_start_graph_request(graph_entity)
```

#### Request a node transition

```elixir
  EcspanseStateMachine.Api.submit_node_transition_request(graph_entity, :decision_phase)
```

#### Generate a Mermaid State Diagram

```elixir
  EcspanseStateMachine.Api.as_mermaid_diagram(graph_entity)
```
