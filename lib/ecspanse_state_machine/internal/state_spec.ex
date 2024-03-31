defmodule EcspanseStateMachine.Internal.StateSpec do
  @moduledoc false
  # access functions for state keywords
  # Fields
  #   * name is required
  #   * exits, list(names), optional
  #   * timeout, pos_integer(),  optional
  #   * default_exit, name, optional
  use EcspanseStateMachine.Types

  @spec has_timeout?(keyword()) :: boolean()
  def has_timeout?(state), do: timeout(state) != nil

  @spec has_default_exit?(keyword()) :: boolean()
  def has_default_exit?(state),
    do: Keyword.has_key?(state, :default_exit) || length(exits(state)) > 0

  @spec has_exit?(keyword(), Types.state_name()) :: boolean()
  def has_exit?(state, to), do: to in exits(state)

  @spec exits(keyword()) :: Types.list(state_name())
  def exits(state), do: Keyword.get(state, :exits, [])

  @spec name(keyword()) :: Types.state_name() | nil
  def name(state), do: state[:name]

  @spec timeout(keyword()) :: pos_integer() | nil
  def timeout(state), do: Keyword.get(state, :timeout)

  @spec default_exit(keyword()) :: state_name() | nil
  def default_exit(state) do
    Keyword.get(state, :default_exit) || List.first(exits(state))
  end

  @spec validate(keyword()) :: :ok | {:error, String.t()}
  def validate(state) do
    with :ok <- validate_name(state),
         :ok <- validate_timeout(state) do
      validate_default_exit(state)
    end
  end

  defp validate_default_exit(state) do
    case {has_timeout?(state), default_exit(state), default_exit(state) in exits(state)} do
      {true, nil, _} -> {:error, "#{name(state)} has a timeout duration but no default exit"}
      {true, _, false} -> {:error, "#{name(state)}'s default_exit is not in the list of exits"}
      _ -> :ok
    end
  end

  defp validate_timeout(state) do
    case {has_timeout?(state), is_integer(timeout(state)), timeout(state) > 0} do
      {true, false, _} ->
        {:error,
         "#{name(state)} timeout duration, #{inspect(timeout(state))}, must be an integer"}

      {true, true, false} ->
        {:error,
         "#{name(state)} timeout duration, #{inspect(timeout(state))}, must be a positive integer"}

      _ ->
        :ok
    end
  end

  defp validate_name(state) do
    case {name(state), is_atom(name(state)) or is_binary(name(state))} do
      {nil, _} -> {:error, "States must have a name."}
      {_, false} -> {:error, "State names must be an atom or string"}
      _ -> :ok
    end
  end
end
