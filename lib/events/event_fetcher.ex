defmodule Events.EventFetcher do
  @moduledoc false

  def init(manager) do
    loop(manager)
  end

  defp loop(manager) do
    send manager, {:ready, self}
    receive do
      _ -> loop(manager)
    end
  end

end