defmodule Events.EventFetcher do
  @moduledoc false

  import Timex.DateTime, only: [now: 0]
  import Timex, only: [before?: 2, shift: 2]

  @update_frequency minutes: 15

  def init(manager) do
    loop(manager)
  end

  def seconds_to_next_update(refreshed_at) do
    with update_at = next_update(refreshed_at) do
      Timex.to_unix(update_at) - Timex.to_unix(now)
    end
  end

  defp next_update(last_update)  do
    cond do
      last_update == nil -> now
      shift(last_update, @update_frequency) |> before?(now) -> now
      true -> shift(last_update, @update_frequency)
    end
  end

  defp loop(manager) do
    send manager, {:ready, self}
    receive do
      {:fetch, cal} ->
        IO.puts "fetch #{inspect cal}"
        loop(manager)
      {:refresh, cal} ->
        IO.puts "refresh #{inspect cal}"
        loop(manager)
    end
  end

end