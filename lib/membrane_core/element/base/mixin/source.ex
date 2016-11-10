defmodule Membrane.Element.Base.Mixin.Source do
  defmacro __using__(_) do
    quote location: :keep do
      def link(server, destination) do
        debug("Link #{inspect(destination)} -> #{inspect(server)}")
        GenServer.call(server, {:membrane_link, destination})
      end


      def send_buffer(server, buffer) when is_tuple(buffer) do
        debug("Send buffer #{inspect(buffer)} -> #{inspect(server)}")
        GenServer.call(server, {:membrane_send_buffer, buffer})
      end


      def handle_call({:membrane_link, destination}, _from, %{link_destinations: link_destinations} = state) do
        case Enum.find(link_destinations, fn(x) -> x == destination end) do
          nil ->
            debug("Handle Link: OK, #{inspect(destination)} added")
            {:reply, :ok, %{state | link_destinations: link_destinations ++ [destination]}}

          _ ->
            warn("Handle Link: Error, #{inspect(destination)} already present")
            {:reply, :noop, state}
        end
      end


      def handle_call({:membrane_send_buffer, buffer}, _from, %{link_destinations: link_destinations} = state) do
        :ok = send_buffer_loop(buffer, link_destinations)
        {:reply, :ok, state}
      end
    end
  end
end