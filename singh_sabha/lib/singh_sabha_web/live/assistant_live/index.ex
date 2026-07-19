defmodule SinghSabhaWeb.AssistantLive.Index do
  use SinghSabhaWeb, :live_view

  alias SinghSabhaWeb.Helpers.EventType
  alias SinghSabha.Drafts
  alias SinghSabha.Workers.Poster

  @impl true
  def mount(_, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(SinghSabha.PubSub, "drafts")
    end

    {:ok,
     socket
     |> assign(:drafts, Drafts.list_drafts())
     |> assign(:selected_event, nil)
     |> assign(:selected_event_ids, %{})
     |> assign(:open_file_id, nil)
     |> assign(:uploaded_files, [])
     |> assign(:processing?, false)
     |> allow_upload(:poster,
       accept: ~w(.png .jpg .jpeg),
       max_entries: 5,
       auto_upload: true
     )}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :poster, ref)}
  end

  def handle_event("save", _params, socket) do
    if Enum.all?(socket.assigns.uploads.poster.entries, & &1.done?) do
      entries =
        consume_uploaded_entries(socket, :poster, fn %{path: path}, entry ->
          key = "posters/#{entry.uuid}-#{entry.client_name}"
          body = File.read!(path)

          "singh-sabha-posters"
          |> ExAws.S3.put_object(key, body)
          |> ExAws.request!()

          %{id: entry.uuid, key: key, filename: entry.client_name}
          |> tap(fn file ->
            %{
              "id" => file.id,
              "key" => file.key,
              "filename" => entry.client_name
            }
            |> Poster.new()
            |> Oban.insert()
          end)
          |> then(&{:ok, &1})
        end)

      files =
        Enum.map(entries, fn entry ->
          Map.merge(entry, %{status: :processing, events: nil, error: nil})
        end)

      {:noreply,
       socket
       |> update(:uploaded_files, &(&1 ++ files))
       |> assign(:processing?, true)}
    else
      {:noreply, put_flash(socket, :error, "Please wait for the upload to finish.")}
    end
  end

  @impl true
  def handle_info({:draft_created, draft_id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/assistant/#{draft_id}/edit")}
  end
end
