# EcspanseStateMachine

`ECSpanse State Machine` is a state machine implementation for [`ECSpanse`](https://hexdocs.pm/ecspanse).

[![](https://mermaid.ink/img/pako:eNpNkD0OwjAMha8SeUTtwpiBiZWJkSBkNW4bkR-UpqCq6hl6FybOwwW4Ammrqtn8vvcs-bmHwkkCDk3AQEeFlUeTP_fCMnbZXVmeH5gnOclSY1MrW92iTvkqU3_iHWntXmuSs-_4_n3GdKPyRDY1ZjBby_LmQQaGvEEl4639lBUQajIkgMdRor8LEHaIOWyDO3e2AB58Sxm0D7lVA16ibiIlqYLzp6X8_IPhD-E_XkE?type=png)](https://mermaid.live/edit#pako:eNpNkD0OwjAMha8SeUTtwpiBiZWJkSBkNW4bkR-UpqCq6hl6FybOwwW4Ammrqtn8vvcs-bmHwkkCDk3AQEeFlUeTP_fCMnbZXVmeH5gnOclSY1MrW92iTvkqU3_iHWntXmuSs-_4_n3GdKPyRDY1ZjBby_LmQQaGvEEl4639lBUQajIkgMdRor8LEHaIOWyDO3e2AB58Sxm0D7lVA16ibiIlqYLzp6X8_IPhD-E_XkE)

## Features

- Every entity can have a state machine executing simultaneously - create, start, and stop independently
- Validation - all states must be defined and reachable
- State changes on request or timeout
- Register for State Change events
- Telemetry
- Mermaid state diagram generation

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ecspanse_state_machine` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecspanse_state_machine, "~> 0.2.0"}
  ]
end
```

## How to Use

1. [Systems Setup](#systems-setup)
2. [Add a state machine](#add-a-state-machine)
3. [Starting your state machine](#starting-your-state-machine)
4. [Adding timeouts](#adding-timeouts)
5. [Listen for state changes](#listen-for-state-changes)
6. [Request a state change](#request-a-state-change)
7. [Stopping a state machine](#stopping-a-state-machine)

### Systems Setup

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

### Add a state machine

The state machine is an ECSpanse component. You add it to your entity's spec in the components list. `EcspanseStateMachine.state_machine` is a convenience API function to create the state machine component.

1. Create a state machine component spec

```elixir
    traffic_light_component_spec =
      EcspanseStateMachine.state_machine(:red, [
        [name: :red, exits_to: [:green, :flashing_red]],
        [name: :flashing_red, exits_to: [:red]],
        [name: :green, exits_to: [:yellow]],
        [name: :yellow, exits_to: [:red]]
      ])
```

2. Include the component in your entity

```elixir
    Ecspanse.Command.spawn_entity!({
      Ecspanse.Entity,
      components: [
        traffic_light_component_spec
      ]
    })
```

> #### Tip {: .info}
>
> You can call the function to create the state machine directly in the list of components for your entity (step 2 above).

### Starting your state machine

The default behavior is to automatically start a state machine. If you don't want that behavior, then you can 'set auto_start to false' and call `EcspanseStateMachine.request_start` when you're ready.

Auto start is an option, the third parameter to EcspanseStateMachine.state_machine().

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
  EcspanseStateMachine.request_start(traffic_light.id)
```

### Adding timeouts

The State timer component adds changing state on timeout. You add it to your entity's spec in the components list just like you did with the state machine. `EcspanseStateMachine.state_timer` is a convenience API function to create the state timer component.

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

**_note:_** You can still change state through the api before the timer elapses.

### Listen for state changes

ECSpanseStateMachine publishes `Started`, `Stopped`, and `StateChanged` events. State changed is the primary event. It's your chance to take action after a transition.

```elixir
defmodule OnStateChanged do
  use Ecspanse.System,
    event_subscriptions: [EcspanseStateMachine.Events.StateChanged]

  def run(
        %EcspanseStateMachine.Events.StateChanged{
          entity_id: entity_id,
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

State changes happen when a timeout elapses or upon request. Call `ECSPanseStateMachine.request_transition` to trigger a transition.

```elixir
  EcspanseStateMachine.request_transition(entity_id, :red, :flashing_red)
```

Here were changing state from :red to :flashing_red.

### Stopping a state machine

The state machine will automatically stop when it reaches a state no exits.

You can stop a state machine anytime by calling `ECSpanseStateMachine.request_stop`.

```elixir
  EcspanseStateMachine.request_stop(entity_id)
```

## Telemetry

ECSpanse State Machine implements telemetry for the following events.

| event name                         | measurement | metadata             | description                     |
| ---------------------------------- | ----------- | -------------------- | ------------------------------- |
| ecspanse_state_machine.start       | system_time | state_machine        | Executed on state machine start |
| ecspanse_state_machine_stop        | duration    | state_machine        | Executed on state machine stop  |
| ecspanse_state_machine.state.start | system_time | state_machine, state | Executed on entering a state    |
| ecspanse_state_machine.state.stop  | duration    | state_machine, state | Executed on exiting a state     |

## Mermaid State Diagrams

ECSpanseStateMachine generates [Mermaid.js](https://mermaid.js.org/) state diagrams for your state machines and state timers.

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
