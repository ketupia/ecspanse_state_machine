defmodule EcspanseStateMachine.Components.StateTimer do
  @moduledoc """
  The timer component for states that have a timeout

  ## Fields
  * timeouts: [:name, :duration, :exits_to]
  """
  use Ecspanse.Template.Component.Timer,
    state: [
      duration: 5_000,
      time: 5_000,
      event: EcspanseStateMachine.Internal.Events.StateTimeout,
      mode: :once,
      paused: true,
      timeouts: [],
      timing_state: nil
    ],
    tags: [:ecspanse_state_machine_timeout_timer]

  def has_timeout?(timer, name), do: get_timeout(timer, name) != nil

  def get_timeout(timer, name) do
    Enum.find(timer.timeouts, &(&1[:name] == name))
  end

  def validate(component) do
    with :ok <- verify_timeout_names(component),
         :ok <- verify_timeout_durations(component),
         :ok <- verify_timeout_exits(component) do
      :ok
    end
  end

  defp verify_timeout_exits(component) do
    timeouts_with_exits =
      Enum.filter(component.timeouts, &Keyword.has_key?(&1, :exits_to))

    case length(component.timeouts) == length(timeouts_with_exits) do
      false -> {:error, "Timeouts must have a exits_to"}
      _ -> :ok
    end
  end

  defp verify_timeout_durations(component) do
    durations =
      Enum.filter(component.timeouts, &Keyword.has_key?(&1, :duration))
      |> Enum.map(& &1[:duration])

    valid_durations = Enum.filter(durations, fn d -> is_integer(d) and d > 0 end)

    case {length(component.timeouts) == length(durations),
          length(durations) == length(valid_durations)} do
      {false, _} -> {:error, "Timeouts must have a duration"}
      {_, false} -> {:error, "Durations must be integers greater than 0."}
      _ -> :ok
    end
  end

  defp verify_timeout_names(component) do
    names =
      Enum.filter(component.timeouts, &Keyword.has_key?(&1, :name))
      |> Enum.map(& &1[:name])

    unique_names = names |> Enum.uniq()

    case {length(component.timeouts) == length(names), length(names) == length(unique_names)} do
      {false, _} -> {:error, "Timeouts must have a name"}
      {_, false} -> {:error, "Timeout names must be unique."}
      _ -> :ok
    end
  end
end
