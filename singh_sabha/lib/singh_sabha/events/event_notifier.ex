defmodule SinghSabha.Events.EventNotifier do
  use Phoenix.Swoosh,
    view: SinghSabhaWeb.EmailView,
    layout: {SinghSabhaWeb.LayoutView, :email}

  alias SinghSabha.Mailer
  alias SinghSabha.Payments

  @from {"Gurdwara Singh Sabha of Victoria", "no-reply@singhsabha.net"}

  def event_confirmation(event) do
    new()
    |> to(event.registrant_email)
    |> from(@from)
    |> subject("Event booking request received: #{event.occassion}")
    |> render_body("event_confirmation.html", %{event: event})
    |> Mailer.deliver()
  end

  def event_approved(event) do
    with {:ok, session} <- Payments.create_checkout_session(event) do
      new()
      |> to(event.registrant_email)
      |> from(@from)
      |> subject("Event approved: #{event.occassion}")
      |> render_body("event_approved.html", %{event: event, payment_url: session.url})
      |> Mailer.deliver()
    end
  end

  def event_denied(event, denial_reason) do
    new()
    |> to(event.registrant_email)
    |> from(@from)
    |> subject("Event request update: #{event.occassion}")
    |> render_body("event_denied.html", %{event: event, denial_reason: denial_reason})
    |> Mailer.deliver()
  end

  def admin_notification(event, admin_emails) do
    new()
    |> to(admin_emails)
    |> from(@from)
    |> subject("New event booking: #{event.occassion}")
    |> render_body("admin_notification.html", %{event: event})
    |> Mailer.deliver()
  end

  def admin_upcoming_events(events_by_day, admin_emails) do
    new()
    |> to(admin_emails)
    |> from(@from)
    |> subject("Weekly events schedule")
    |> render_body("admin_weekly_events.html", %{events_by_day: events_by_day})
    |> Mailer.deliver()
  end
end
