defmodule Events.CalendarManagerTest do
  use ExUnit.Case
  doctest Events.CalendarManager

  import Events.CalendarManager, only: [handle_cast: 2, handle_info: 2]

  test ":add schedules fetching if there is a worker" do
    {:noreply, _state} = handle_cast({:add, calendar}, {[self], []})
    receive do
      {:fetch, cal} -> assert cal == calendar
      after 1000 -> flunk "Did not receive :fetch message"
    end
  end

  test ":add places command in the queue if there is no worker" do
    {:noreply, state} = handle_cast({:add, calendar}, {[], []})
    {_workers, commands} = state
    assert commands == [{:fetch, calendar}]
  end

  test ":add appends command to the end of the queue if there is no worker" do
    {:noreply, state} = handle_cast({:add, calendar}, {[], [{:fetch, calendar(2)}]})
    {_workers, commands} = state
    assert commands == [{:fetch, calendar(2)}, {:fetch, calendar}]
  end

  test ":refresh schedules refreshing if there is a worker" do
    {:noreply, _} = handle_cast({:refresh, calendar}, {[self], []})
    receive do
      {:refresh, cal} -> assert cal == calendar
      after 1000 -> flunk "Did not receive :refresh message"
    end
  end

  test ":refresh places command in the queue if there is no worker" do
    {:noreply, state} = handle_cast({:refresh, calendar}, {[], []})
    {_workers, commands} = state
    assert commands == [{:refresh, calendar}]
  end

  test ":refresh appends command to the end of the queue if there is no worker" do
    {:noreply, state} = handle_cast({:refresh, calendar}, {[], [{:fetch, calendar(2)}]})
    {_workers, commands} = state
    assert commands == [{:fetch, calendar(2)}, {:refresh, calendar}]
  end

  test ":remove removes :fetch command from the queue" do
    {:noreply, state} = handle_cast({:remove, calendar}, {[], [{:fetch, calendar}]})
    {_workers, commands} = state
    assert commands == []
  end

  test ":remove removes :refresh command from the queue" do
    {:noreply, state} = handle_cast({:remove, calendar}, {[], [{:refresh, calendar}]})
    {_workers, commands} = state
    assert commands == []
  end

  test ":ready schedules next command if queue is not empty" do
    {:noreply, _} = handle_info({:ready, self}, {[], [{:fetch, calendar}]})
    receive do
      {:fetch, cal} -> assert cal == calendar
      after 1000 -> flunk "Did not receive :fetch message"
    end
  end

  test ":ready places worker in pool if queue is empty" do
    {:noreply, state} = handle_info({:ready, self}, {[], []})
    {workers, _commands} = state
    assert workers == [self]
  end

  test ":ready appends worker to the end of the pool if queue is empty" do
    {:noreply, state} = handle_info({:ready, self}, {[self], []})
    {workers, _commands} = state
    assert workers == [self, self]
  end

  defp calendar(r_count \\ 1) do
    {"calendar" <> String.duplicate("r", r_count - 1)}
  end

end