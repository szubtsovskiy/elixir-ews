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
      true -> GenServer.cast(self, {:add, calendar})
    end
  end

  @doc """
  Forcibly fetches events in a calendar. See `add/1` for information about calendar format and examples.
  """
  def refresh(calendar) do
    case valid?(calendar) do
      false -> {:error, :wrong_format}
      true -> GenServer.cast(self, {:refresh, calendar})
    end
  end

  @doc """
  Removes calendar from the internal queue. See `add/1` for information about calendar format and examples.
  """
  def remove(calendar) do
    GenServer.cast(self, {:remove, calendar})
  end


  ### CALLBACKS

  def init([module, func, count]) do
    Logger.info "Starting calendar manager with #{count} workers"
    (1..count)
        |> Enum.each(fn _ -> spawn(module, func, [self]) end)
    {:ok, {[], []}}
  end

  def handle_cast({:add, cal}, state) do
    case state do
      {[], commands} -> {:noreply, {[], commands ++ [{:fetch, cal}]}}
      {[worker | rest], commands} ->
        send worker, {:fetch, cal}
        {:noreply, {rest, commands}}
    end
  end

  def handle_cast({:refresh, cal}, state) do
    case state do
      {[], commands} -> {:noreply, {[], commands ++ [{:refresh, cal}]}}
      {[worker | rest], commands} ->
        send worker, {:refresh, cal}
        {:noreply, {rest, commands}}
    end
  end

  def handle_cast({:remove, cal}, {workers, queue}) do
    updated_queue = queue
                      |> List.delete({:fetch, cal})
                      |> List.delete({:refresh, cal})

    {:noreply, {workers, updated_queue}}
  end

  def handle_info({:ready, pid}, {workers, []}) do
    {:noreply, {[pid | workers], []}}
  end

  def handle_info({:ready, pid}, {workers, [cmd | commands]}) do
    send pid, cmd
    {:noreply, {workers, commands}}
  end

  def handle_info({:answer, calendar, _new_refreshed_at, _events}, {workers, commands}) do
    new_state = case calendar do
      {:ews, _, _, _} -> {workers, commands ++ [{:fetch, calendar}]}
      {:google, _, _, _} -> {workers, commands}
    end
    {:noreply, new_state}
  end

  ### PRIVATE API

  defp valid?({:ews, _id, {_endpoint, _user, _password}, _refreshed_at}), do: true
  defp valid?({:google, _id, {_refresh_token}, _refreshed_at}), do: true
  defp valid?(_), do: false

end