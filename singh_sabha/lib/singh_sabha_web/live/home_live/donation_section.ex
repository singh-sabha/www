defmodule SinghSabhaWeb.HomeLive.DonationsSection do
  use Phoenix.Component
  use SinghSabhaWeb, :html

  @etransfer_email "singhsabhayyj@gmail.com"
  @stripe_url "https://donate.stripe.com/eVa5m4deM9G99QkbIJ"

  def section(assigns) do
    assigns =
      assigns
      |> assign(:etransfer_email, @etransfer_email)
      |> assign(:stripe_url, @stripe_url)

    ~H"""
    <section class="space-y-4">
      <div class="flex justify-center items-center gap-2">
        <h3 class="text-lg font-semibold">Support Our Mission</h3>
      </div>
      <p class="text-sm opacity-60 text-center">
        Your generous donations help us maintain and improve our services. We appreciate any contribution you can make.
      </p>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4 container mx-auto pt-8 ">
        <div class="flex flex-col gap-3 rounded-md border border-base-300 p-4">
          <div class="flex items-center gap-2">
            <.icon name="hero-envelope" class="size-4 opacity-70" />
            <h4 class="font-semibold">e-Transfer</h4>
          </div>
          <p class="text-sm opacity-60">
            Send an Interac e-Transfer to the following email address.
          </p>
          <div class="flex w-full mt-auto gap-2">
            <input
              type="text"
              class="input input-sm flex-1 font-mono text-sm"
              value={@etransfer_email}
              readonly
            />
            <button
              class="btn btn-sm"
              phx-click={JS.dispatch("phx:copy", detail: %{text: @etransfer_email})}
            >
              <.icon name="hero-clipboard" class="size-4 [[data-copied]_&]:hidden" />
              <.icon name="hero-check" class="size-4 hidden [[data-copied]_&]:block" />
            </button>
          </div>
        </div>

        <div class="flex flex-col gap-3 rounded-md border border-base-300 p-4">
          <div class="flex items-center gap-2">
            <.icon name="hero-credit-card" class="size-4 opacity-70" />
            <h4 class="font-semibold">Credit Card</h4>
          </div>
          <p class="text-sm opacity-60">
            Donate securely online using your credit card via Stripe.
          </p>
          <a href={@stripe_url} target="_blank" class="btn btn-sm mt-auto gap-2">
            Donate with Stripe
          </a>
        </div>
      </div>
    </section>
    """
  end
end
