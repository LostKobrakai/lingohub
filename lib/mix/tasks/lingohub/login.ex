defmodule Mix.Tasks.Lingohub.Login do
  use Mix.Task

  def run(_args) do
    Application.ensure_all_started(:lingo_hub)

    user_name = prompt("Your user name?")
    password = prompt("Your password?")

    with {:ok, token} <- LingoHub.login(user_name, password) do
      Mix.shell().info("Retrieved token: #{token}")

      if Mix.shell().yes?("Store token?") do
        File.write(".lingohub", token)
      end
    end
  end

  def prompt(msg) do
    msg
    |> Mix.shell().prompt()
    |> String.trim()
  end
end
