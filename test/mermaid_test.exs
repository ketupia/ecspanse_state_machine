defmodule MermaidTest do
  use ExUnit.Case, async: false

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
    entity =
      Ecspanse.Command.spawn_entity!({
        Ecspanse.Entity,
        components: [
          EcspanseStateMachine.state_machine(
            :red,
            [
              [name: :red, exits_to: [:green]],
              [name: :green, exits_to: [:yellow]],
              [name: :yellow, exits_to: [:red]]
            ]
          )
        ]
      })

    mermaid = EcspanseStateMachine.as_mermaid_diagram(entity.id)

    assert mermaid =~ "stateDiagram-v2"
  end
end
