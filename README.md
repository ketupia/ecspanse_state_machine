# EcspanseStateMachine

<!-- MDOC !-->

`ECSpanse State Machine` is a state machine implementation for [`ECSpanse`](https://hexdocs.pm/ecspanse).

[![](https://mermaid.ink/img/pako:eNp1kEFuwjAQRa9izbLCUkmhRV6w4gYs6yqa2AONiB3kTKpWiDNwF1acpxfoFTqOioJadWN7_vsjff8DuNYTGNBa28g1N2RUhSx3WWGFtKic3tzLMZvNpxrnjwvtcVo8EBUO8cnGYbFjZFrVuE0Y9Ftho1LPdy9K66XiPsVSeOKsjtMAt4kieupKet83EsSoz9P563LK1t9sWHBtkHQYuSslJLrd7cYfOAag6G-dV-2_hFf004SMGY3TAOWHWYUJBEoBay81HrJigV8pkAUjT49pZ8HGo_iw53b9ER0YTj1NoN_7sTcwG2w6On4DXdGPHQ?type=png)](https://mermaid.live/edit#pako:eNp1kEFuwjAQRa9izbLCUkmhRV6w4gYs6yqa2AONiB3kTKpWiDNwF1acpxfoFTqOioJadWN7_vsjff8DuNYTGNBa28g1N2RUhSx3WWGFtKic3tzLMZvNpxrnjwvtcVo8EBUO8cnGYbFjZFrVuE0Y9Ftho1LPdy9K66XiPsVSeOKsjtMAt4kieupKet83EsSoz9P563LK1t9sWHBtkHQYuSslJLrd7cYfOAag6G-dV-2_hFf004SMGY3TAOWHWYUJBEoBay81HrJigV8pkAUjT49pZ8HGo_iw53b9ER0YTj1NoN_7sTcwG2w6On4DXdGPHQ)

<!-- MDOC !-->

## Features

- Multiple graphs executing simultaneously - create, start, and stop independently
- Graph validation - all nodes defined and reachable
- Node transitions on request or timeout
- Register for Node transition events
- Mermaid state diagram generation

<!-- MDOC !-->

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

<!-- MDOC !-->

## How to use

1. [Register the state machine's ECSpanse systems](#register-escpanse-state-machine-systems)
2. [Spawn a graph](#spawn-a-graph)
3. [Start your graph](#start-your-graph)
4. [Listen for node transitions](#listen-for-node-transitions)
5. [Request a node transition](#request-a-node-transition)
6. [Stopping a graph](#stopping-a-graph)
7. [Despawning a graph](#despawning-a-graph)

### Register ESCpanse State Machine Systems

As part of your ESCpanse setup, you will have defined a `manager` with a `setup(data)` function. In that function, chain a call to `ESCpanseStateMachine.setup`

```elixir
  def setup(data) do
    data
    # register the state machine's systems
    |> EcspanseStateMachine.setup()

    # Be sure to register the Ecspanse System Timer!
    |> Ecspanse.add_frame_end_system(Ecspanse.System.Timer)

    # register your systems too
```

ECSpanseStateMachine will add the systems it needs for you.

### Spawn a graph

A graph is a collection of nodes along with some state such as the starting node name and is running. Nodes represent the states in the state machine. Nodes have a name, a list of allowed exit transitions, and may have a timeout timer.

Here's an example of spawning a graph with each condition.

```elixir
  graph_attrs = %Graph{
      name: :battle_123,
      starting_node: :battle_start,
      metadata: %{battle_entity_id: "5dc3f158-d28c-4386-b54b-22606be5641b"},
      auto_start: true,
      nodes: [
        %Node{
          name: :battle_start,
          exits_to: [:battle_end],
          timer: %Timer{duration: :timer.seconds(3), exits_to: :battle_end}
        },
        %Node{
          name: :battle_end,
          exits_to: []
        }
  }
  with {:ok, graph_entity_id} <- EcspanseStateMachine.spawn_graph(graph_attrs) do
      IO.puts(EcspanseStateMachine.as_mermaid_diagram(graph_entity_id))
    else
      {:error, reason} ->
        Logger.critical("Invalid Graph: #{reason}")
    end
```

`:battle_123` is the name of the graph.

`:battle_start` is the name of the node the graph transition to when it starts.

The metadata, %{battle_entity_id: ...}, is metadata you provide to the state machine. It can be `any()` data you want. This data will be provided back to you in events. This sample is from a system with many graphs running many battles. When a `NodeTransition` event is received, the metadata provides quick access to look up the battle.

When `auto_start` is true, the graph will be spawned and started if the graph is valid.

:nodes is the list of states that make up your graph.

The first node listed is :battle_start. When the state machine is in this state, you can transition to :battle_end. You could have many exits from a node. :battle_start also has a timer. After 3 seconds, it will transition to the timer's exits_to state.

The last node, :battle_end has no exit nodes and does not have a timer.

### Start your graph

You can `auto_start` your graph as shown above or, you set the state machine in motion by issuing a start graph request. The graph will transition into the starting node.

```elixir
  EcspanseStateMachine.submit_start_graph_request(graph_entity_id)
```

#### graph start events

You can listen for graph started events.

```elixir
defmodule OnGraphStarted do
  use Ecspanse.System,
    event_subscriptions: [EcspanseStateMachine.Events.GraphStarted]

  def run(
        %EcspanseStateMachine.Events.GraphStarted{
          entity_id: entity_id,
          name: name,
          metadata: metadata
        },
        _frame
      ) do
    IO.inspect(
      "Graph #{entity_id}, #{name} started, metadata: #{inspect(metadata)}"
    )
  end
end
```

### Listen for node transitions

You'll create ECSpanse event subscriptions for EcspanseStateMachine.Events.NodeTransition events.

```elixir
defmodule OnNodeTransition do
  use Ecspanse.System,
    event_subscriptions: [EcspanseStateMachine.Events.NodeTransition]

  def run(
        %EcspanseStateMachine.Events.NodeTransition{
          graph_entity_id: graph_entity_id,
          graph_name: graph_name,
          graph_metadata: graph_metadata,
          from_node_name: from_node_name,
          to_node_name: to_node_name,
          reason: _reason
        },
        _frame
      ) do
      # respond to the transition
  end
end
```

### Request a node transition

Node transitions happen when a node has a timeout and the timeout elapses or upon request. Submitting a request will cause the graph to transition from the current node to the target node.

The request will be executed so long as the graph is running, the current node is the same as the from node, and the target node is in the list of allowed exit states from the current node.

```elixir
  EcspanseStateMachine.submit_node_transition_request(graph_entity_id, :turn_start, :decision_phase)
```

In this example, :turn_start is the from node name and :decision_phase is the target node name.

<!-- MDOC !-->

### Stopping a graph

The graph will automatically stop when it reaches a node without allowed exit node names.

You can stop a graph from running anytime by submitting a stop graph request.

```elixir
  EcspanseStateMachine.submit_stop_graph_request(graph_entity_id)
```

The graph will be stopped and if the timeout timer of current node will be stopped (provided it has one).

#### graph stop events

You can listen for graph stopped events.

```elixir
defmodule OnGraphStopped do
  use Ecspanse.System,
    event_subscriptions: [EcspanseStateMachine.Events.GraphStopped]

  def run(
        %EcspanseStateMachine.Events.GraphStopped{
          entity_id: entity_id,
          name: name,
          metadata: metadata
        },
        _frame
      ) do
    IO.inspect(
      "Graph #{entity_id}, #{name} stopped, metadata: #{inspect(metadata)}"
    )
  end
end
```

### Despawning a graph

The systems api has a function to despawn a graph and it's nodes.

```elixir
    EcspanseStateMachine.despawn_graph(graph_entity_id)
```

## Generate a Mermaid State Diagram

After you have spawned a graph, you can get a [Mermaid.js](https://mermaid.js.org/) state diagram for it.

```elixir
  EcspanseStateMachine.as_mermaid_diagram(graph_entity_id)
```

Here's an example output.

```
---
title: battle_babae8bc-f0bc-4451-a568-da123ee2caa7
---
stateDiagram-v2
  [*] --> turn_start
  turn_start --> grenades_explode: ⏲️
  grenades_explode --> combatants_attack: ⏲️
  combatants_attack --> turn_end: ⏲️
  turn_end --> turn_start
  turn_end --> battle_end
  battle_end --> [*]
```

Which produces the following state diagram when rendered

[![](https://mermaid.ink/img/pako:eNp1kEFuwjAQRa9izbLCUkmhRV6w4gYs6yqa2AONiB3kTKpWiDNwF1acpxfoFTqOioJadWN7_vsjff8DuNYTGNBa28g1N2RUhSx3WWGFtKic3tzLMZvNpxrnjwvtcVo8EBUO8cnGYbFjZFrVuE0Y9Ftho1LPdy9K66XiPsVSeOKsjtMAt4kieupKet83EsSoz9P563LK1t9sWHBtkHQYuSslJLrd7cYfOAag6G-dV-2_hFf004SMGY3TAOWHWYUJBEoBay81HrJigV8pkAUjT49pZ8HGo_iw53b9ER0YTj1NoN_7sTcwG2w6On4DXdGPHQ?type=png)](https://mermaid.live/edit#pako:eNp1kEFuwjAQRa9izbLCUkmhRV6w4gYs6yqa2AONiB3kTKpWiDNwF1acpxfoFTqOioJadWN7_vsjff8DuNYTGNBa28g1N2RUhSx3WWGFtKic3tzLMZvNpxrnjwvtcVo8EBUO8cnGYbFjZFrVuE0Y9Ftho1LPdy9K66XiPsVSeOKsjtMAt4kieupKet83EsSoz9P563LK1t9sWHBtkHQYuSslJLrd7cYfOAag6G-dV-2_hFf004SMGY3TAOWHWYUJBEoBay81HrJigV8pkAUjT49pZ8HGo_iw53b9ER0YTj1NoN_7sTcwG2w6On4DXdGPHQ)
