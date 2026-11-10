# FileDeck

A lightweight dual-pane file manager for macOS.

## Build locally

```bash
swift build
swift run FileDeck
```

Create a local app bundle:

```bash
./build.sh
open build/FileDeck.app
```

## Build on GitHub

This repository includes `.github/workflows/build.yml`.
Push the project to GitHub, then open **Actions → Build macOS App**.
Download the `FileDeck-macOS` artifact when the workflow succeeds.
