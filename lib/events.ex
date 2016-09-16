defmodule Events do

  def start(_, _) do
    Events.CalendarManager.start_link
  end

end
