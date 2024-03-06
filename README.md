# EcspanseStateMachine

<!-- MDOC !-->

`ECSpanse State Machine` is a state machine implementation for [`ECSpanse`](https://hexdocs.pm/ecspanse).

[![](https://mermaid.ink/img/pako:eNpNkD0OwjAMha8SeUTtwpiBiZWJkSBkNW4bkR-UpqCq6hl6FybOwwW4Ammrqtn8vvcs-bmHwkkCDk3AQEeFlUeTP_fCMnbZXVmeH5gnOclSY1MrW92iTvkqU3_iHWntXmuSs-_4_n3GdKPyRDY1ZjBby_LmQQaGvEEl4639lBUQajIkgMdRor8LEHaIOWyDO3e2AB58Sxm0D7lVA16ibiIlqYLzp6X8_IPhD-E_XkE?type=png)](https://mermaid.live/edit#pako:eNpNkD0OwjAMha8SeUTtwpiBiZWJkSBkNW4bkR-UpqCq6hl6FybOwwW4Ammrqtn8vvcs-bmHwkkCDk3AQEeFlUeTP_fCMnbZXVmeH5gnOclSY1MrW92iTvkqU3_iHWntXmuSs-_4_n3GdKPyRDY1ZjBby_LmQQaGvEEl4639lBUQajIkgMdRor8LEHaIOWyDO3e2AB58Sxm0D7lVA16ibiIlqYLzp6X8_IPhD-E_XkE)

<!-- MDOC !-->

## Features

- Every entity can have a state machine executing simultaneously - create, start, and stop independently
- Validation - all states must be defined and reachable
- State changes on request or timeout
- Register for State Change events
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

1. [Register the state machine's ECSpanse systems](#register-escpansestatemachine-systems)
2. [Adding a state machine](#adding-a-state-machine)
3. [Starting your state machine](#starting-your-state-machine)
4. [Adding timeouts](#adding-timeouts)
5. [Listen for state changes](#listen-for-state-changes)
6. [Request a node transition](#request-a-node-transition)
7. [Stopping a graph](#stopping-a-graph)
8. [Despawning a graph](#despawning-a-graph)

### Register ESCpanseStateMachine Systems

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

### Adding a state machine

The state machine is an ECSpanse component. You add it to your entity's spec in the components list. EcspanseStateMachine.state_machine is a convenience API function to create the state machine component.

```elixir
    traffic_light =
      Ecspanse.Command.spawn_entity!({
        Ecspanse.Entity,
        components: [
          EcspanseStateMachine.state_machine(:red, [
            [name: :red, exits_to: [:green, :flashing_red]],
            [name: :flashing_red, exits_to: [:red]],
            [name: :green, exits_to: [:yellow]],
            [name: :yellow, exits_to: [:red]]
          ])
        ]
      })
```

### Starting your state machine

The default behavior is to automatically start a state machine. If you don't want that behavior, then you can 'set auto_start to false' and call 'EcspanseStateMachine.start' when you're ready.

Auto start is the third parameter to EcspanseStateMachine.state_machine().

```elixir
    traffic_light =
      Ecspanse.Command.spawn_entity!({
        Ecspanse.Entity,
        components: [
          EcspanseStateMachine.state_machine(:red, [
            [name: :red, exits_to: [:green, :flashing_red]],
            [name: :flashing_red, exits_to: [:red]],
            [name: :green, exits_to: [:yellow]],
            [name: :yellow, exits_to: [:red]]
          ], false)
        ]
      })

  # some time later
  EcspanseStateMachine.start(traffic_light.id)
```

### Adding timeouts

State timer is another component. You add it to your entity's spec in the components list just like you did with the state machine. EcspanseStateMachine.state_timer is a convenience API function to create the state state timer component.

```elixir
    traffic_light_with_timer =
      Ecspanse.Command.spawn_entity!({
        Ecspanse.Entity,
        components: [
          EcspanseStateMachine.state_machine(:red, [
            [name: :red, exits_to: [:green, :flashing_red]],
            [name: :flashing_red, exits_to: [:red]],
            [name: :green, exits_to: [:yellow]],
            [name: :yellow, exits_to: [:red]]
          ]),
          EcspanseStateMachine.state_timer([
            [name: :red, duration: :timer.seconds(30), exits_to: :green],
            [name: :green, duration: :timer.seconds(10), exits_to: :yellow],
            [name: :yellow, duration: :timer.seconds(5), exits_to: :red]
          ])
        ]
      })
```

Now your state machine will automatically change states when timeouts occur. In this example, :red will transition to :green after 30 seconds.

You can still change state through the api before the timer elapses.

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

### Listen for state changes

ECSpanseStateMachine publishes `Started`, `Stopped`, and `StateChanged` events. State changed is the primary event. It's your chance to take action after a transition.

```elixir
defmodule OnStateChanged do
  use Ecspanse.System,
    event_subscriptions: [EcspanseStateMachine.Events.StateChanged]

  def run(
        %EcspanseStateMachine.Events.StateChanged{
          entity_id: graph_entity_id,
          from: from,
          to: to,
          trigger: _trigger
        },
        _frame
      ) do
      # respond to the transition
  end
end
```

### Request a state change

State changes happen when a timeout elapses or upon request. Call `ECSPanseStateMachine.change_state` to trigger a transition.

```elixir
  EcspanseStateMachine.change_state(entity_id, :red, :flashing_red)
```

Here were changing state from :red to :flashing_red.

<!-- MDOC !-->

### Stopping a graph

The graph will automatically stop when it reaches a state without allowed exit node names.

You can stop a graph from running anytime by submitting a stop graph request.

```elixir
  EcspanseStateMachine.stop(entity_id)
```

The graph will be stopped and if the timeout timer of current node will be stopped (provided it has one).

## Generate a Mermaid State Diagram

ECSpanseStateMachine can generate a [Mermaid.js](https://mermaid.js.org/) state diagram for your graph.

```elixir
  EcspanseStateMachine.as_mermaid_diagram(entity_id)
```

Here's an example output.

```
stateDiagram-v2
  [*] --> red
  flashing_red --> red
  green --> yellow: ⏲️
  red --> flashing_red
  red --> green: ⏲️
  yellow --> red: ⏲️
```

Which produces the following state diagram when rendered

[![](https://mermaid.ink/img/pako:eNpNkD0OwjAMha8SeUTtwpiBiZWJkSBkNW4bkR-UpqCq6hl6FybOwwW4Ammrqtn8vvcs-bmHwkkCDk3AQEeFlUeTP_fCMnbZXVmeH5gnOclSY1MrW92iTvkqU3_iHWntXmuSs-_4_n3GdKPyRDY1ZjBby_LmQQaGvEEl4639lBUQajIkgMdRor8LEHaIOWyDO3e2AB58Sxm0D7lVA16ibiIlqYLzp6X8_IPhD-E_XkE?type=png)](https://mermaid.live/edit#pako:eNpNkD0OwjAMha8SeUTtwpiBiZWJkSBkNW4bkR-UpqCq6hl6FybOwwW4Ammrqtn8vvcs-bmHwkkCDk3AQEeFlUeTP_fCMnbZXVmeH5gnOclSY1MrW92iTvkqU3_iHWntXmuSs-_4_n3GdKPyRDY1ZjBby_LmQQaGvEEl4639lBUQajIkgMdRor8LEHaIOWyDO3e2AB58Sxm0D7lVA16ibiIlqYLzp6X8_IPhD-E_XkE)
