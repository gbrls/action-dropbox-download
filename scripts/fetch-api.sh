#!/bin/sh

# Downloads files from API using DRPOBOX_REFRESH_TOKEN

cd .dropbox || true

set -e

mix local.rebar --force 
mix local.hex --force 
elixir scripts/main.exs 

mv data.zip ../tmp-dropbox-data.zip

cd ..
rm -rf ./.dropbox || true


unzip tmp-dropbox-data.zip -d $OUT_PATH
chmod -R 666 $OUT_PATH
