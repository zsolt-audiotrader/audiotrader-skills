#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract fields
model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "~"')
folder=$(basename "$cwd")
branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
dirty=""
ahead=0
behind=0
if [ -n "$branch" ]; then
    [ -n "$(git -C "$cwd" status --porcelain 2>/dev/null)" ] && dirty="*"
    counts=$(git -C "$cwd" rev-list --count --left-right '@{upstream}...HEAD' 2>/dev/null)
    if [ -n "$counts" ]; then
        behind=$(echo "$counts" | cut -f1)
        ahead=$(echo "$counts" | cut -f2)
    fi
fi
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')

# Colors matching PS1 (green + blue)
GREEN='\033[01;32m'
BLUE='\033[01;34m'
YELLOW='\033[01;33m'
DIM='\033[02m'
RESET='\033[00m'

# Context bar (10 chars wide) using ▰▱ (tr can't handle multi-byte unicode)
used_int=$(printf "%.0f" "$used_pct")
bar_filled=$((used_int * 10 / 100))
bar_empty=$((10 - bar_filled))
bar=""
for ((i=0; i<bar_filled; i++)); do bar+="▰"; done
for ((i=0; i<bar_empty; i++)); do bar+="▱"; done
bar=$(printf "${GREEN}%s${RESET}" "$bar")

# Context % color: green 0-70, yellow 70-90, red 90+
RED='\033[01;31m'
if [ "$used_int" -ge 90 ]; then
    PCT_COLOR="$RED"
elif [ "$used_int" -ge 70 ]; then
    PCT_COLOR="$YELLOW"
else
    PCT_COLOR="$GREEN"
fi

# Format cost
cost_fmt=$(printf "$%.2f" "$cost")

# Format duration as Xm Ys
duration_s=$((duration_ms / 1000))
mins=$((duration_s / 60))
secs=$((duration_s % 60))
if [ "$mins" -gt 0 ]; then
    duration_fmt="${mins}m ${secs}s"
else
    duration_fmt="${secs}s"
fi

# Build status line
status=$(printf "${GREEN}[%s]${RESET}" "$model")
status+=$(printf " ${BLUE}%s${RESET}" "$folder")
MAGENTA='\033[38;5;205m'
if [ -n "$branch" ]; then
    status+=$(printf " ${DIM}|${RESET} ${DIM}git:${RESET} ${MAGENTA} %s${RESET}" "$branch")
    [ -n "$dirty" ] && status+=$(printf "${YELLOW}%s${RESET}" "$dirty")
    [ "$ahead" -gt 0 ] 2>/dev/null && status+=$(printf " ${GREEN}↑%s${RESET}" "$ahead")
    [ "$behind" -gt 0 ] 2>/dev/null && status+=$(printf " ${RED}↓%s${RESET}" "$behind")
fi
status+=$(printf " ${DIM}|${RESET} %s ${PCT_COLOR}%d%%${RESET}" "$bar" "$used_int")
status+=$(printf " ${DIM}|${RESET} ${YELLOW}%s${RESET}" "$cost_fmt")
DIM_CYAN='\033[02;36m'
status+=$(printf " ${DIM}|${RESET} ${DIM_CYAN}%s${RESET}" "$duration_fmt")

echo "$status"
