defmodule SinghSabhaWeb.UsersLive.Modals.ReviewEvent do
  use SinghSabhaWeb, :live_component

  alias SinghSabha.Events
  alias SinghSabha.Events.Event

  attr :id, :string, required: true
  attr :selected_event, :map, default: nil
  attr :current_scope, :map, default: nil

  def render(assigns) do
    ~H"""
    <div class="modal-box">
      <button
        type="button"
        class="btn btn-sm btn-circle btn-ghost absolute right-2 top-2"
        phx-click={JS.patch(~p"/users/notifications")}
      >
        <.icon name="hero-x-mark" class="size-4" />
      </button>

      <h3 class="font-bold text-lg">{@selected_event.occasion}</h3>

      <div class="space-y-3 mt-4">
        <div class="flex items-start gap-2">
          <.icon name="hero-user" class="mt-1 size-4 shrink-0" />
          <div>
            <p class="text-sm font-medium">Organizer</p>
            <p class="text-sm text-base-content/70">{@selected_event.registrant_full_name}</p>
          </div>
        </div>

        <div class="flex items-start gap-2">
          <.icon name="hero-tag" class="mt-1 size-4 shrink-0" />
          <div>
            <p class="text-sm font-medium">Event Type</p>
            <p class="text-sm text-base-content/70">{@selected_event.event_type.display_name}</p>
          </div>
        </div>

        <div class="flex items-start gap-2">
          <.icon name="hero-calendar" class="mt-1 size-4 shrink-0" />
          <div>
            <p class="text-sm font-medium">Date</p>
            <p class="text-base-content/70 text-sm mt-1">
              {Calendar.strftime(@selected_event.requested, "%B %-d, %Y")}
            </p>
          </div>
        </div>

        <%= if @selected_event.note do %>
          <div class="flex items-start gap-2">
            <.icon name="hero-document-text" class="mt-1 size-4 shrink-0" />
            <div>
              <p class="text-sm font-medium">Note</p>
              <p class="text-sm text-base-content/70">{@selected_event.note}</p>
            </div>
          </div>
        <% end %>
      </div>

      <div class="border-t border-base-300 my-4" />

      <.form
        for={@form}
        phx-change="validate"
        phx-submit="approve_event"
        phx-target={@myself}
      >
        <div class="grid grid-cols-2 gap-4">
          <.input field={@form[:start]} type="datetime-local" label="Start Time" required />
          <.input field={@form[:end]} type="datetime-local" label="End Time" required />
        </div>

        <div class="modal-action">
          <.button
            phx-disable-with="Approving..."
            type="submit"
            class={[
              "btn btn-success",
              if(@start_time not in [nil, ""] and @end_time not in [nil, ""],
                do: "btn",
                else: "btn-disabled"
              )
            ]}
          >
            Approve
          </.button>
          <.button
            phx-disable-with="Denying..."
            type="button"
            class="btn btn-error"
            phx-click="deny_event"
            phx-value-event-id={@selected_event.id}
            phx-target={@myself}
          >
            Deny
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(start_time: nil, end_time: nil)
     |> assign(form: to_form(Events.change_event(%Event{}, %{}), as: :approve_event))}
  end

  def handle_event("validate", %{"approve_event" => params}, socket) do
    form =
      %Event{}
      |> Events.change_event(params)
      |> to_form(action: :validate, as: :approve_event)

    {:noreply,
     socket
     |> assign(form: form)
     |> assign(start_time: params["start"], end_time: params["end"])}
  end

  def handle_event("approve_event", %{"approve_event" => params}, socket) do
    send(self(), {:approve_event, socket.assigns.selected_event.id, params})
    {:noreply, socket}
  end

  def handle_event("deny_event", %{"event-id" => event_id}, socket) do
    send(self(), {:deny_event, event_id})
    {:noreply, socket}
  end
end
