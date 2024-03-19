defmodule EcspanseStateMachine.Types do
  defmacro __using__(_) do
    quote do
      @type state_name :: atom() | String.t()
    end
  end
end
