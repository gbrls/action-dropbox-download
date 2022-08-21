# action-dropbox-download

This action downloads the selected dropbox folder to a given path.

```
name: test workflow
on:
  workflow_dispatch:
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: gbrls/action-dropbox-download@main
        with:
          dropbox-refresh-token: ${{ secrets.DROPBOX_REFRESH_TOKEN }}
          source-path: '/code'
          destination-path: 'downloaded'
      - name: List artifacts
        run: |
          ls -la
          find
```

You need to provide the `dropbox-refresh-token` input. For now this process is
manual and a bit involved.
