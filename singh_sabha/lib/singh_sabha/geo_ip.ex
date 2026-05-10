defmodule SinghSabha.GeoIP do
  @unknown %{lat: nil, lon: nil, country: nil, city: nil}

  def lookup("unknown"), do: @unknown
  def lookup(nil), do: @unknown

  def lookup(ip) do
    case Req.get("http://ip-api.com/json/#{ip}", params: [fields: "lat,lon,country,city,status"]) do
      {:ok, %{body: %{"status" => 200} = body}} ->
        %{
          lat: body["lat"],
          lon: body["lon"],
          country: body["country"],
          city: body["city"]
        }

      _ ->
        @unknown
    end
  end
end
