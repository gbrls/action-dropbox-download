#!/bin/sh

mix local.rebar --force 
mix local.hex --force 
elixir scripts/main.exs
ls -la
