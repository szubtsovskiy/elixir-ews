defmodule Events.TableFormatter do
  import Enum, only: [map_join: 3, map: 2]
  import Map, only: [get: 2]

  @default_print_count 7

  def format(events, count \\ @default_print_count) do
    events |> sort
           |> Enum.take(count)
           |> print_formatted
  end

  defp sort(events) do
    events |> Enum.sort(fn e1, e2 -> e1["start"] >= e2["start"] end)
  end

  defp print_formatted(items) do
    with columns = ["subject", "start", "end", "organizer"],
         column_widths = compute_column_widths(items, columns),
         format_string = to_format_string(columns, column_widths) do

          print_line(columns, format_string)
          print_separator(columns, column_widths)
          for item <- items do
            print_line(data_for_columns(item, columns), format_string)
          end
    end
  end

  defp compute_column_widths(items, columns) do
    for key <- columns, into: %{} do
      key_length = key |> to_string |> String.length
      {key, max(items |> Enum.map(&(get_length(&1, key))) |> Enum.max, key_length)}
    end
  end

  defp get_length(item, key) do
    get(item, key) |> to_string |> String.length
  end

  defp to_format_string(columns, column_widths) do
    "| " <> map_join(columns, " | ", &("~-#{column_widths[&1]}s")) <> " |~n"
  end

  defp print_line(data, format_string) do
    :io.format(format_string, data)
  end

  defp print_separator(columns, column_widths) do
    format_string = "+ " <> map_join(columns, " + ", &("~-#{column_widths[&1]}c")) <> " +~n"
    print_line(map(columns, fn _ -> ?- end), format_string)
  end

  defp data_for_columns(item, columns) do
    columns |> Enum.map(&(get(item, &1) |> to_string))
  end

end