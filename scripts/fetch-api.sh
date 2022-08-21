#!/bin/sh

# Downloads files from API using DRPOBOX_REFRESH_TOKEN

cd .dropbox || true

set -e

mix local.rebar --force 
mix local.hex --force 
elixir scripts/main.exs 

unzip data.zip -d ../$OUT_PATH

rm -rf ../.dropbox || true
