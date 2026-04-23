defmodule SinghSabhaWeb.AboutLive do
  use SinghSabhaWeb, :live_view
  use SinghSabhaWeb, :html

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h1 class="text-2xl font-bold">About</h1>

      <.section_card title="Gurdwara Singh Sabha Victoria">
        <p class="text-sm text-base-content/70">
          Established in 1999, Gurdwara Singh Sabha in Victoria is a non-profit organization
          dedicated to promoting Sikh principles and providing spiritual, social, and educational
          support to the community.
        </p>
        <p class="text-sm text-base-content/70">
          Guided by the Akal Takht Sahib directive, the Gurdwara focuses on serving the needs of
          the Sikh community, especially those who are vulnerable, isolated, or at risk. Through
          services such as langar and educational programs in Sikh spirituality, ethics, and culture,
          the Gurdwara fosters unity, guidance, and a deeper connection to Sikh teachings.
        </p>
      </.section_card>

      <.section_card title="Our History">
        <p class="text-sm text-base-content/70">
          For twenty five blessed years, Gurdwara Singh Sabha has stood as a lighthouse of Sikh
          discipline, unity, and unwavering devotion to Gurmat principles. What began in 1998 as a
          humble, faith driven effort has blossomed through courage, collective seva, and the
          unending grace of Guru Sahib.
        </p>
        <p class="text-sm text-base-content/70">
          The Gurdwara was established during a time of deep division in the local sangat following
          the Langar Hukamnama issued by Sri Akal Takht Sahib. A group of principled Gursikhs rose
          above conflict with a single shared purpose: to uphold Akal Takht Sahib's Rehat Maryada
          while preserving peace within the wider Sikh community.
        </p>
        <p class="text-sm text-base-content/70">
          The first Gurdwara Sahib program was held on January 25, 1998, and in March 1999 the
          Gurdwara was formally registered as the Gurdwara Singh Sabha Society of Victoria. Later
          that year, the sangat purchased its first warehouse property, transforming a simple
          structure into a beacon of Sikhi for the growing community.
        </p>
        <p class="text-sm text-base-content/70">
          Through careful planning and financial transparency, the Gurdwara steadily expanded with
          Phase One completed in 2004 to 2005 and the main Diwan Hall in 2007 to 2008. In 2010,
          an additional property at 482 Cecelia Road was purchased, securing future growth. Most
          recently, as the Gurdwara marked its 25th anniversary, the sangat was blessed with the
          acquisition of a new building valued at $5.8 million, a full circle journey completed
          exactly a quarter century after the sangat first gathered in that very same warehouse
          during the 300th Khalsa Sajna Diwas celebrations.
        </p>
        <p class="text-sm">
          <span class="text-base-content/60">Read the full story in the</span>
          <a
            href="https://fctimes.ca/wp-admin/admin-ajax.php?action=get_viewer&scrolling=-1&selection_tool=0&spreads=0&file=https://fctimes.ca/wp-content/uploads/2026/02/February-2026-Newspaper-compressed.pdf"
            target="_blank"
            class="link link-primary inline-flex items-center gap-1"
          >
            February 2026 edition of Fateh Care Times
            <.icon name="hero-arrow-top-right-on-square" class="size-3" />
          </a>
        </p>
      </.section_card>

      <.section_card title="The Akal Takht Sahib Directive">
        <p class="text-sm text-base-content/70">
          On April 20, 1998, a significant meeting was held at the Akal Takht Sahib in Amritsar,
          led by Jathedar Bhai Ranjit Singh. This gathering resulted in a Hukamnama (official edict)
          that reaffirmed a core Sikh tradition: Langar, the free community meal served in every
          Gurdwara, should be eaten while sitting on the floor.
        </p>
        <p class="text-sm text-base-content/70">
          This practice embodies two essential Sikh principles: humility and equality, ensuring
          that everyone, regardless of background, sits and eats together as equals. Today, over
          99% of the world's 20,000+ Gurdwaras have embraced this directive.
        </p>
        <p class="text-sm">
          <span class="text-base-content/60">View the original</span>
          <a
            href="/documents/langar_hukamnama_1998.pdf"
            target="_blank"
            class="link link-primary inline-flex items-center gap-1"
          >
            Langar Hukamnama (1998) <.icon name="hero-arrow-top-right-on-square" class="size-3" />
          </a>
        </p>
      </.section_card>

      <.section_card title="Our Guiding Principles">
        <div class="join join-vertical w-full">
          <.principle_item
            icon="hero-heart"
            title="Langar Tradition"
            description="Communal meals are served and eaten while seated on a matted floor. All participants must have their heads covered and shoes removed as a mark of respect."
          />
          <.principle_item
            icon="hero-document-text"
            title="Authority and Code of Conduct"
            description="We recognize the supreme authority of Akal Takht Sahib and adhere to the Panth-approved Sikh Rehat Maryada (Code of Conduct)."
          />
          <.principle_item
            icon="hero-user-group"
            title="Promotion of Sikhism"
            description="We actively promote Sikhism through Amrit Sanchar (Sikh baptism ceremony), youth programs, and other Gurmat activities."
          />
          <.principle_item
            icon="hero-bookmark"
            title="Guidelines for Preaching"
            description="All Katha, Kirtan, or teachings must be conducted by individuals who maintain Sikhi Saroop, with exceptions for youth educational programs."
          />
          <.principle_item
            icon="hero-clipboard-document-list"
            title="Duties in Attendance of Guru Granth Sahib Ji"
            description="Responsibilities such as performing Akhand Path or Sehaj Path must be carried out exclusively by Amritdhari Sikhs."
          />
        </div>
      </.section_card>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "About")}
  end

  attr :title, :string, required: true
  slot :inner_block, required: true

  defp section_card(assigns) do
    ~H"""
    <div class="flex flex-col gap-3 rounded-md border border-base-300 p-4">
      <h2 class="font-semibold">{@title}</h2>
      <div class="flex flex-col gap-3">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :icon, :string, required: true
  attr :title, :string, required: true
  attr :description, :string, required: true

  defp principle_item(assigns) do
    ~H"""
    <div class="collapse collapse-arrow join-item border border-base-300">
      <input type="checkbox" />
      <div class="collapse-title flex items-center gap-2 font-medium text-sm">
        <.icon name={@icon} class="size-4 shrink-0" />
        {@title}
      </div>
      <div class="collapse-content">
        <p class="text-sm text-base-content/70">{@description}</p>
      </div>
    </div>
    """
  end
end
