defmodule SinghSabha.Accounts.UserNotifier do
  use Phoenix.Swoosh,
    view: SinghSabhaWeb.EmailView,
    layout: {SinghSabhaWeb.LayoutView, :email}

  alias SinghSabha.Mailer
  alias SinghSabha.Accounts.User

  @from {"Gurdwara Singh Sabha of Victoria", "no-reply@singhsabha.net"}

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    new()
    |> to(user.email)
    |> from(@from)
    |> subject("Update Email Instructions")
    |> render_body("update_email_instructions.html", %{user: user, url: url})
    |> Mailer.deliver()
  end

  @doc """
  Deliver instructions to log in with a magic link.
  """
  def deliver_login_instructions(user, url) do
    case user do
      %User{confirmed_at: nil} -> deliver_confirmation_instructions(user, url)
      _ -> deliver_magic_link_instructions(user, url)
    end
  end

  defp deliver_magic_link_instructions(user, url) do
    new()
    |> to(user.email)
    |> from(@from)
    |> subject("Log In Instructions")
    |> render_body("magic_link_instructions.html", %{user: user, url: url})
    |> Mailer.deliver()
  end

  defp deliver_confirmation_instructions(user, url) do
    new()
    |> to(user.email)
    |> from(@from)
    |> subject("Confirmation Instructions")
    |> render_body("confirmation_instructions.html", %{user: user, url: url})
    |> Mailer.deliver()
  end
end
