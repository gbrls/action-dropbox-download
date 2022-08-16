#!/usr/bin/env elixir

Mix.install([{:jason, "~> 1.3"}, {:httpoison, "~> 1.8"}])

defmodule Dropbox do
  # @TODO: The OAuth 2 token seems to be very ephemeral.
  @token System.get_env("DROPBOX_TOKEN")

  def list_folder(folder) do
    body = %{path: "#{folder}"} |> Jason.encode!()
    req_body("https://api.dropboxapi.com/2/files/list_folder", body)
  end

  def download_zip(folder, filename) do
    arg = %{path: "#{folder}"} |> Jason.encode!()
    bin_data = req_arg("https://content.dropboxapi.com/2/files/download_zip", arg)

    {:ok, file} = File.open(filename, [:write])
    result = IO.binwrite(file, bin_data)

    File.close(file)

    {result, bin_data}
  end

  def req_body(path, body) do
    headers = [{"Content-Type", "application/json"}, {"Authorization", "Bearer #{@token}"}]

    case HTTPoison.post(path, body, headers, []) do
      {:ok, %HTTPoison.Response{body: body}} -> body |> Jason.decode!() |> IO.inspect()
      any -> IO.inspect(any)
    end
  end

  def req_arg(path, arg) do
    headers = [
      {"Content-Type", "text/plain; charset=utf-8"},
      {"Authorization", "Bearer #{@token}"},
      {"Dropbox-Api-Arg", arg}
    ]

    case HTTPoison.post(path, "", headers, []) do
      {:ok, %HTTPoison.Response{body: body, headers: _headers}} -> body |> IO.inspect()
      any -> IO.inspect(any)
    end
  end
end

dropbox_dir_path = System.get_env("DIR_PATH", "/dotfiles")
# it doesn't make a difference because latter we'll extract it to a user
# defined folder
local_path = "data.zip"

Dropbox.download_zip(dropbox_dir_path, local_path)
