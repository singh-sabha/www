defmodule SinghSabhaWeb.Helpers.Path do
  use SinghSabhaWeb, :verified_routes

  def calendar(query, opts \\ []) do
    view = Keyword.get(opts, :view, query.view)
    date = Keyword.get(opts, :date, query.date)

    queries = [view: view, date: Date.to_string(date)]
    queries = if time = Keyword.get(opts, :time), do: queries ++ [time: time], else: queries

    case Keyword.get(opts, :action, :index) do
      :index -> ~p"/calendar?#{queries}"
      :new -> ~p"/calendar/new?#{queries}"
      {:show, id} -> ~p"/calendar/#{id}?#{queries}"
      {:edit, id} -> ~p"/calendar/#{id}/edit?#{queries}"
    end
  end

  def assistant(query, opts \\ []) do
    draft_id = Keyword.get(opts, :draft_id, query.draft_id)

    ~p"/assistant/#{draft_id}/edit"
  end
end
