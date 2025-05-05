#!/bin/bash
# optimize-font.sh

function fontOptimize(){

FONT_INPUT=$1
FONT_BASE=$(basename "$FONT_INPUT" .ttf)

pyftsubset "$FONT_INPUT" \
  --text="AaĄąBbCcĆćDdEeĘęFfGgHhIiJjKkLlŁłMmNnŃńOoÓóPpRrSsŚśTtUuWwYyZzŹźŻż0123456789!.,?:;()[]{}+-=<>\"'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" \
  --layout-features='*' \
  --output-file="${FONT_BASE}-polish.ttf"
}