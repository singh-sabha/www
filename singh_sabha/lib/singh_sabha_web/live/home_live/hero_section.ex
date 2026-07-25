defmodule SinghSabhaWeb.HomeLive.HeroSection do
  use Phoenix.Component
  use SinghSabhaWeb, :verified_routes

  import SinghSabhaWeb.CoreComponents

  alias Phoenix.LiveView.JS

  def section(assigns) do
    ~H"""
    <section
      class="relative bg-cover bg-center bg-no-repeat"
      style="background-image: url('/images/gurdwara.jpg')"
    >
      <div class="absolute inset-0 bg-black/50 backdrop-blur-md"></div>
      <div class="relative mx-auto min-h-[calc(100vh-4rem)] p-4 flex flex-col justify-center items-center">
        <div class="w-full max-w-4xl mx-auto text-center space-y-8">
          <div class="relative">
            <h2 class="text-2xl sm:text-3xl font-medium text-primary-content mb-2">
              Gurdwara Singh Sabha of Victoria
            </h2>
            <div class="h-1 w-20 bg-primary mx-auto rounded-full"></div>
          </div>
          <div>
            <h1 class="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-bold text-primary-content font-gurmukhi leading-[1.25]">
              ਆਵਹੁ ਸਿਖ ਸਤਿਗੁਰੂ ਕੇ ਪਿਆਰਿਹੋ ਗਾਵਹੁ ਸਚੀ ਬਾਣੀ
            </h1>
          </div>
          <div>
            <p class="text-xl sm:text-2xl text-primary-content">
              Come, O beloved Sikhs of the True Guru, and sing the True Word of His Bani
            </p>
          </div>
          <div class="flex flex-wrap justify-center gap-4">
            <.link
              phx-click={JS.dispatch("scroll-to-content", detail: %{target: "#services"})}
              class="btn btn-primary"
            >
              <.icon name="hero-hand-raised" class="mr-2 h-5 w-5" /> Our Services
            </.link>
            <.link
              phx-click={JS.dispatch("scroll-to-content", detail: %{target: "#donations"})}
              class="btn"
            >
              <.icon name="hero-currency-dollar" class="mr-2 h-5 w-5" /> Donate
            </.link>
          </div>
        </div>
        <.button
          phx-click={JS.dispatch("scroll-to-content", detail: %{target: "#upcoming-events"})}
          class="absolute bottom-8 left-1/2 -translate-x-1/2 text-primary-content hover:text-primary-content/80 transition-colors focus:outline-none cursor-pointer animate-bounce"
          aria-label="Scroll to content"
        >
          <.icon name="hero-chevron-down" class="w-8 h-8" />
        </.button>
      </div>
    </section>
    """
  end
end
