defmodule Membrane.Pad.Mode.Pull do
  @moduledoc false
  # Module contains logic that causes sink pads in the pull mode to actually
  # generate demand for new buffers and forward these buffers to the parent
  # element's handle_buffer callback so it can consume them.
  #
  # It enters a loop and demands new chunk of data after each call to the
  # handle_buffer callback of the parent element so if element is sink that
  # has limited throughput, and it is using blocking calls, it will limit
  # also throughput of the pipeline which is desired in many cases.


  use Membrane.Pad.Mode
  use Membrane.Mixins.Log


  # Private API

  @doc false
  # Received from parent element in reaction to the :demand action.
  # Returns error if pad is not linked, so demand cannot be satisfied.
  def handle_call(:membrane_demand, _parent, nil, :sink, state) do
    debug("Demand on non-linked sink pad")
    {:reply, {:error, :not_linked}, state}
  end

  # Received from parent element in reaction to the :demand action.
  # Forwards demand request to the peer but does not wait for reply.
  def handle_call(:membrane_demand, _parent, peer, :sink, state) do
    debug("Demand on sink pad")
    send(peer, :membrane_demand)
    {:reply, :ok, state}
  end

  # Received from parent element in reaction to the :buffer action.
  # Returns error if pad is not linked, so send cannot succeed.
  def handle_call({:membrane_buffer, buffer}, _parent, nil, :source, state) do
    debug("Buffer on non-linked source pad, buffer = #{inspect(buffer)}")
    {:reply, {:error, :not_linked}, state}
  end

  # Received from parent element in reaction to the :buffer action.
  # Forwards demand request to the peer but does not wait for reply.
  def handle_call({:membrane_buffer, buffer}, _parent, peer, :source, state) do
    debug("Buffer on source pad, buffer = #{inspect(buffer)}")
    send(peer, {:membrane_buffer, buffer})
    {:reply, :ok, state}
  end


  @doc false
  # Received at source pads when their peer sink pad got demand request.
  # Forwards demand request to the parent element but does not wait for reply.
  def handle_other(:membrane_demand, parent, _peer, :source, state) do
    debug("Demand on source pad")
    send(parent, {:membrane_demand, self()})
    {:ok, state}
  end

  # Received at sink pads when their peer source pad got send action.
  # Forwards data to the parent element but does not wait for reply.
  def handle_other({:membrane_buffer, buffer}, parent, _peer, :sink, state) do
    debug("Buffer on sink pad, buffer = #{inspect(buffer)}")
    send(parent, {:membrane_buffer, self(), :pull, buffer})
    {:ok, state}
  end
end