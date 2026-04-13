#!/bin/bash

# Script Filter for Alfred Workflow - Search ClashX Meta logs
# Receives a search keyword as input and returns matching log entries as JSON items

LOG_DIR="$HOME/Library/Logs/ClashX Meta"
KEYWORD="$1"

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

# Process each matching line
first=true
while IFS= read -r line; do
    # Extract date (format: DD/MM/YYYY, HH:MM:SS.mmm)
    date=$(echo "$line" | grep -oE '^[0-9]{2}/[0-9]{2}/[0-9]{4}, [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}')
    
    # Extract everything after "-->"
    rule=$(echo "$line" | sed 's/.*--> //')
    
    # Format the rule display:
    # Remove "match", replace "using" with "➡️", add emoji around RuleSet
    rule=$(echo "$rule" | sed 's/:[^ ]* match /🎯/g' | sed 's/ using /➡️/g' )
    
    # Skip if extraction failed
    if [[ -z "$date" ]] || [[ -z "$rule" ]]; then
        continue
    fi
    
    # Add comma before item (except for the first one)
    if [[ "$first" == false ]]; then
        echo ","
    fi
    first=false
    
    # Output JSON item with proper escaping
    printf '    {\n'
    printf '        "subtitle": "%s",\n' "$(echo "$rule" | sed 's/"/\\"/g')"
    printf '        "title": "%s"\n' "$(echo "$date" | sed 's/"/\\"/g')"
    printf '    }'
done <<< "$matches"

# Close JSON output
echo ""
echo "]}"
