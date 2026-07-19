defmodule SinghSabha.Drafts do
  import Ecto.Query, warn: false
  alias SinghSabha.Repo

  alias SinghSabha.Events.Event
  alias SinghSabha.Drafts.Draft

  @doc """
  Creates a draft with multiple events.
  """
  def create_draft(attrs \\ %{}) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:draft, Draft.changeset(%Draft{}, attrs))
    |> Ecto.Multi.run(:events, fn repo, %{draft: draft} ->
      events =
        Map.get(attrs, "events", attrs[:events] || [])
        |> Enum.map(&Map.put(&1, "draft_id", draft.id))

      Enum.reduce_while(events, {:ok, []}, fn event_attrs, {:ok, acc} ->
        case %Event{} |> Event.changeset(event_attrs) |> repo.insert() do
          {:ok, event} -> {:cont, {:ok, [event | acc]}}
          {:error, changeset} -> {:halt, {:error, changeset}}
        end
      end)
      |> case do
        {:ok, events} -> {:ok, Enum.reverse(events)}
        {:error, changeset} -> {:error, changeset}
      end
    end)
    |> Repo.transaction()
  end

  @doc """
  List an drafts
  """
  def list_drafts() do
    from(d in Draft,
      where: d.status == "pending"
    )
    |> Repo.all()
  end

  @doc """
  Get a draft and it's associated events
  """
  def get_draft(id) do
    from(d in Draft,
      where: d.id == ^id,
      preload: [events: [:event_type]]
    )
    |> Repo.one()
  end

  @doc """
  Deletes a draft
  """
  def delete_draft(draft) do
    Repo.delete(draft)
  end
end
