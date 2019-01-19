defmodule Mix.Tasks.Lingohub.Sync do
  use Mix.Task

  def run(args) do
    Mix.Task.run("lingohub.upload", args)
    Mix.shell().info("Wait for processing")
    Process.sleep(:timer.seconds(10))
    Mix.Task.run("lingohub.download", args)
  end
end
