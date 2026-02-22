# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     SinghSabha.Repo.insert!(%SinghSabha.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias SinghSabha.Events

event_types = [
  %{
    display_name: "Funeral",
    description:
      "A solemn service honouring the departed soul, featuring prayers, hymns, and Ardas, focusing on the soul's journey and the Sikh belief in eternal life.",
    is_requestable: true,
    deposit: Decimal.new("0.00")
  },
  %{
    display_name: "Sukhmani Sahib Path",
    description:
      "A recitation of hymns by Guru Arjan Dev Ji, offering peace and spiritual solace, often performed during challenging or celebratory times.",
    is_requestable: true,
    deposit: Decimal.new("100.00")
  },
  %{
    display_name: "Sehaj Path",
    description:
      "A complete recitation of the Guru Granth Sahib, done at a steady pace to seek blessings or mark special occasions.",
    is_requestable: true,
    deposit: Decimal.new("250.00")
  },
  %{
    display_name: "Akhand Path",
    description:
      "A continuous 48-hour recitation of the Guru Granth Sahib, performed without interruption to seek blessings or mark special occasions.",
    is_requestable: true,
    deposit: Decimal.new("250.00")
  },
  %{
    display_name: "Langar",
    description:
      "A free community meal promoting equality, unity, and selfless service, prepared and served by volunteers in the Gurdwara.",
    is_requestable: true,
    deposit: Decimal.new("100.00")
  },
  %{
    display_name: "Other",
    description: "A general event that doesn't fit into a specific category.",
    is_requestable: false,
    deposit: Decimal.new("0.00")
  },
  %{
    display_name: "Anand Karaj",
    description:
      "The Sikh wedding ceremony signifying the spiritual union of two souls through the sacred Lavan around the Guru Granth Sahib.",
    is_requestable: true,
    deposit: Decimal.new("500.00")
  }
]

Enum.each(event_types, fn attrs ->
  case Events.create_event_type(attrs) do
    {:ok, event_type} ->
      IO.puts("Created event type: #{event_type.display_name}")

    {:error, changeset} ->
      IO.puts("Failed to create #{attrs.display_name}: #{inspect(changeset.errors)}")
  end
end)
