defmodule EcspanseStateMachine.Projections.StateTimer do
  @moduledoc """
  The projection for a StateTimer component
  """
  alias EcspanseStateMachine.Components

  use Ecspanse.Projection,
    fields: [
      :paused,
      :timing_state,
      :time,
      :duration,
      :exits_to
    ]

  @impl true
  def project(%{entity_id: entity_id} = _attrs) do
    with {:ok, entity} <- Ecspanse.Entity.fetch(entity_id),
         {:ok, timer} <- Components.StateTimer.fetch(entity) do
      {paused, time, duration} =
        case timer.paused do
          true -> {true, nil, nil}
          false -> {false, timer.time, timer.duration}
        end

      {name, exits_to} =
        case timer.timing_state do
          nil ->
            {nil, nil}

          _ ->
            timeout = Components.StateTimer.get_timeout(timer, timer.timing_state)
            {timeout[:name], timeout[:exits_to]}
        end

      {:ok,
       struct!(__MODULE__,
         paused: paused,
         time: time,
         duration: duration,
         timing_state: name,
         exits_to: exits_to
       )}
    else
      _ -> :error
    end
  end

  @impl true
  def on_change(%{client_pid: pid} = _attrs, new_projection, _previous_projection) do
    # when the projection changes, send it to the client
    send(pid, {:projection_updated, new_projection})
  end
end
