defmodule Mix.Tasks.Lingohub.Upload do
  use Mix.Task

  def run(args, config \\ Mix.Project.config()) do
    {opts, _, _} = OptionParser.parse(args, strict: [token: :string, with_translations: :boolean])
    Application.ensure_all_started(:lingo_hub)

    account = get_in(config, [:lingo_hub, :account]) || prompt("Your account name?")
    project = get_in(config, [:lingo_hub, :project]) || prompt("Your project?")

    with {:ok, token} <- get_auth(opts) do
      Mix.shell().info("Retrieving local sources")

      if opts[:with_translations] do
        Mix.shell().info("Retrieving local resources")

        for %{path: path, name: name} <- LingoHub.Gettext.list_local_resources() do
          case LingoHub.put_resource(account, project, {:file, path}, auth: token, filename: name) do
            :ok -> Mix.shell().info("Uploaded #{path} for #{account}:#{project}")
            _ -> Mix.shell().error("Error uploading #{path} for #{account}:#{project}")
          end
        end
      end

      for %{path: path} <- LingoHub.Gettext.list_local_sources() do
        case LingoHub.put_resource(account, project, {:file, path}, auth: token) do
          :ok -> Mix.shell().info("Uploaded #{path} for #{account}:#{project}")
          _ -> Mix.shell().error("Error uploading #{path} for #{account}:#{project}")
        end
      end
    end
  end

  def get_auth(opts) do
    token =
      with :error <- Keyword.fetch(opts, :token),
           {:error, _} <- File.read(".lingohub") do
        {:ok, Mix.shell().prompt("Your auth token?")}
      end

    case token do
      {:ok, ""} -> {:error, :emptytoken}
      {:ok, token} -> {:ok, token}
      result -> result
    end
  end

  def prompt(msg) do
    msg
    |> Mix.shell().prompt()
    |> String.trim()
  end
end
