defmodule SinghSabha.Workers.Poster do
  use Oban.Worker, queue: :posters, max_attempts: 3

  require Logger

  alias ReqLLM.Message.ContentPart

  alias SinghSabhaWeb.Helpers.Timezone

  alias SinghSabha.Events.{Event, EventType}
  alias SinghSabha.Events

  @model "google:gemini-3.1-flash-lite"

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"id" => id, "key" => key, "filename" => filename, "topic" => topic},
        attempt: attempt
      }) do
    case extract_event(key, filename) do
      {:error, %ReqLLM.Error.API.Request{status: 503}} when attempt < 3 ->
        {:snooze, 30}

      results ->
        Phoenix.PubSub.broadcast(
          SinghSabha.PubSub,
          topic,
          {:poster_processed, id, results}
        )

        case results do
          {:ok, _} -> :ok
          {:error, reason} -> {:error, reason}
        end
    end
  end

  defp extract_event(key, filename) do
    event_types = Events.list_event_types(:all)
    type_names = Enum.map(event_types, & &1.display_name)

    type_descriptions =
      Enum.map_join(event_types, "\n", fn type ->
        "- #{type.display_name}: #{type.description}"
      end)

    prompt = """
    Extract every distinct event listed on this poster. Posters often list a
    full week's or month's program with multiple separate entries — extract
    ALL of them as separate events, even if several events fall on the same
    date. Do not merge multiple entries into one.
    The poster may contain Punjabi (Gurmukhi script), English, or a mix of both.
    - Translate any Punjabi text into natural English - do not transliterate.
      Proper nouns and terms commonly used as-is in English (e.g. "Gurdwara",
      "Vaisakhi", "Kirtan") can stay in their common English spelling rather
      than being awkwardly translated.
    - All output fields must be in English.
    - If a field isn't present for a given event, omit it.
    - For "type", choose the single best match for each event from this list:
    #{type_descriptions}
    - If the poster states a year only once (e.g. in a title or header), apply
      that year to every event's date.
    - Format "start" and "end" exactly as: YYYY-MM-DD HH:MM:SS (24-hour time).
      For example, October 5 2026 at 9:00 AM is "2026-10-05 09:00:00". If no
      time is given for an event, use "00:00:00".
    """

    image_binary =
      "singh-sabha-posters"
      |> ExAws.S3.get_object(key)
      |> ExAws.request!()
      |> Map.fetch!(:body)

    mime_type = MIME.from_path(filename)

    messages = [
      ReqLLM.Context.user([
        ContentPart.text(prompt),
        ContentPart.image(image_binary, mime_type)
      ])
    ]

    schema = %{
      "type" => "object",
      "properties" => %{
        "events" => %{
          "type" => "array",
          "items" => %{
            "type" => "object",
            "properties" => %{
              "occasion" => %{
                "type" => "string"
              },
              "start" => %{
                "type" => "string",
                "description" => "Format: YYYY-MM-DD HH:MM:SS"
              },
              "end" => %{
                "type" => "string",
                "description" => "Format: YYYY-MM-DD HH:MM:SS"
              },
              "type" => %{
                "type" => "string",
                "enum" => type_names
              },
              "notes" => %{
                "type" => "string"
              }
            },
            "required" => ["occasion", "start", "end", "type"]
          }
        }
      },
      "required" => ["events"]
    }

    case ReqLLM.generate_object(@model, messages, schema) do
      {:ok, response} -> build_events(response.object, event_types)
      {:error, reason} -> {:error, reason}
    end
  end

  defp build_events(%{"events" => events}, event_types) do
    name_to_id = Map.new(event_types, &{&1.display_name, &1.id})

    results =
      Enum.flat_map(events, fn event ->
        with {:ok, start} <- Timezone.local_to_utc_full(event["start"]),
             # "end" is a reversed keyword, so we use "end_" instead
             {:ok, end_} <- Timezone.local_to_utc_full(event["end"]),
             {:ok, type_id} <- Map.fetch(name_to_id, event["type"]) do
          [
            %Event{
              occasion: event["occasion"],
              # required: in DB "type" is a foreign key used for modal population
              type: type_id,
              event_type: %EventType{
                id: type_id,
                display_name: event["type"]
              },
              start: start,
              end: end_,
              note: event["note"],
              is_deposit_paid: true,
              is_verified: true,
              is_public: true
            }
          ]
        else
          _ ->
            Logger.warning("aborted: encountered a malformed entry during agentic extraction")
            []
        end
      end)

    if length(results) != length(events) do
      {:error, "aborted: we were not able to extract some events"}
    else
      {:ok, results}
    end
  end
end
