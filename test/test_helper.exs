ExUnit.start()

defmodule Examples do
  @moduledoc false
  def traffic_light() do
    traffic_light_component_spec =
      EcspanseStateMachine.state_machine(:red, [
        [name: :red, exits_to: [:green, :flashing_red]],
        [name: :flashing_red, exits_to: [:red]],
        [name: :green, exits_to: [:yellow]],
        [name: :yellow, exits_to: [:red]]
      ])

    Ecspanse.Command.spawn_entity!({
      Ecspanse.Entity,
      components: [
        traffic_light_component_spec
      ]
    })
  end

  def traffic_light_with_timer() do
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
  end

  def game_turn_loop() do
    Ecspanse.Command.spawn_entity!({
      Ecspanse.Entity,
      components: [
        EcspanseStateMachine.state_machine("turn starts", [
          [name: "turn starts", exits_to: ["player 1"]],
          [name: "player 1", exits_to: ["player 2"]],
          [name: "player 2", exits_to: [:player3]],
          [name: :player3, exits_to: [:turn_end]],
          [name: :turn_end, exits_to: ["turn starts"]]
        ])
      ]
    })
  end
end
