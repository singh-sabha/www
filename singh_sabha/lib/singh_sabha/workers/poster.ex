defmodule SinghSabha.Workers.Poster do
  use Oban.Worker, queue: :posters, max_attempts: 1

  require Logger

  alias ReqLLM.Message.ContentPart

  alias SinghSabhaWeb.Helpers.Timezone

  alias SinghSabha.Events
  alias SinghSabha.Drafts

  @model "google:gemini-3.1-flash-lite"

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"id" => id, "key" => key, "filename" => filename}
      }) do
    response = %{
      "events" => [
        %{
          "end" => "2026-10-17T23:59",
          "occasion" => "Sangrand (Katak) Evening Programme",
          "start" => "2026-10-17T18:00",
          "type" => "Other"
        },
        %{
          "end" => "2026-10-17T23:59",
          "notes" => "Guru Ghar",
          "occasion" => "Langar",
          "start" => "2026-10-17T12:00",
          "type" => "Langar"
        },
        %{
          "end" => "2026-10-18T20:00",
          "notes" => "Sewa by Satbir Singh",
          "occasion" => "Sri Sukhmani Sahib",
          "start" => "2026-10-18T18:00",
          "type" => "Sukhmani Sahib Path"
        },
        %{
          "end" => "2026-10-18T20:00",
          "notes" => "Sewa by Satbir Singh",
          "occasion" => "Langar",
          "start" => "2026-10-18T18:00",
          "type" => "Langar"
        },
        %{
          "end" => "2026-10-19T14:00",
          "notes" => "Sewa by Bibi Manjil Kaur",
          "occasion" => "Sunday Diwan Langar",
          "start" => "2026-10-19T11:00",
          "type" => "Langar"
        },
        %{
          "end" => "2026-10-19T14:00",
          "notes" => "Sewa by Rajinder Kaur",
          "occasion" => "Sehaj Path Bhog",
          "start" => "2026-10-19T11:00",
          "type" => "Sehaj Path"
        },
        %{
          "end" => "2026-10-21T20:30",
          "notes" => "Bandi Chhor Divas",
          "occasion" => "Diwali Evening Diwan",
          "start" => "2026-10-21T17:00",
          "type" => "Other"
        },
        %{
          "end" => "2026-10-21T20:30",
          "notes" => "Sewa by Bibi Balwinder Kaur",
          "occasion" => "Langar",
          "start" => "2026-10-21T17:00",
          "type" => "Langar"
        },
        %{
          "end" => "2026-10-25T12:00",
          "notes" => "At home of Sr. Kuldar Singh",
          "occasion" => "Sri Sukhmani Sahib Path",
          "start" => "2026-10-25T09:00",
          "type" => "Sukhmani Sahib Path"
        },
        %{
          "end" => "2026-10-26T14:00",
          "notes" => "Sewa by Surjeet Singh Dhaneta",
          "occasion" => "Sunday Diwan",
          "start" => "2026-10-26T11:00",
          "type" => "Other"
        },
        %{
          "end" => "2026-10-26T14:00",
          "notes" => "Sewa by Surjeet Singh Dhaneta",
          "occasion" => "Sri Sukhmani Sahib Path",
          "start" => "2026-10-26T11:00",
          "type" => "Sukhmani Sahib Path"
        },
        %{
          "end" => "2026-10-26T14:00",
          "notes" => "Sewa by Surjeet Singh Dhaneta",
          "occasion" => "Langar",
          "start" => "2026-10-26T11:00",
          "type" => "Langar"
        }
      ]
    }

    with {:ok, %{draft: draft}} <- build_events(response, key) do
      Logger.info("created draft #{draft.id}")

      Phoenix.PubSub.broadcast(SinghSabha.PubSub, "drafts", {:draft_created, draft.id})

      :ok
    else
      {:error, %ReqLLM.Error.API.Request{status: 503}} = error ->
        Logger.error("hit a rate limit")
        error

      {:error, :events, changeset, _changes_so_far} ->
        Logger.error("event failed validation: #{inspect(changeset.errors)}")
        {:error, changeset}

      {:error, :draft, changeset, _changes_so_far} ->
        Logger.error("draft failed validation: #{inspect(changeset.errors)}")
        {:error, changeset}

      {:error, reason} = error ->
        Logger.error("could not build draft: #{inspect(reason)}")
        error
    end
  end

  defp extract_events(key, filename) do
    Logger.info("extracting events for #{filename}...")

    event_types =
      Events.list_event_types(:all)
      |> Enum.map(& &1.display_name)

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
    #{event_types}
    - If the poster states a year only once (e.g. in a title or header), apply
      that year to every event's date.
    - Format "start" and "end" exactly as: YYYY-MM-DDTHH:MM (24-hour time).
      For example, October 5 2026 at 9:00 AM is "2026-10-05T09:00". If no
      time is given for an event, use "00:00".
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
                "description" => "Format: YYYY-MM-DDTHH:MM"
              },
              "end" => %{
                "type" => "string",
                "description" => "Format: YYYY-MM-DDTHH:MM"
              },
              "type" => %{
                "type" => "string",
                "enum" => event_types
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
      {:ok, response} ->
        Logger.info("successfully extracted events for #{filename}!")

        ReqLLM.Response.object(response)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp build_events(%{"events" => events}, key) do
    Logger.info("building draft with events...")

    name_to_id =
      Events.list_event_types(:all)
      |> Map.new(&{&1.display_name, &1.id})

    events
    |> Enum.reduce_while({:ok, []}, fn event, {:ok, acc} ->
      with {:ok, type_id} <- fetch_type_id(name_to_id, event["type"]),
           params <-
             event
             |> Map.merge(%{"is_deposit_paid" => true, "is_verified" => true, "type" => type_id})
             |> Timezone.convert_datetime_params() do
        {:cont, {:ok, [params | acc]}}
      else
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, event_params} ->
        Drafts.create_draft(%{
          "image_path" => key,
          "status" => "pending",
          "events" => Enum.reverse(event_params)
        })

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_type_id(name_to_id, type) do
    case Map.fetch(name_to_id, type) do
      {:ok, id} -> {:ok, id}
      :error -> {:error, {:unknown_event_type, type}}
    end
  end
end
