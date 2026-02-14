defmodule SinghSabha.MailingList do
  use Ecto.Schema
  import Ecto.Changeset

  alias SinghSabha.Events.Event

  schema "mailing_list" do
    field :email, :string

    timestamps()
  end

  def changeset(mailing_list, attrs) do
    mailing_list
    |> cast(attrs, [:email])
    |> validate_required([:email])
    |> Event.validate_email()
    |> unique_constraint(:email)
  end
end
