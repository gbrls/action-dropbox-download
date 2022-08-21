#!/bin/sh

# Downloads files from API using DRPBOX_TOKEN

cd .dropbox || true

mix local.rebar --force 
mix local.hex --force 
elixir scripts/main.exs $OPERATION > result.txt

unzip data.zip -d ../$OUT_PATH

rm -rf ../.dropbox || true
