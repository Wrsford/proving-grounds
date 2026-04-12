#!/usr/bin/env bash
# argparse.sh exits on invalid or missing arguments

declare -Ag _ARG_KIND=()
declare -Ag _ARG_VAR=()
declare -Ag _ARG_SHORT=()
declare -Ag _ARG_LONG=()
declare -Ag _ARG_HELP=()
declare -Ag _ARG_DEF=()
declare -Ag _ARG_REQ=()
declare -ag _ARG_ORDER=()
declare -ag _ARG_POS_ORDER=()

_ARG_PROG="${_ARG_PROG:-${0##*/}}"
_ARG_DESC="${_ARG_DESC:-}"

arg_desc() { _ARG_DESC=$1; }

arg_flag() { 
  local n=$1 v=$2 s=$3 l=$4 h=$5
  _ARG_KIND[$n]=flag; _ARG_VAR[$n]=$v; _ARG_SHORT[$n]=$s; _ARG_LONG[$n]=$l
  _ARG_HELP[$n]="$h"; _ARG_DEF[$n]=0; _ARG_REQ[$n]=0; _ARG_ORDER+=("$n")
}

arg_opt() { 
  local n=$1 v=$2 s=$3 l=$4 h=$5 d=${6-} r=${7-0}
  _ARG_KIND[$n]=opt; _ARG_VAR[$n]=$v; _ARG_SHORT[$n]=$s; _ARG_LONG[$n]=$l
  _ARG_HELP[$n]="$h"; _ARG_DEF[$n]="$d"; _ARG_REQ[$n]=$r; _ARG_ORDER+=("$n")
}

arg_pos() {
  local n=$1 v=$2 h=$3 d=${4-} r=${5-1}
  _ARG_KIND[$n]=pos; _ARG_VAR[$n]=$v; _ARG_HELP[$n]="$h"
  _ARG_DEF[$n]="$d"; _ARG_REQ[$n]=$r; _ARG_POS_ORDER+=("$n"); _ARG_ORDER+=("$n")
}

_arg_by_long() { local k; for k in "${!_ARG_LONG[@]}"; do [[ "${_ARG_LONG[$k]}" = "$1" ]] && echo "$k" && return 0; done; return 1; }
_arg_by_short() { local k; for k in "${!_ARG_SHORT[@]}"; do [[ "${_ARG_SHORT[$k]}" = "$1" ]] && echo "$k" && return 0; done; return 1; }

_arg_help() {
    local n optsig line pos_usage=""
    for n in "${_ARG_POS_ORDER[@]}"; do
        if [[ $n == "--" ]]; then pos_usage+="[ARGS...] "; else pos_usage+="[$n] "; fi
    done
    echo "Usage: $_ARG_PROG [options] $pos_usage"
    [[ -n $_ARG_DESC ]] && echo; echo "$_ARG_DESC"
    echo; echo "Options:"
    printf "  %-18s %s\n" "-h, --help" "Show this help and exit."
    for n in "${_ARG_ORDER[@]}"; do
        [[ "${_ARG_KIND[$n]}" = pos ]] && continue
        optsig=""
        [[ -n "${_ARG_SHORT[$n]}" ]] && optsig+="${_ARG_SHORT[$n]}"
        [[ -n "${_ARG_LONG[$n]}" ]] && optsig+="${optsig:+, }${_ARG_LONG[$n]}"
        [[ "${_ARG_KIND[$n]}" = opt ]] && optsig+=" VALUE"
        line="${_ARG_HELP[$n]}"
        [[ "${_ARG_REQ[$n]}" = 1 ]] && line+=" (required)"
        [[ -n "${_ARG_DEF[$n]}" ]] && line+=" [default: ${_ARG_DEF[$n]}]"
        printf "  %-18s %s\n" "$optsig" "$line"
    done
    if ((${#_ARG_POS_ORDER[@]})); then
        echo; echo "Positionals:"
        for n in "${_ARG_POS_ORDER[@]}"; do
            local sig="$n"; [[ $n == "--" ]] && sig="ARGS..."
            line="${_ARG_HELP[$n]}"
            [[ "${_ARG_REQ[$n]}" = 1 && $n != "--" ]] && line+=" (required)"
            [[ -n "${_ARG_DEF[$n]}" && $n != "--" ]] && line+=" [default: ${_ARG_DEF[$n]}]"
            printf "  %-18s %s\n" "$sig" "$line"
        done
    fi
}

_arg_err() { 
    echo "Error: $*" >&2
    echo >&2
    _arg_help >&2
    exit 1
}

arg_parse() {
    local n

    # init defaults safely
    for n in "${_ARG_ORDER[@]}"; do
        case "${_ARG_KIND[$n]}" in
            flag) eval "${_ARG_VAR[$n]}=0" ;;
            opt) eval "${_ARG_VAR[$n]}='${_ARG_DEF[$n]-}'" ;;
            pos) 
                if [[ $n == "--" ]]; then eval "${_ARG_VAR[$n]}=()" 
                else eval "${_ARG_VAR[$n]}='${_ARG_DEF[$n]-}'"; fi
                ;;
        esac
    done

    local argv=()
    while (($#)); do
        case "$1" in
            -h|--help) _arg_help; exit 0 ;;
            --) shift; argv+=("$@"); set --; break ;;
            --*=*) 
                n=$(_arg_by_long "${1%%=*}") || _arg_err "unknown option: $1"
                eval "${_ARG_VAR[$n]}='${1#*=}'"; shift ;;
            --*) 
                n=$(_arg_by_long "$1") || _arg_err "unknown option: $1"
                if [[ "${_ARG_KIND[$n]}" = flag ]]; then eval "${_ARG_VAR[$n]}=1"; shift
                else
                    shift
                    [[ $# -eq 0 ]] && _arg_err "option requires a value: $1"
                    eval "${_ARG_VAR[$n]}='$1'"; shift
                fi ;;
            -?*)
                local cluster="${1#-}"; shift
                local s
                while [[ -n $cluster ]]; do
                    s="-${cluster:0:1}"; cluster="${cluster:1}"
                    n=$(_arg_by_short "$s") || _arg_err "unknown option: $s"
                    if [[ "${_ARG_KIND[$n]}" = flag ]]; then eval "${_ARG_VAR[$n]}=1"
                    else
                        if [[ -n $cluster ]]; then
                            eval "${_ARG_VAR[$n]}='$cluster'"; cluster=""
                        else
                            [[ $# -eq 0 ]] && _arg_err "option requires a value: $s"
                            eval "${_ARG_VAR[$n]}='$1'"; shift
                        fi
                    fi
                done ;;
            *) argv+=("$1"); shift ;;
        esac
    done

    # assign positional args
    local pos_i=0 p
    for p in "${_ARG_POS_ORDER[@]}"; do
        if [[ $p == "--" ]]; then
            eval "${_ARG_VAR[$p]}=(\"\${argv[@]:$pos_i}\")"
        else
            eval "${_ARG_VAR[$p]}='${argv[$pos_i]-}'"
            ((pos_i++))
            [[ -z "${!_ARG_VAR[$p]}" && "${_ARG_REQ[$p]}" = 1 ]] && _arg_err "missing positional: $p"
        fi
    done

    # validate required options
    for n in "${_ARG_ORDER[@]}"; do
        if [[ "${_ARG_KIND[$n]}" = opt && "${_ARG_REQ[$n]}" = 1 ]]; then
            local ref="${_ARG_VAR[$n]}"
            [[ -z "${!ref-}" ]] && _arg_err "missing required option: ${_ARG_LONG[$n]:-${_ARG_SHORT[$n]}}"
        fi
    done
}
