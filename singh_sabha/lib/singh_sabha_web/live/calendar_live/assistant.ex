defmodule SinghSabhaWeb.CalendarLive.Assistant do
  use SinghSabhaWeb, :live_view

  alias SinghSabhaWeb.Helpers.{
    TimezoneHelpers,
    EventTypeHelpers
  }

  alias SinghSabhaWeb.CalendarLive.EditEventModal

  alias SinghSabha.Events

  alias SinghSabha.Workers.Poster

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8 max-w-2xl">
      <h1 class="text-xl font-semibold mb-6">Assistant</h1>
      <form
        id="upload-form"
        phx-change="validate"
        phx-submit="save"
        class={[@processing? && "hidden"]}
      >
        <section class={[
          "flex flex-col items-center justify-center",
          @uploads.poster.entries == [] && "rounded-box border border-base-300 py-12"
        ]}>
          <%= if @uploads.poster.entries == [] do %>
            <.icon name="hero-photo" class="size-10 text-base-content/70" />
            <p class="text-sm text-base-content/60">Click below to browse for a poster</p>
          <% else %>
            <div class="w-full space-y-2">
              <%= for entry <- @uploads.poster.entries do %>
                <div class="flex items-center gap-3 rounded-md border border-base-300 p-3">
                  <.icon name="hero-photo" class="size-5 shrink-0 text-base-content/70" />

                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-medium truncate">{entry.client_name}</p>
                    <progress
                      class="progress progress-primary w-full h-1.5"
                      value={entry.progress}
                      max="100"
                    />
                  </div>

                  <button
                    type="button"
                    phx-click="cancel_upload"
                    phx-value-ref={entry.ref}
                    class="btn btn-xs btn-ghost btn-circle shrink-0"
                    aria-label="Remove"
                  >
                    <.icon name="hero-x-mark" class="size-3" />
                  </button>
                </div>
              <% end %>
            </div>
          <% end %>

          <label class={["btn btn-sm", @uploads.poster.entries != [] && "hidden"]}>
            Choose image <.live_file_input upload={@uploads.poster} class="hidden" />
          </label>
        </section>
        <%= for err <- upload_errors(@uploads.poster) do %>
          <div class="flex items-center gap-1.5 mt-2">
            <span class={["badge badge-sm gap-1", EventTypeHelpers.badge_colour(:red)]}>
              <.icon name="hero-exclamation-circle" class="size-3" />
              {Phoenix.Naming.humanize(err)}
            </span>
          </div>
        <% end %>
        <button
          type="submit"
          class="btn btn-primary mt-4 w-full"
          disabled={
            @uploads.poster.entries == [] or not Enum.all?(@uploads.poster.entries, & &1.done?)
          }
        >
          Upload
        </button>
      </form>

      <div class={["space-y-3", !@processing? && "hidden"]}>
        <%= for file <- @uploaded_files do %>
          <%= case file.status do %>
            <% :done -> %>
              <div class="collapse collapse-arrow rounded-md border border-base-300">
                <input
                  type="checkbox"
                  checked={@open_file_id == file.id}
                  phx-click="toggle_file"
                  phx-value-file-id={file.id}
                />

                <div class="collapse-title min-h-0 !py-3 !pl-3 !pr-10 flex items-center gap-3 text-sm">
                  <.icon name="hero-photo" class="size-4 shrink-0 text-base-content/70" />
                  <span class="font-medium truncate flex-1">{file.filename}</span>
                  <span class="badge badge-sm badge-ghost shrink-0">
                    {length(file.events)} event{if length(file.events) != 1, do: "s"}
                  </span>
                </div>

                <div class="collapse-content !pb-3 space-y-3">
                  <% selected = Map.get(@selected_event_ids, file.id, MapSet.new()) %>

                  <div class="flex items-center justify-between pb-1">
                    <label class="flex items-center gap-2 text-xs text-base-content/60 cursor-pointer">
                      <input
                        type="checkbox"
                        class="checkbox checkbox-xs"
                        checked={
                          MapSet.size(selected) == length(file.events) and length(file.events) > 0
                        }
                        phx-click="toggle_select_all"
                        phx-value-file-id={file.id}
                      /> Select all
                    </label>

                    <button
                      type="button"
                      class="btn btn-xs btn-primary"
                      disabled={MapSet.size(selected) == 0}
                      phx-click="accept_events"
                      phx-value-file-id={file.id}
                    >
                      <.icon name="hero-check" class="size-3" /> Accept
                    </button>
                  </div>

                  <%= for {event, index} <- Enum.with_index(file.events) do %>
                    <.event_card
                      event={event}
                      event_id={index}
                      file_id={file.id}
                      checked={MapSet.member?(selected, index)}
                    />
                  <% end %>
                </div>
              </div>
            <% :processing -> %>
              <div class="flex items-center gap-3 rounded-md border border-base-300 p-3 text-sm">
                <.icon name="hero-photo" class="size-4 shrink-0 text-base-content/70" />
                <span class="font-medium truncate flex-1">{file.filename}</span>
                <span class="loading loading-spinner loading-xs shrink-0" />
              </div>
            <% :error -> %>
              <div class="flex items-center gap-3 rounded-md border border-base-300 p-3 text-sm">
                <.icon name="hero-photo" class="size-4 shrink-0 text-base-content/70" />
                <div class="flex-1 min-w-0">
                  <p class="font-medium truncate">{file.filename}</p>
                  <p class="text-xs text-base-content/60 truncate">
                    {file.error || "Could not extract event details from image"}
                  </p>
                </div>
                <.icon name="hero-exclamation-circle" class="size-4 shrink-0 text-error" />
              </div>
          <% end %>
        <% end %>
      </div>
    </div>

    <.live_component
      :if={@selected_event}
      module={EditEventModal}
      id="edit_event_modal"
      selected_event={@selected_event}
      source={@edit_source}
    />

    <div phx-hook="ModalManager" id="modal-manager"></div>
    """
  end

  defp event_card(assigns) do
    ~H"""
    <% colour = EventTypeHelpers.event_type_to_colour(@event.event_type.display_name) %>

    <div class={[
      "flex select-none items-center gap-3 rounded-md border p-3 text-sm transition-colors",
      EventTypeHelpers.card_colour(colour)
    ]}>
      <input
        type="checkbox"
        class="checkbox checkbox-sm shrink-0"
        checked={@checked}
        phx-click="toggle_event_selection"
        phx-value-file-id={@file_id}
        phx-value-event-id={@event_id}
      />

      <div class="flex flex-1 flex-col gap-2 min-w-0">
        <div class="flex items-center gap-1.5">
          <p class="font-medium">
            <span class={EventTypeHelpers.text_colour(colour)}>
              {@event.occasion}
            </span>
          </p>
        </div>

        <div class="flex items-center gap-1.5">
          <.icon name="hero-clock" class="size-3 shrink-0 text-base-content/70" />
          <p class="text-xs">
            {TimezoneHelpers.format_datetime(@event.start)} - {TimezoneHelpers.format_datetime(
              @event.end
            )}
          </p>
        </div>

        <div class="flex items-center gap-1.5">
          <.icon name="hero-tag" class="size-3 shrink-0 text-base-content/70" />
          <p class="text-xs">{@event.event_type.display_name}</p>
        </div>

        <%= if @event.note do %>
          <div class="flex items-center gap-1.5">
            <.icon name="hero-document-text" class="size-3 shrink-0 text-base-content/70" />
            <p class="text-xs">{@event.note}</p>
          </div>
        <% end %>
      </div>

      <button
        type="button"
        class="btn btn-xs btn-ghost btn-circle shrink-0"
        phx-click="edit_event"
        phx-value-event-id={@event_id}
        phx-value-file-id={@file_id}
        aria-label="Edit event"
      >
        <.icon name="hero-pencil-square" class="size-4" />
      </button>
    </div>
    """
  end

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
          dest =
            Path.join(
              Application.app_dir(:singh_sabha, "priv/static/uploads"),
              entry.client_name
            )

          File.cp!(path, dest)

          %{id: entry.uuid, path: dest, filename: entry.client_name}
          |> tap(fn file ->
            %{"id" => file.id, "path" => file.path, "topic" => socket.assigns.topic}
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
