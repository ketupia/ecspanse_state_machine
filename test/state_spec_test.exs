defmodule StateSpecTest do
  @moduledoc false
  use ExUnit.Case

  describe "validate_name" do
    test "no name" do
      state = [exits: []]
      assert {:error, reason} = EcspanseStateMachine.Internal.StateSpec.validate(state)
      assert reason =~ "States must have a name"
    end

    test "integer name" do
      state = [name: 4, exits: []]
      assert {:error, reason} = EcspanseStateMachine.Internal.StateSpec.validate(state)
      assert reason =~ "State names must be an atom or string"
    end
  end

  describe "validate_timeout" do
    test "string timeout" do
      state = [name: :red, exits: [:yellow], timeout: "1000"]
      assert {:error, reason} = EcspanseStateMachine.Internal.StateSpec.validate(state)
      assert reason =~ "must be an integer"
    end

    test "zero timeout" do
      state = [name: :red, exits: [:yellow], timeout: 0]
      assert {:error, reason} = EcspanseStateMachine.Internal.StateSpec.validate(state)
      assert reason =~ "must be a positive integer"
    end

    test "negative timeout" do
      state = [name: :red, exits: [:yellow], timeout: -1000]
      assert {:error, reason} = EcspanseStateMachine.Internal.StateSpec.validate(state)
      assert reason =~ "must be a positive integer"
    end
  end

  describe "validate_default_exit" do
    test "timeout without any exits" do
      state = [name: :red, exits: [], timeout: 1000]
      assert {:error, reason} = EcspanseStateMachine.Internal.StateSpec.validate(state)
      assert reason =~ "has a timeout duration but no default exit"
    end

    test "timeout specified default exit not in list" do
      state = [name: :red, exits: [], default_exit: :yellow, timeout: 1000]
      assert {:error, reason} = EcspanseStateMachine.Internal.StateSpec.validate(state)
      assert reason =~ "default_exit is not in the list of exits"
    end
  end
end
