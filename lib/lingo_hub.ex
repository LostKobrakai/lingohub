defmodule LingoHub do
  @moduledoc """
  Documentation for LingoHub.
  """
  alias LingoHub.Api.Base, as: API
  alias LingoHub.Api.JsonBase, as: JSONAPI

  @type account :: String.t()
  @type project :: String.t()
  @type opts :: Keyword.t()

  @doc false
  @spec json_library() :: module()
  def json_library do
    Application.get_env(:lingo_hub, :json_library, Jason)
  end

  @doc """
  Login using username and passwor to retrive the users api token.
  """
  @spec login(String.t(), String.t()) :: {:ok, token :: String.t()} | {:error, term}
  def login(user_name, password) do
    with {:ok, %{body: %{"api_key" => token}, status_code: 200}} <-
           JSONAPI.post("sessions", "", [], hackney: [basic_auth: {user_name, password}]) do
      {:ok, token}
    else
      err -> handle_errors(err)
    end
  end

  @doc """
  Retrieve all the projects a user has access to.
  """
  @spec list_projects(opts) :: {:ok, list(LingoHub.Project.t())} | {:error, term}
  def list_projects(opts) do
    with {:ok, token} <- get_auth(Keyword.get(opts, :auth)),
         {:ok, %{body: body, status_code: 200}} <-
           JSONAPI.get("projects", [], params: [auth_token: token]) do
      {:ok, convert_projects(body)}
    else
      err -> handle_errors(err)
    end
  end

  defp convert_projects(%{"members" => members}) do
    Enum.map(members, &convert_project(&1))
  end

  defp convert_project(%{"links" => [%{"href" => uri}]} = data) do
    {account, name} = extract_account_and_name(uri)
    convert_project(account, name, data)
  end

  defp convert_project(account, name, %{"title" => title}) do
    %LingoHub.Project{title: title, account: account, name: name}
  end

  defp extract_account_and_name(uri) do
    uri = URI.parse(uri)
    ["/", "v1", account, "projects", name] = Path.split(uri.path)
    {account, name}
  end

  @doc """
  Retrieve details for a given project of an account.
  """
  @spec fetch_project(account, project, opts) :: {:ok, LingoHub.Project.t()} | {:error, term}
  def fetch_project(account, project, opts) when is_binary(account) and is_binary(project) do
    path = Path.join([account, "projects", project])

    with {:ok, token} <- get_auth(Keyword.get(opts, :auth)),
         {:ok, %{body: body, status_code: 200}} <-
           JSONAPI.get(path, [], params: [auth_token: token]) do
      {:ok, convert_project(account, project, body)}
    else
      err -> handle_errors(err)
    end
  end

  @doc """
  Retrive a list of resources for a given project of an account.
  """
  @spec list_resources(account, project, opts) ::
          {:ok, list(LingoHub.Resource.t())} | {:error, term}
  def list_resources(account, project, opts) when is_binary(account) and is_binary(project) do
    path = Path.join([account, "projects", project, "resources"])

    with {:ok, token} <- get_auth(Keyword.get(opts, :auth)),
         {:ok, %{body: body, status_code: 200}} <-
           JSONAPI.get(path, [], params: [auth_token: token]) do
      {:ok, convert_resources(account, project, body)}
    else
      err -> handle_errors(err)
    end
  end

  defp convert_resources(account, project, %{"members" => members}) do
    Enum.map(members, &convert_resource(account, project, &1))
  end

  defp convert_resource(account, project, %{"name" => name, "project_locale" => locale}) do
    %LingoHub.Resource{
      locale: locale,
      name: name,
      account: account,
      project: project
    }
  end

  @doc """
  Retrive the contents of a given resource.
  """
  @spec fetch_resource(account, project, filename :: binary, opts) ::
          {:ok, binary} | {:error, term}
  def fetch_resource(account, project, filename, opts)
      when is_binary(account) and is_binary(project) and is_binary(filename) do
    path = Path.join([account, "projects", project, "resources", filename])

    with {:ok, token} <- get_auth(Keyword.get(opts, :auth)),
         params = Keyword.merge([auth_token: token], Keyword.get(opts, :params, [])),
         {:ok, %{body: body, status_code: 200}} <- API.get(path, [], params: params) do
      {:ok, body}
    else
      err -> handle_errors(err)
    end
  end

  @doc """
  Upload the contents of a file
  """
  @spec put_resource(account, project, file, opts) :: :ok | {:error, term}
        when file: {:file, Path.t()} | {:binary, iodata}
  def put_resource(account, project, file, opts)
      when is_binary(account) and is_binary(project) do
    path = Path.join([account, "projects", project, "resources"])
    form = {:multipart, [file_part(file, opts)]}

    with {:ok, token} <- get_auth(Keyword.get(opts, :auth)),
         params = Keyword.merge([auth_token: token], Keyword.get(opts, :params, [])),
         {:ok, %{status_code: status}} when status in [200, 201] <-
           JSONAPI.post(path, form, [], params: params) do
      :ok
    else
      err -> handle_errors(err)
    end
  end

  @spec file_part(file, Keyword.t()) :: tuple()
        when file: {:file, Path.t()} | {:binary, iodata}
  defp file_part({:file, path}, opts) do
    file_part({File.read!(path), Path.basename(Keyword.get(opts, :filename, path))})
  end

  defp file_part({:binary, contents}, opts) do
    file_part({contents, Path.basename(Keyword.fetch!(opts, :filename))})
  end

  defp file_part({contents, filename}) do
    {"file", contents, {"form-data", [{"name", "file"}, {"filename", filename}]}, []}
  end

  @spec handle_errors({:ok, term} | {:error, term}) :: {:error, term}
  defp handle_errors({:ok, %HTTPoison.Response{status_code: status}}) do
    {:error, {:status, status}}
  end

  defp handle_errors({:error, _} = err), do: err

  @spec get_auth(nil | binary | (() -> {:ok, binary} | {:error, term})) ::
          {:ok, binary} | {:error, term}
  defp get_auth(callback) when is_function(callback, 0), do: callback.()
  defp get_auth(token) when is_binary(token), do: {:ok, token}
  defp get_auth(nil), do: {:error, :notoken}
end
