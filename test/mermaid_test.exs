defmodule StateMachineComponentValidationTest do
  use ExUnit.Case, async: false

  alias EcspanseStateMachine.StateMachine

  @moduledoc false

  defmodule EcspanseTest do
    @moduledoc false
    use Ecspanse
    @impl true
    def setup(data) do
      data
    end
  end

  setup do
    {:ok, _pid} = start_supervised({EcspanseTest, :test})
    Ecspanse.System.debug()
  end

  test "red light" do
    my_entity =
      Ecspanse.Command.spawn_entity!({
        Ecspanse.Entity,
        components: [
          {StateMachine.Components.StateMachine,
           [
             initial_state: :red,
             states: [
               [name: :red, exits_to: [:green]],
               [name: :green, exits_to: [:yellow]],
               [name: :yellow, exits_to: [:red]]
             ]
           ]}
        ]
      })

    mermaid = EcspanseStateMachine.as_mermaid_diagram(my_entity)

    IO.inspect(mermaid)

    assert mermaid != ""
  end
end
