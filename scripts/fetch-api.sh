#!/bin/sh

mix local.rebar --force 
mix local.hex --force 
elixir scripts/main.exs
unzip data.zip -d $OUT_PATH

