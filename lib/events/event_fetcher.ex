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
      {:fetch, {:ews, _id, {endpoint, user, password}, refreshed_at} = cal} ->
        cond do
          seconds_to_next_update(refreshed_at) == 0 ->
            {:ok, events} = Events.Ews.get_calendar_events(endpoint, user, password)
            send manager, {:answer, cal, now, events}
            loop(manager)
          true ->
            send manager, {:answer, cal, refreshed_at, nil}
            loop(manager)
        end
        loop(manager)
      {:refresh, {:ews, _id, {endpoint, user, password}, _refreshed_at} = cal} ->
        {:ok, events} = Events.Ews.get_calendar_events(endpoint, user, password)
        send manager, {:answer, cal, now, events}
        loop(manager)
    end
  end

end