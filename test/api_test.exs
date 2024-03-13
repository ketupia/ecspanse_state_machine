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

  describe "fetch_current" do
    test "not running returns error" do
      entity = Examples.traffic_light()
      assert {:error, :not_running} = EcspanseStateMachine.fetch_current(entity.id)
    end

    test "not found returns error" do
      assert {:error, :not_found} = EcspanseStateMachine.fetch_current("1234")
    end

    test "running returns :ok, state" do
      entity = Examples.traffic_light()
      Process.sleep(100)
      assert {:ok, :red} = EcspanseStateMachine.fetch_current(entity.id)
    end
  end

  describe "fetch_states" do
    test "not found returns error" do
      assert {:error, :not_found} = EcspanseStateMachine.fetch_states("1234")
    end

    test "returns :ok, states" do
      entity = Examples.traffic_light()

      assert {:ok, states} = EcspanseStateMachine.fetch_states(entity.id)
      assert :red in states
      assert :flashing_red in states
      assert :yellow in states
      assert :green in states
    end
  end

  describe "fetch_state_exits_to" do
    test "not found returns error" do
      assert {:error, :not_found} = EcspanseStateMachine.fetch_state_exits_to("1234", :red)
    end

    test "returns :ok, exits_to" do
      entity = Examples.traffic_light()

      assert {:ok, states} = EcspanseStateMachine.fetch_state_exits_to(entity.id, :red)
      assert :red not in states
      assert :flashing_red in states
      assert :yellow not in states
      assert :green in states
    end
  end
end
