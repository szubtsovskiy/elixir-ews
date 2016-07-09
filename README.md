# Events

Scheduler and worker queue implementation loading events from EWS and Google calendar and displaying them in a nice table.

*Features:*

* Load events from Google or EWS calendar.
* Automatically update EWS calendar every 15 minutes.
* Force refresh events.
* Report errors during refreshing.
* Print loaded events as a table.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `events` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:events, "~> 0.1.0"}]
    end
    ```

  2. Ensure `events` is started before your application:

    ```elixir
    def application do
      [applications: [:events]]
    end
    ```

