#!/usr/bin/env bash
# build.sh - Pack multi-file mal JS impl into single file for cscript/jsc
# Usage: bash build.sh [step0_repl|step1_read_print|...|stepA_mal]
set -e

IMPL_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$IMPL_DIR"
mkdir -p dist

# Common files (order matters - dependencies first)
COMMON_FILES="runtime.js io.js types.js reader.js printer.js env.js core.js interop.js"

# Step files
STEP_FILE="$1.js"

if [ -z "$1" ]; then
    echo "Usage: bash build.sh <step_name>"
    echo "  e.g. bash build.sh step0_repl"
    exit 1
fi

if [ ! -f "$STEP_FILE" ]; then
    echo "Error: $STEP_FILE not found"
    exit 1
fi

OUTPUT="dist/$STEP_FILE"

# Concatenate all files - node_readline.js is excluded (Node-only, not needed for cscript/jsc)
cat $COMMON_FILES "$STEP_FILE" > "$OUTPUT"

# Get line count
LINES=$(wc -l < "$OUTPUT")
echo "Built $OUTPUT ($LINES lines)"
