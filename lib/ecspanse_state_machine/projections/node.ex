defmodule EcspanseStateMachine.Projections.Node do
  @moduledoc """
  The projection for a node
  """
  alias EcspanseStateMachine.Components

  use Ecspanse.Projection,
    fields: [
      :name,
      :allowed_exit_node_names,
      :has_timer,
      :timeout_node_name
    ]

  @impl true
  def project(%{entity_id: entity_id} = _attrs) do
    with {:ok, node_entity} <- Ecspanse.Entity.fetch(entity_id),
         {:ok, node_component} <- Components.Node.fetch(node_entity) do
      {:ok, struct!(__MODULE__, Map.to_list(node_component))}
    else
      _ -> :error
    end
  end

  @impl true
  @spec on_change(
          %{
            :client_pid => atom() | pid() | port() | reference() | {atom(), atom()},
            optional(any()) => any()
          },
          any(),
          any()
        ) :: any()
  def on_change(%{client_pid: pid} = _attrs, new_projection, _previous_projection) do
    # when the projection changes, send it to the client
    send(pid, {:projection_updated, new_projection})
  end
end
