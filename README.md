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
2. [Spawn a graph and nodes](#spawn-a-graph-and-nodes)
3. [Start your graph](#start-your-graph)
4. [Listen for node transitions](#listen-for-node-transitions)
5. [Request a node transition](#request-a-node-transition)
6. [Stopping a graph](#stopping-a-graph)
7. [Despawning a graph](#despawning-a-graph)

### Register ESCpanse State Machine Systems

As part of your ESCpanse setup, you will have defined a `manager` with a `setup(data)` function. In that function, chain a call to the `ESCpanseStateMachine.Manager.setup`

```elixir
  def setup(data) do
    data
    # register the state machine's systems
    |> EcspanseStateMachine.Manager.setup()

    # Be sure to register the Ecspanse System Timer!
    |> Ecspanse.add_frame_end_system(Ecspanse.System.Timer)

    # register your systems too
```

ECSpanseStateMachine will add the systems it needs for you.

### Spawn a graph and nodes

A graph is a collection of nodes along with some state such as the starting node name and is running. Nodes represent the states in the state machine. Nodes have a name, a list of allowed exit transitions, and may have a timeout timer.

The `ECSpanse State Machine System Api` exposes functions to spawn a graph and it's nodes. Since you will be spawning nodes, you can only call these functions from within an `ECSpanse System`.

#### Spawn a graph

Here's an example of creating a graph.

```elixir
    {:ok, graph_entity_id} =
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
      graph_entity_id,
      :action_phase_end,
      [:decision_phase, :battle_end]
    )
```

The graph*entity is returned from the spawn_graph call above. `:action_phase_end` is the name of the node. Node names must be atoms and must be unique \_within* a graph. `[:decision_phase, :battle_end]` are the allowed exit transitions, the names of the nodes you can transition to from this node.

#### Spawn a node with a timeout timer ⏲️

Here's an example of spawning a node into the graph with a timeout timer. You can request a node transition to move from this state to one of the exit states or a state transition will automatically occur if the timer elapses.

```elixir
    EcspanseStateMachine.SystemsApi.spawn_node(
      graph_entity_id,
      :combatants_attack,
      [:combatants_move],
      :timer.seconds(1),
      :combatants_move
    )
```

The first 3 parameters are the same as before. This node is named `:combatants_attack` and there is only one allowed exit node specified `[:combatants_move]`. This node will automatically transition to `:combatants_move` after `:timer.seconds(1)`. The fourth parameter, `:timer.seconds(1)`, is the timer duration and the final parameter, `:combatants_move`, is the timeout node name. The timeout node name must be in the list of allowed exists.

### Start your graph

Once you have spawned your graph and it's nodes, you set the state machine in motion by issuing a start graph request. The graph will transition into the starting node.

```elixir
  EcspanseStateMachine.Api.submit_start_graph_request(graph_entity_id)
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
          graph_reference: graph_reference,
          previous_node_name: previous_node_name,
          current_node_name: current_node_name,
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

The request will be executed so long as the graph is running, the current node is the same, and the target node is in the list of allowed exit states from the current node.

```elixir
  EcspanseStateMachine.Api.submit_node_transition_request(graph_entity_id, :turn_start, :decision_phase)
```

In this example, :turn_start is the current node name and :decision_phase is the target node name.

<!-- MDOC !-->

### Stopping a graph

The graph will automatically stop when it reaches a node without allowed exit node names.

You can stop a graph from running anytime by submitting a stop graph request.

```elixir
  EcspanseStateMachine.Api.submit_stop_graph_request(graph_entity_id)
```

The graph will be stopped and if the timeout timer of current node will be stopped (provided it has one).

### Despawning a graph

The systems api has a function to despawn a graph and it's nodes.

```elixir
    EcspanseStateMachine.SystemsApi.despawn_graph(graph_entity_id)
```

## Validating your graph

If your graph is invalid, it won't start. EcspanseStateMachine will validate your graph and report back errors.

```elixir
    case EcspanseStateMachine.Api.validate_graph(graph_entity_id) do
      :ok -> IO.puts("graph is valid")
      {:error, :not_found} -> IO.puts("graph not found")
      {:error, reason} -> IO.puts("invalid :" <> reason)
    end
```

## Generate a Mermaid State Diagram

After you have spawned a graph, you can get a [Mermaid.js](https://mermaid.js.org/) state diagram for it.

```elixir
  EcspanseStateMachine.Api.as_mermaid_diagram(graph_entity_id)
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
