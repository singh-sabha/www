defmodule SinghSabha.PromEx do
  use PromEx, otp_app: :singh_sabha

  @impl true
  def plugins do
    [
      PromEx.Plugins.Application,
      PromEx.Plugins.Beam,
      {PromEx.Plugins.Phoenix, router: SinghSabhaWeb.Router},
      SinghSabhaWeb.PromEx.Plugins.ViewerPlugin
    ]
  end
end
