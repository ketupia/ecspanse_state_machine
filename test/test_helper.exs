ExUnit.start()

defmodule Examples do
  def traffic_light() do
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
end
