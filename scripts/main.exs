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
  @token System.get_env("DROPBOX_TOKEN")
  @refresh_token System.get_env("REFRESH_TOKEN")
  @auth_code System.get_env("AUTHORIZATION_CODE")
  @verifier System.get_env("VERIFIER")

  def refresh_token, do: @refresh_token

  def authorize_url(codes) do
    "https://www.dropbox.com/oauth2/authorize?client_id=fju3fjnb714ptef&response_type=code&code_challenge=#{codes.challenge}&token_access_type=offline&code_challenge_method=S256"
  end

  def fetch_refresh_token() do
    path = "https://api.dropbox.com/oauth2/token"

    data =
      [
        "code=#{@auth_code}",
        "grant_type=authorization_code",
        "code_verifier=#{@verifier}",
        "client_id=fju3fjnb714ptef"
      ]
      |> Enum.join("\n")

    case HTTPoison.post(path, data, [], []) do
      {:ok, %HTTPoison.Response{body: body, headers: _headers}} -> body |> IO.inspect()
      any -> IO.inspect(any)
    end
  end

  def list_folder(folder) do
    body = %{path: "#{folder}"} |> Jason.encode!()
    req_body("https://api.dropboxapi.com/2/files/list_folder", body)
  end

  def download_zip(folder, filename) do
    arg = %{path: "#{folder}"} |> Jason.encode!()
    bin_data = req_arg("http://gbrls.space", arg)
    #bin_data = req_arg("https://content.dropboxapi.com/2/files/download_zip", arg)

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

args = System.argv()

dropbox_dir_path = System.get_env("DIR_PATH", "/dotfiles")
# it doesn't make a difference because latter we'll extract it to a user
# defined folder
local_path = "data.zip"

if length(args) > 0 && hd(args) == "url" do
  codes = Main.code()
  IO.puts(Dropbox.authorize_url(codes) <> "\n" <> codes.verifier)
else
  Dropbox.download_zip(dropbox_dir_path, local_path)
end
