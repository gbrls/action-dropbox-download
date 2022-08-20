#!/bin/sh

cd .dropbox || true

mix local.rebar --force 
mix local.hex --force 
elixir scripts/main.exs
unzip data.zip -d ../$OUT_PATH

rm -rf ../.dropbox || true
