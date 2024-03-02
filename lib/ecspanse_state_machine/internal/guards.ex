defmodule EcspanseStateMachine.Internal.Guards do
  defguard is_positive_integer(x) when is_integer(x) and x > 0

  defguard is_not_positive_integer(x) when not is_integer(x) or x <= 0
end
