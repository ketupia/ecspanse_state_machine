defmodule EcspanseStateMachine.Types do
  @moduledoc false
  defmacro __using__(_) do
    quote do
      @typedoc "state names can be an atom or a string"
      @type state_name :: atom() | String.t()
    end
  end
end
