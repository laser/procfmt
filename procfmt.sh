#!/usr/bin/env bash

set -f

parse() {
  local input="$1"
  local d=""
  local stack=""

  # reset global
  parse_output=()

  for (( i=0; i<${#input}; i++ )); do
    local char="${input:i:1}"

    if [ "$char" == "'" ]; then
      stack+="$char"

      if [ -z "$d" ]; then
        d="'"
        continue
      fi

      parse_output=("${parse_output[@]}" "$stack")
      stack=""
      d=""
      continue
    fi

    if [ -z "$d" ] && [ "$char" == " " ]; then
      if [ -n "$stack" ]; then
        parse_output=("${parse_output[@]}" "$stack")
      fi

      stack=""
      continue
    fi

    stack+="$char"
  done

  if [ -n "$stack" ]; then
    parse_output=("${parse_output[@]}" "$stack")
  fi
}

ignored_process_types=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -i|--ignore)
      ignored_process_types="$2"
      shift # past argument
      shift # past value
      ;;
    -*|--*)
      echo "unhandled option: $1"
      exit 1
      ;;
    *)
      shift
      ;;
  esac
done

# read stdin to a variable; we're going to range over it twice
lines=$(cat)

# compute the longest process type, ignoring anything in our ignore-list
process_type_max_width=0
while IFS= read -r line; do
  if [[ $line == *:* ]] && [[ ! $line == \#* ]] && [[ ! $ignored_process_types == "${line%%:*}" ]]; then
    left=${line%%:*}

    if [ ${#left} -gt $process_type_max_width ]; then
      process_type_max_width=${#left}
    fi
  fi
done < <(printf '%s\n' "$lines")

# range over each line, formatting (or ignoring) as needed
while IFS= read -r line; do
  # pass through comments and empty lines
  if [[ $line == \#* ]] || [[ -z $line ]]; then
    echo "$line"
    continue
  fi

  # pass through lines with a process type that's in our ignore list
  if [[ -n $ignored_process_types ]] && [[ $ignored_process_types == "${line%%:*}" ]]; then
    echo "$line"
    continue
  fi

  # declare an array of environment variable-setting strings, e.g. ["FOO=1", "BAR=abc"]
  environment_variables=()

  # declare an array to hold other parts of the command, e.g. ["env", "bundle", "exec", "rake"]
  others=()

  # an array containing the process type and the command
  IFS=':' read -ra parts <<< "$line"

  # extract the command and strip superfluous whitespace
  command=${parts[@]:1}
  command=${command//+([[:blank:]])/ }

  # parse into chunks
  parse "${command}"

  prefix=()
  sortables=()
  suffix=()

  sort_mode=1
  for part in "${parse_output[@]}"; do
    # if someone's using env, they almost certainly want it first
    if [[ $part == "env" ]]; then
      prefix+=("$part")
      continue
    fi

    # if we think it's an environment variable, throw it into the array of
    # things to sort
    IFS='=' read -ra chunks <<< "$part"
    if [[ "${chunks[0]//_/}" =~ ^[[:upper:]]+$ ]]; then
      if [[ $sort_mode -eq 1 ]]; then
        sortables+=("$part")
        continue
      fi
    fi

    # if we hit this point, we're probably working with the command and its
    # flags; don't sort anything from hereon out
    sort_mode=0
    suffix+=("$part")
  done

  # alpha-sort the environment variable list so that ["FOO=1", "BAR=2"] becomes ["BAR=2", "FOO=1"]
  sorted=($(printf '%s\n' "${sortables[@]}"|sort))

  # glue our parts back together and write to stdout
  head="${parts[0]}:$(printf '%*s' $((process_type_max_width - ${#parts[0]} + 1)) '')"

  # concatenate all three arrays together
  concat=($(echo ${prefix[*]}) $(echo ${sorted[*]}) $(echo ${suffix[*]}))

  tail="${concat[@]}"

  echo "${head}${tail}"
done < <(printf '%s\n' "$lines")
