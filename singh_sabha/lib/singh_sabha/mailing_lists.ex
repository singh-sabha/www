defmodule SinghSabha.MailingLists do
  @moduledoc """
  The MailingLists context.
  """

  import Ecto.Query, warn: false
  alias SinghSabha.MailingList
  alias SinghSabha.Repo

  @doc """
  Subscribes an email to the mailing list.
  """
  def subscribe(attrs \\ %{}) do
    %MailingList{}
    |> MailingList.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Unsubscribes an email from the mailing list.
  """
  def unsubscribe(email) do
    case Repo.get_by(MailingList, email: email) do
      nil -> {:error, :not_found}
      subscriber -> Repo.delete(subscriber)
    end
  end

  @doc """
  Returns all subscribed emails.
  """
  def list_subscribers do
    Repo.all(MailingList)
  end

  @doc """
  Checks if an email is subscribed.
  """
  def subscribed?(email) do
    Repo.exists?(from m in MailingList, where: m.email == ^email)
  end
end
