defmodule Events.EventFetcherTest do
  use ExUnit.Case
  use Timex

  doctest Events.EventFetcher

  @moduledoc false

  import Events.EventFetcher, only: [seconds_to_next_update: 1]

  test "seconds_to_next_update returns correct amount when refreshed_at is in an hour" do
    with refreshed_at = Timex.shift(DateTime.now, hours: 1) do
      assert seconds_to_next_update(refreshed_at) == 4500 # 1 hour 15 minutes == 4500 seconds
    end
  end

  test "seconds_to_next_update returns correct amount when refreshed_at is one hour ago" do
    with refreshed_at = Timex.shift(DateTime.now, hours: -1) do
      assert seconds_to_next_update(refreshed_at) == 0
    end
  end

  test "seconds_to_next_update returns correct amount when refreshed_at is ten minutes ago" do
    with refreshed_at = Timex.shift(DateTime.now, minutes: -10) do
      assert seconds_to_next_update(refreshed_at) == 300 # 5 minutes == 300 seconds
    end
  end

  test "seconds_to_next_update returns correct amount when refreshed_at is nil" do
    assert seconds_to_next_update(nil) == 0
  end

end
