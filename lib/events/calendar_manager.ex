defmodule Events.CalendarManager do
  @moduledoc """
  Creates and manages worker processes capable of fetching events in a calendar.
  Sends calendars to workers for processing from an internal queue.
  Accepts new calendars and requests to refresh or remove them from queue.
  """
  
  use GenServer
  require Logger

  @doc """
  Starts manager and triggers initialization of worker processes.
  """
  def start_link() do
    GenServer.start_link(__MODULE__, [Events.EventLoader, :init, 10])
  end

  ### PUBLIC API

  @doc """
  Adds calendar to the internal queue. Calendar is a tuple in form `{kind, id, credentials, refreshed_at}`.
  Credentials is a tuple in form `{endpoint, user, password}` or `{refresh_token}` depending on the calendar's kind.

  ## Examples:
      iex> alias Events.CalendarManager
      iex> CalendarManager.add({:ews, "some id", {"https://example.org/EWS/Exchange.asmx", "user", "password"}, Timex.datetime({{2015, 11, 30}, {13, 30, 30}})})
      :ok
      iex> CalendarManager.add({:google, "some id", {"refresh_token"}, nil})
      :ok
      iex> CalendarManager.add({:ews, "some id", {"refresh_token"}, nil})
      {:error, :wrong_format}
  """
  def add(calendar) do
    case valid?(calendar) do
      false -> {:error, :wrong_format}
      true -> GenServer.cast(self, {:add, {calendar}})
    end
  end

  @doc """
  Forcibly fetches events in a calendar. See `add/1` for information about calendar format and examples.
  """
  def refresh(calendar) do
    case valid?(calendar) do
      false -> {:error, :wrong_format}
      true -> GenServer.cast(self, {:add, {calendar, :refresh}})
    end
  end

  @doc """
  Removes calendar from the internal queue. See `add/1` for information about calendar format and examples.
  """
  def remove(calendar) do
    GenServer.cast(self, {:remove, {calendar}})
  end


  ### CALLBACKS

  def init([module, func, count]) do
    Logger.info "Starting calendar manager with #{count} workers"
    (1..count)
        |> Enum.each(fn _ -> spawn(module, func, [self]) end)
    {:ok, {[], []}}
  end

  def handle_cast({:add, new_cal_spec}, {[], queue}) do
    {:noreply, {[], queue ++ [new_cal_spec]}}
  end

  def handle_cast({:add, new_cal_spec}, {[pid | other_workers], []}) do
    schedule(pid, {new_cal_spec})
    {:noreply, {other_workers, []}}
  end

  def handle_cast({:add, new_cal_spec}, {[pid | other_workers], [cal_spec | other_calendars]}) do
    schedule(pid, cal_spec)
    {:noreply, {other_workers, other_calendars ++ [new_cal_spec]}}
  end

  def handle_cast({:remove, cal}, {workers, queue}) do
    updated_queue = queue
                      |> List.delete({cal})
                      |> List.delete({cal, :refresh})

    {:noreply, {workers, updated_queue}}
  end

  def handle_info({:ready, pid}, [workers, []]) do
    {:noreply, [[pid | workers], []]}
  end

  def handle_info({:ready, pid}, [workers, [cal_spec | other_calendars]]) do
    schedule(pid, cal_spec)
    {:noreply, [workers, other_calendars]}
  end

  ### PRIVATE API

  defp valid?({:ews, _id, {_endpoint, _user, _password}, _refreshed_at}), do: true
  defp valid?({:google, _id, {_refresh_token}, _refreshed_at}), do: true
  defp valid?(_), do: false

  defp schedule(pid, {cal}) do
    send pid, {:fetch, cal}
  end

  defp schedule(pid, {cal, :refresh}) do
    send pid, {:fetch, cal, :force}
  end
end