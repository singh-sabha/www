defmodule SinghSabhaWeb.Components.Footer do
  use Phoenix.Component
  use SinghSabhaWeb, :verified_routes

  import SinghSabhaWeb.CoreComponents

  def footer(assigns) do
    ~H"""
    <footer class="footer sm:footer-horizontal bg-base-200 text-base-content p-10">
      <nav>
        <h6 class="footer-title">Services</h6>
        <.link navigate={~p"/calendar"} class="link link-hover">Calendar</.link>
        <a class="link link-hover">Community</a>
        <a class="link link-hover">Resources</a>
      </nav>
      <nav>
        <h6 class="footer-title">Gurdwara</h6>
        <.link navigate={~p"/about"} class="link link-hover">About us</.link>
        <.link navigate={~p"/contact"} class="link link-hover">Contact</.link>
        <a class="link link-hover">News</a>
      </nav>
      <nav>
        <h6 class="footer-title">Contact</h6>
        <a class="flex items-center gap-1.5">
          <.icon name="hero-map-pin" class="size-4 shrink-0" />
          <p>470 Cecelia Rd Victoria, BC V8T 4T5</p>
        </a>
        <a class="flex items-center gap-1.5">
          <.icon name="hero-phone" class="size-4 shrink-0" />
          <p>+1 250 475-2280</p>
        </a>
        <a class="flex items-center gap-1.5">
          <.icon name="hero-envelope" class="size-4 shrink-0" />
          <p>singhsabhayyj@gmail.com</p>
        </a>
        <a class="flex items-center gap-1.5">
          <.icon name="hero-clock" class="size-4 shrink-0" />
          <p>4:30AM - 8:00PM</p>
        </a>
      </nav>
    </footer>
    <footer class="footer bg-base-200 text-base-content border-base-300 border-t px-10 py-4">
      <aside class="grid-flow-col items-center">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="24"
          height="24"
          viewBox="0 0 24 24"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <path d="M18 22V2.8a.8.8 0 0 0-1.17-.71L5.45 7.78a.8.8 0 0 0 0 1.44L18 15.5" />
        </svg>
        <p>
          Gurdwara Singh Sabha<br /> Serving the Sikh community with devotion and compassion.
        </p>
      </aside>
      <nav class="md:place-self-center md:justify-self-end">
        <div class="grid grid-flow-col gap-4">
          <a
            href="https://youtube.com/@singhsabhavictoria"
            target="_blank"
            rel="noopener noreferrer"
            aria-label="YouTube"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="24"
              height="24"
              viewBox="0 0 24 24"
              class="fill-current"
            >
              <title>YouTube</title>
              <path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z" />
            </svg>
          </a>
          <a
            href="https://facebook.com/singhsabhavictoria"
            target="_blank"
            rel="noopener noreferrer"
            aria-label="Facebook"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="24"
              height="24"
              viewBox="0 0 24 24"
              class="fill-current"
            >
              <title>Facebook</title>
              <path d="M9.101 23.691v-7.98H6.627v-3.667h2.474v-1.58c0-4.085 1.848-5.978 5.858-5.978.401 0 .955.042 1.468.103a8.68 8.68 0 0 1 1.141.195v3.325a8.623 8.623 0 0 0-.653-.036 26.805 26.805 0 0 0-.733-.009c-.707 0-1.259.096-1.675.309a1.686 1.686 0 0 0-.679.622c-.258.42-.374.995-.374 1.752v1.297h3.919l-.386 2.103-.287 1.564h-3.246v8.245C19.396 23.238 24 18.179 24 12.044c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.628 3.874 10.35 9.101 11.647Z" />
            </svg>
          </a>
          <a
            href="https://wa.me/12504752280"
            target="_blank"
            rel="noopener noreferrer"
            aria-label="WhatsApp"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="24"
              height="24"
              class="fill-current"
              viewBox="0 0 24 24"
            >
              <title>WhatsApp</title>
              <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413Z" />
            </svg>
          </a>
        </div>
      </nav>
    </footer>
    """
  end
end
