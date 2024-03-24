ExUnit.start()

defmodule EcspanseTest do
  @moduledoc false
  use Ecspanse
  @impl true
  def setup(data) do
    data
    |> EcspanseStateMachine.setup()
    |> Ecspanse.add_system(EcspanseTest.OnStart)
    |> Ecspanse.add_system(EcspanseTest.OnStateChanged)
    |> Ecspanse.add_system(EcspanseTest.OnStopped)
  end

  defmodule OnStart do
    @moduledoc false
    use Ecspanse.System,
      event_subscriptions: [EcspanseStateMachine.Events.Started]

    def run(%EcspanseStateMachine.Events.Started{entity_id: _entity_id}, _frame) do
    end
  end

  defmodule OnStateChanged do
    @moduledoc false
    use Ecspanse.System,
      event_subscriptions: [EcspanseStateMachine.Events.StateChanged]

    def run(
          %EcspanseStateMachine.Events.StateChanged{
            entity_id: _entity_id,
            from: _from,
            to: _to,
            trigger: _trigger
          },
          _frame
        ) do
    end
  end

  defmodule OnStopped do
    @moduledoc false
    use Ecspanse.System,
      event_subscriptions: [EcspanseStateMachine.Events.Stopped]

    def run(%EcspanseStateMachine.Events.Stopped{entity_id: _entity_id}, _frame) do
    end
  end

  def frame() do
    %Ecspanse.Frame{event_batches: [[]], delta: 1}
  end

  def frame(event) do
    %Ecspanse.Frame{event_batches: [[event]], delta: 1}
  end
end

defmodule Examples do
  @moduledoc false

  defmodule DummyComponent do
    @moduledoc false
    use Ecspanse.Component, state: [x: 1]
  end

  def no_state_machine() do
    Ecspanse.Command.spawn_entity!({
      Ecspanse.Entity,
      components: [DummyComponent]
    })
  end

  def simple_ai_no_auto_start() do
    state_machine =
      EcspanseStateMachine.new(
        :idle,
        [
          [name: :die],
          [name: :idle, exits: [:patrol, :fight], timeout: 5_000],
          [name: :patrol, exits: [:fight, :idle], timeout: 10_000, default_exit: :idle],
          [name: :fight, exits: [:idle, :die]]
        ],
        auto_start: false
      )

    Ecspanse.Command.spawn_entity!({
      Ecspanse.Entity,
      components: [state_machine]
    })
  end

  def traffic_light() do
    state_machine =
      EcspanseStateMachine.new(:red, [
        [name: :red, exits: [:green, :flashing_red]],
        [name: :flashing_red, exits: [:red]],
        [name: :green, exits: [:yellow]],
        [name: :yellow, exits: [:red]]
      ])

    Ecspanse.Command.spawn_entity!({
      Ecspanse.Entity,
      components: [
        state_machine
      ]
    })
  end

  def traffic_light_with_timeouts() do
    Ecspanse.Command.spawn_entity!({
      Ecspanse.Entity,
      components: [
        EcspanseStateMachine.new(:red, [
          [
            name: :red,
            exits: [:green, :flashing_red],
            timeout: 30_000,
            default_exit: :green
          ],
          [name: :flashing_red, exits: [:red]],
          [name: :green, exits: [:yellow], timeout: 100],
          [name: :yellow, exits: [:red], timeout: 5_000]
        ])
      ]
    })
  end

  def mixed_state_names() do
    Ecspanse.Command.spawn_entity!({
      Ecspanse.Entity,
      components: [
        EcspanseStateMachine.new("turn starts", [
          [name: "turn starts", exits: ["player 1"]],
          [name: "player 1", exits: ["player 2"]],
          [name: "player 2", exits: [:player3]],
          [name: :player3, exits: [:turn_end]],
          [name: :turn_end, exits: ["turn starts", :battle_end]],
          [name: :battle_end]
        ])
      ]
    })
  end
end
