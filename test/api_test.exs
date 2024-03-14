defmodule ApiTest do
  use ExUnit.Case, async: false

  @moduledoc false

  defmodule EcspanseTest do
    @moduledoc false
    use Ecspanse
    @impl true
    def setup(data) do
      data |> EcspanseStateMachine.setup()
    end
  end

  setup do
    {:ok, _pid} = start_supervised({EcspanseTest, :test})
    Ecspanse.System.debug()
  end

  describe "transitions" do
    test "not running returns error" do
      entity = Examples.traffic_light()
      assert {:error, :not_running} = EcspanseStateMachine.transition(entity.id, :red, :green)
    end

    test "not found returns error" do
      assert {:error, :not_found} = EcspanseStateMachine.transition("1234", :red, :green)
    end

    test "running returns :ok, state" do
      entity =
        Examples.traffic_light()

      Process.sleep(100)
      assert :ok = EcspanseStateMachine.transition(entity.id, :red, :green)
    end
  end
end
