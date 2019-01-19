defmodule LingoHub.Gettext do
  @moduledoc """
  Convenience module for interacting with gettext based .po files.
  """
  @doc """
  List all local .pot files
  """
  @spec list_local_sources() :: list(%{path: Path.t(), filename: binary})
  def list_local_sources do
    Path.wildcard("priv/gettext/*.pot")
    |> Enum.map(fn path ->
      ["priv", "gettext", filename] = Path.split(path)
      %{path: path, filename: filename}
    end)
  end

  @doc """
  List all local .po files for the translated locales
  """
  @spec list_local_resources() :: list(%{path: Path.t(), name: binary})
  def list_local_resources do
    Path.wildcard("priv/gettext/*/LC_MESSAGES/*.po")
    |> Enum.map(fn path ->
      ["priv", "gettext", locale, "LC_MESSAGES", filename] = Path.split(path)
      locale = locale_translate_to_lingohub(locale)
      name = Path.basename(filename, ".po")
      %{path: path, name: "#{name}.#{locale}.po"}
    end)
  end

  defp locale_translate_to_lingohub(<<locale::binary-size(2), "_", region::binary-size(2)>>),
    do: "#{locale}-#{region}"

  defp locale_translate_to_lingohub(<<locale::binary-size(2)>>),
    do: locale

  @doc """
  Ge the path based on the filename of the online resource
  """
  @spec local_path_for_resource(LingoHub.Resource.t()) :: Path.t()
  def local_path_for_resource(%LingoHub.Resource{} = resource) do
    filename =
      resource.name
      |> Path.basename(".po")
      |> Path.basename(".#{resource.locale}")
      |> Kernel.<>(".po")

    locale = locale_translate_to_gettext(resource.locale)

    Path.join(["priv", "gettext", locale, "LC_MESSAGES", filename])
  end

  defp locale_translate_to_gettext(<<locale::binary-size(2), "-", region::binary-size(2)>>),
    do: "#{locale}_#{region}"

  defp locale_translate_to_gettext(<<locale::binary-size(2)>>),
    do: locale
end
