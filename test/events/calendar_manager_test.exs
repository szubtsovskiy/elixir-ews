defmodule Events.CalendarManagerTest do
  use ExUnit.Case
  use Timex
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

  describe "handle_info({:answer, ...}, ...)" do

    test "places EWS-calendar in the queue when there is no worker" do
      with cal = ews_calendar do
        test_answer(calendar: cal, incoming_state: {[], []}, expected_state: {[], [{:fetch, cal}]})
      end
    end

    test "places EWS-calendar in the queue when there is a worker" do
      with cal = ews_calendar do
        test_answer(calendar: cal, incoming_state: {[self], []}, expected_state: {[self], [{:fetch, cal}]})
      end
    end

    test "appends EWS-calendar to the end of the queue when there is no worker" do
      with cal1 = ews_calendar, cal2 = calendar do
        test_answer(calendar: cal1, incoming_state: {[], [{:fetch, cal2}]}, expected_state: {[], [{:fetch, cal2}, {:fetch, cal1}]})
      end
    end

    test "appends EWS-calendar to the end of the queue when there is a worker" do
      with cal1 = ews_calendar, cal2 = calendar do
        test_answer(calendar: cal1, incoming_state: {[self], [{:fetch, cal2}]}, expected_state: {[self], [{:fetch, cal2}, {:fetch, cal1}]})
      end
    end

    defp test_answer([calendar: cal, incoming_state: incoming_state, expected_state: {expected_workers, expected_commands}]) do
      {:noreply, state} = handle_info({:answer, cal, nil, nil}, incoming_state)
      {workers, commands} = state
      assert workers == expected_workers
      assert commands == expected_commands
    end
  end

  # TODO: test refreshed_at updated

  # TODO: test handle_info {:answer, ...} with events

  # TODO: refactor and group other tests

  ### PRIVATE API

  defp calendar(r_count \\ 1, kind  \\ :test) do
    {kind, r_count, "calendar" <> String.duplicate("r", r_count - 1), nil}
  end

  defp ews_calendar(r_count \\ 1) do
    calendar(r_count, :ews)
  end

end