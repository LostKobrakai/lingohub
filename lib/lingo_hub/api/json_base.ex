defmodule LingoHub.Api.JsonBase do
  @moduledoc false
  use HTTPoison.Base

  defdelegate process_request_url(url), to: LingoHub.Api.Base

  def process_response_body(body) do
    LingoHub.json_library().decode!(body)
  end
end
