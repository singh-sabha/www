defmodule SinghSabhaWeb.WorkflowController do
  alias SinghSabha.Events
  use SinghSabhaWeb, :controller

  @required_fields ~w(occassion start end type)

  def generate(conn, %{"_json" => events}) when is_list(events) do
    results = Enum.map(events, &validate_event/1)
    errors = for {:error, msg} <- results, do: msg

    if Enum.empty?(errors) do
      with {:ok, event_list} <- format_event_list(events) do
        json(conn, %{
          message:
            "✨ Generated #{length(events)} event#{pluralize(length(events))}.\n\n#{event_list}"
        })
      else
        {:error, reason} ->
          conn
          |> put_status(:bad_request)
          |> json(%{message: "❌ Invalid request: #{reason}"})
      end
    else
      conn
      |> put_status(:unprocessable_entity)
      |> json(%{errors: errors})
    end
  end

  def generate(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{message: "⚠️ No events provided in the request body."})
  end

  def create(conn, %{"_json" => events}) when is_list(events) do
    results = Enum.map(events, &validate_event/1)
    errors = for {:error, msg} <- results, do: msg

    if Enum.empty?(errors) do
      with results <- create_events(events),
           {:ok, summary} <- summarize_results(results) do
        conn
        |> put_status(summary.status)
        |> json(%{message: summary.message})
      else
        {:error, reason} ->
          conn
          |> put_status(:bad_request)
          |> json(%{message: "❌ Invalid request: #{reason}"})
      end
    else
      conn
      |> put_status(:unprocessable_entity)
      |> json(%{errors: errors})
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{message: "⚠️ No events provided in the request body."})
  end

  defp validate_event(event) do
    missing =
      Enum.filter(@required_fields, fn field ->
        not Map.has_key?(event, field) or event[field] in [nil, ""]
      end)

    with [] <- missing,
         {:ok, _} <- fetch_event_type(event["type"]) do
      {:ok, event}
    else
      missing when is_list(missing) ->
        {:error, "missing required fields: #{Enum.join(missing, ", ")}"}

      {:error, msg} ->
        {:error, msg}
    end
  end

  defp fetch_event_type(type_id) do
    case Events.get_event_type(type_id) do
      nil -> {:error, "invalid event type: #{type_id}"}
      _ -> {:ok, type_id}
    end
  end

  defp create_events(events) do
    Enum.map(events, fn event_data ->
      {:ok, start_naive} = NaiveDateTime.from_iso8601(event_data["start"])
      {:ok, end_naive} = NaiveDateTime.from_iso8601(event_data["end"])
      {:ok, start_local} = DateTime.from_naive(start_naive, "America/Vancouver")
      {:ok, end_local} = DateTime.from_naive(end_naive, "America/Vancouver")

      result =
        Events.create_event(%{
          registrant_full_name: nil,
          registrant_email: nil,
          registrant_phone_number: nil,
          type: event_data["type"],
          start: DateTime.shift_zone!(start_local, "Etc/UTC"),
          end: DateTime.shift_zone!(end_local, "Etc/UTC"),
          occassion: event_data["occassion"],
          note: event_data["note"],
          is_verified: true,
          is_public: true,
          is_deposit_paid: true
        })

      case result do
        {:ok, event} ->
          Phoenix.PubSub.broadcast(SinghSabha.PubSub, "events", {:event_created, event})
          {:ok, event}

        err ->
          err
      end
    end)
  end

  defp summarize_results(results) do
    {successes, failures} = Enum.split_with(results, &match?({:ok, _}, &1))
    success_count = length(successes)
    failure_count = length(failures)

    if failure_count == 0 do
      {:ok,
       %{
         status: :ok,
         message: "🎉 Success! Created #{success_count} event#{pluralize(success_count)}."
       }}
    else
      {:ok,
       %{
         status: :unprocessable_entity,
         message:
           "⚠️ Created #{success_count} event#{pluralize(success_count)}, #{failure_count} failed."
       }}
    end
  end

  defp format_event_list(events) do
    try do
      formatted =
        events
        |> Enum.map(fn event ->
          {:ok, start_naive} = NaiveDateTime.from_iso8601(event["start"])
          {:ok, end_naive} = NaiveDateTime.from_iso8601(event["end"])
          start_time = Calendar.strftime(start_naive, "%b %-d, %Y %-I:%M %p")
          end_time = Calendar.strftime(end_naive, "%b %-d, %Y %-I:%M %p")
          "- *#{event["occassion"]}* from #{start_time} to #{end_time}"
        end)
        |> Enum.join("\n")

      {:ok, formatted}
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  defp pluralize(1), do: ""
  defp pluralize(_), do: "s"
end
