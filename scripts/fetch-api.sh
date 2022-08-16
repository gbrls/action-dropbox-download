#!/bin/sh
mix local.hex --force 
elixir scripts/main.exs
ls -la
