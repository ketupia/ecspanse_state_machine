ExUnit.start()

defmodule Examples do
  @moduledoc false

  def simple_ai() do
    state_machine =
      EcspanseStateMachine.new(
        :idle,
        [
          [name: :idle, exits: [:patrol, :fight], timeout: 5_000],
          [name: :patrol, exits: [:fight, :idle], timeout: 10_000, default_exit: :idle],
          [name: :fight, exits: [:idle, :die]],
          [name: :die]
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
          [name: :green, exits: [:yellow], timeout: 10_000],
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
