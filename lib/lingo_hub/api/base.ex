defmodule LingoHub.Api.Base do
  @moduledoc false
  use HTTPoison.Base

  @endpoint URI.parse("https://api.lingohub.com/v1/")

  def process_request_url(url) do
    %{host: nil, path: path} = URI.parse(url)

    @endpoint
    |> Map.update!(:path, &Path.join(&1, path))
    |> URI.to_string()
  end
end
