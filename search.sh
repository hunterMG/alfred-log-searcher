#!/bin/bash

# Script Filter for Alfred Workflow - Search ClashX Meta logs
# Receives a search keyword as input and returns matching log entries as JSON items

LOG_DIR="$logDir"
KEYWORD="$1"

# Helper function to output a JSON item
output_item() {
    local title="$1"
    local subtitle="$2"
    local arg="$3"
    printf '    {\n'
    printf '        "subtitle": "%s",\n' "$(echo "$subtitle" | sed 's/"/\\"/g')"
    printf '        "arg": "%s",\n' "$(echo "$arg" | sed 's/"/\\"/g')"
    printf '        "title": "%s"\n' "$(echo "$title" | sed 's/"/\\"/g')"
    printf '    }'
}

# Validate input
if [[ -z "$KEYWORD" ]]; then
    echo '{"items": []}'
    exit 0
fi

# Check if log directory exists
if [[ ! -d "$LOG_DIR" ]]; then
    echo '{"items": []}'
    exit 1
fi

# Find the most recent log file in the directory
latest_log=$(find "$LOG_DIR" -type f -name "*.log" -o -name "*.txt" | sort -V | tail -1)

# If no log file found, exit
if [[ -z "$latest_log" ]]; then
    echo '{"items": []}'
    exit 1
fi

# Search for lines containing the keyword and get the 5 most recent
matches=$(grep -i "$KEYWORD" "$latest_log" | tail -5)
# reverse the order to show the most recent first, do not use tac
matches=$(echo "$matches" | awk '{print NR, $0}' | sort -rn | cut -d' ' -f2-)

# Start JSON output
echo '{"items": ['

# Check if there are any matches
if [[ -z "$matches" ]]; then
    # No results found - show helpful message
    output_item "No results for '$KEYWORD'" "Try to input another word" ""
else
    # Process each matching line
    first=true
    while IFS= read -r line; do
        # Extract date (format: DD/MM/YYYY, HH:MM:SS.mmm)
        date=$(echo "$line" | grep -oE '^[0-9]{2}/[0-9]{2}/[0-9]{4}, [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}')

        # Extract everything after "-->"
        rule=$(echo "$line" | sed 's/.*--> //')

        # Extract domain name (before the first colon and port)
        domain=$(echo "$rule" | grep -oE '^[^:]+')

        # Format the rule display:
        # Remove "match", replace "using" with "➡️", add emoji around RuleSet
        rule=$(echo "$rule" | sed 's/:[^ ]* match /🎯/g' | sed 's/ using /➡️/g' )

        # Skip if extraction failed
        if [[ -z "$date" ]] || [[ -z "$rule" ]] || [[ -z "$domain" ]]; then
            continue
        fi

        # Add comma before item (except for the first one)
        if [[ "$first" == false ]]; then
            echo ","
        fi
        first=false

        output_item "$date" "$rule" "$domain"
    done <<< "$matches"
    echo ""
fi

# Close JSON output
echo "]}"
