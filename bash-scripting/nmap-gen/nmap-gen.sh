#!/bin/bash

# generate common nmap commands based on provided IP and ports
orig_dir=$PWD
trap "cd '$orig_dir'" EXIT

cd $(dirname "$0")
source "./argparse/argparse.sh"
arg_desc "Generate common nmap commands based on provided IP and ports."
arg_pos "ip" "IP" "Target IP address or range." "" 1
arg_opt "ports" "PORTS" "-p" "--ports" "Comma-separated list of ports to scan. Range format also accepted." "" 0
arg_flag "fast" "T4" "-f" "--fast" "Use -T4 for fast scan."
arg_flag "verbose" "VERBOSE" "-v" "--verbose" "Enable verbose output."

arg_parse "$@"

cmds=()
OPTS=""

if [[ -n "$PORTS" ]]; then
    # passing args straight to nmap. Not going to reinvent the wheel.
    OPTS="-p $PORTS"
else
    # Let nmap do the top 1000 ports if none specified
    OPTS=""
fi

if (( $T4 )); then
    OPTS="$OPTS -T4"
fi

if (( $VERBOSE )); then
    OPTS="$OPTS -vvv"
fi


cmds=(
        "sudo nmap -sS $OPTS $IP #stealth syn scan"
        "nmap -sV -sC $OPTS $IP #service version and script scan"
        "sudo nmap -O $OPTS $IP #OS detection"
        "sudo nmap -O -sC -sV $OPTS $IP #loud but will save you - everything"
    )

echo "Generated nmap commands:"
for cmd in "${cmds[@]}"; do
    echo "$cmd"
done

#return to original directory on exit
cd "$orig_dir"