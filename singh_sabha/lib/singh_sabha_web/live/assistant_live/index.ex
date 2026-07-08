defmodule SinghSabhaWeb.Assistant.Index do
  use SinghSabhaWeb, :live_view

  import SinghSabhaWeb.AssistantLive.Components
  alias SinghSabhaWeb.CalendarLive.Modals.EditEvent
  alias SinghSabhaWeb.Helpers.EventType
  alias SinghSabha.Events
  alias SinghSabha.Workers.Poster

  @impl true
  def mount(_, _session, socket) do
    topic = "assistant_processing:#{socket.id}"

    if connected?(socket) do
      Phoenix.PubSub.subscribe(SinghSabha.PubSub, topic)
    end

    {:ok,
     socket
     |> assign(:selected_event, nil)
     |> assign(:selected_event_ids, %{})
     |> assign(:edit_source, {})
     |> assign(:open_file_id, nil)
     |> assign(:uploaded_files, [])
     |> assign(:processing?, false)
     |> assign(:topic, topic)
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
              "filename" => entry.client_name,
              "topic" => socket.assigns.topic
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

  def handle_event("edit_event", %{"event-id" => event_id, "file-id" => file_id}, socket) do
    index = String.to_integer(event_id)

    event =
      socket.assigns.uploaded_files
      |> Enum.find(&(&1.id == file_id))
      |> then(& &1.events)
      |> Enum.at(index)

    {:noreply,
     socket
     |> assign(:selected_event, event)
     |> assign(:edit_source, {:pending, file_id, index})
     |> push_event("open-modal", %{id: "edit_event_modal"})}
  end

  def handle_event("toggle_file", %{"file-id" => file_id}, socket) do
    open? = socket.assigns.open_file_id == file_id
    {:noreply, assign(socket, :open_file_id, if(open?, do: nil, else: file_id))}
  end

  def handle_event(
        "toggle_event_selection",
        %{"file-id" => file_id, "event-id" => event_id},
        socket
      ) do
    index = String.to_integer(event_id)

    selected_event_ids =
      Map.update(socket.assigns.selected_event_ids, file_id, MapSet.new([index]), fn set ->
        if MapSet.member?(set, index), do: MapSet.delete(set, index), else: MapSet.put(set, index)
      end)

    {:noreply, assign(socket, :selected_event_ids, selected_event_ids)}
  end

  def handle_event("toggle_select_all", %{"file-id" => file_id}, socket) do
    file = Enum.find(socket.assigns.uploaded_files, &(&1.id == file_id))
    currently_selected = Map.get(socket.assigns.selected_event_ids, file_id, MapSet.new())

    all_indices = 0..(length(file.events) - 1) |> Enum.to_list() |> MapSet.new()

    new_set =
      if MapSet.equal?(currently_selected, all_indices), do: MapSet.new(), else: all_indices

    {:noreply,
     assign(
       socket,
       :selected_event_ids,
       Map.put(socket.assigns.selected_event_ids, file_id, new_set)
     )}
  end

  def handle_event("accept_events", %{"file-id" => file_id}, socket) do
    indices = Map.get(socket.assigns.selected_event_ids, file_id, MapSet.new())
    file = Enum.find(socket.assigns.uploaded_files, &(&1.id == file_id))

    events_to_accept =
      file.events
      |> Enum.with_index()
      |> Enum.filter(fn {_event, i} -> MapSet.member?(indices, i) end)
      |> Enum.map(&elem(&1, 0))

    attrs_list = Enum.map(events_to_accept, &Map.from_struct/1)

    case Events.create_events(attrs_list) do
      {:ok, created_events} ->
        uploaded_files = Enum.reject(socket.assigns.uploaded_files, &(&1.id == file_id))

        {:noreply,
         socket
         |> assign(:uploaded_files, uploaded_files)
         |> assign(:processing?, uploaded_files != [])
         |> assign(:selected_event_ids, Map.delete(socket.assigns.selected_event_ids, file_id))
         |> put_flash(:success, "#{length(created_events)} event(s) accepted.")}

      {:error, _changeset} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Could not save events. Please check the extracted data and try again."
         )}
    end
  end

  @impl true
  def handle_info({:poster_processed, id, {:ok, events}}, socket) do
    {:noreply, update_file(socket, id, &Map.merge(&1, %{status: :done, events: events}))}
  end

  def handle_info({:poster_processed, id, {:error, reason}}, socket) do
    {:noreply, update_file(socket, id, &Map.merge(&1, %{status: :error, error: inspect(reason)}))}
  end

  def handle_info({:pending_event_updated, file_id, index, updated_event}, socket) do
    uploaded_files =
      Enum.map(socket.assigns.uploaded_files, fn
        %{id: ^file_id} = file ->
          Map.update!(file, :events, &List.replace_at(&1, index, updated_event))

        file ->
          file
      end)

    {:noreply, assign(socket, :uploaded_files, uploaded_files)}
  end

  defp update_file(socket, id, fun) do
    update(socket, :uploaded_files, fn files ->
      Enum.map(files, fn
        %{id: ^id} = file -> fun.(file)
        file -> file
      end)
    end)
  end
end
