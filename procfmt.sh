#!/usr/bin/env bash

set -f

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

  # iterate over each space-delimited element in the command, e.g. ["bundle", "exec", "rake", "TERM_CHILD=1"]
  for part in $command; do
    if [[ $part == *"="* ]]; then
      IFS='=' read -ra chunks <<< "$part"

      consider="${chunks[0]//_/}"

      if [[ ${consider} =~ ^[[:upper:]]+$ ]]; then
        environment_variables+=("$part")
        continue
      fi
    fi

    others+=("$part")
  done

  # alpha-sort the environment variable list so that ["FOO=1", "BAR=2"] becomes ["BAR=2", "FOO=1"]
  IFS=" " read -r -a sorted_environment_variables <<< "$(echo "${environment_variables[@]}" | sort)"

  # strip 'env' command out of the list, if present
  delete=(env)
  env_found=0
  for target in "${delete[@]}"; do
    for i in "${!others[@]}"; do
      if [[ ${others[i]} = $target ]]; then
        unset 'others[i]'
        env_found=1
      fi
    done
  done

  # glue our parts back together and write to stdout
  left="${parts[0]}:$(printf '%*s' $((process_type_max_width - ${#parts[0]} + 1)) '')"

  # if 'env' was present, put it in the right place
  prefix=""
  if [[ $env_found -eq 1 ]]; then
    prefix="env "
  fi

  if [[ ${#sorted_environment_variables} -eq 0 ]]; then
      right="${prefix}${others[@]}"
  else
      right="${prefix}${sorted_environment_variables[@]} ${others[@]}"
  fi

  echo "${left}${right}"
done < <(printf '%s\n' "$lines")
