defmodule Mix.Tasks.Lingohub.Download do
  use Mix.Task

  def run(args, config \\ Mix.Project.config()) do
    {opts, _, _} = OptionParser.parse(args, strict: [token: :string])
    Application.ensure_all_started(:lingo_hub)

    account = get_in(config, [:lingo_hub, :account]) || prompt("Your account name?")
    project = get_in(config, [:lingo_hub, :project]) || prompt("Your project?")

    Mix.shell().info("Retrieving resources for #{account}:#{project}")

    with {:ok, token} <- get_auth(opts),
         {:ok, resources} <- LingoHub.list_resources(account, project, auth: token) do
      for resource <- resources do
        path = LingoHub.Gettext.local_path_for_resource(resource)
        Mix.shell().info("Download #{resource.name} to #{path}")
        update_local(resource, path, auth: token)
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

  def update_local(%LingoHub.Resource{} = resource, path, opts) do
    with {:ok, contents} <-
           LingoHub.fetch_resource(resource.account, resource.project, resource.name, opts) do
      write_file(path, contents)
    else
      err ->
        Mix.shell().error("Error downloading #{resource.path}")
        IO.inspect(err)
    end
  end

  defp write_file(path, contents) do
    :ok = File.mkdir_p!(Path.dirname(path))
    File.write(path, contents)
  end

  def prompt(msg) do
    msg
    |> Mix.shell().prompt()
    |> String.trim()
  end
end
