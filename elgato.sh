#!/bin/bash

# MacOS: Query Bonjour for the first Elgato Key Light
function macos_get_elgato_name() {
  # FIFO to interact with dns-sd
  local fifo='/tmp/discover-elgato.fifo'
  rm -f "${fifo}"
  mkfifo "${fifo}"

  # Query Bonjour.
  dns-sd -B _elg._tcp > "${fifo}" &
  local pid="${!}"

  # Find the first light.
  while read line; do
    # Find the light name.
    [[ -z "${line}" ]] && continue
    local hit;
    hit="$(grep '_elg._tcp.' <<< "${line}")" || continue

    awk '{
      out="";
      for(i = 7; i <= NF; i++) {
        out = out ? out" "$i : $i
      };
      print out
    }' <<< "${hit}"
    break
  done < "${fifo}"

  kill "${pid}"
}

# MacOS: Given the name of an Elgato Key Light ($1), produce the host / port
# information for that device.
function macos_get_elgato_host_port() {
  # FIFO to interact with dns-sd
  local fifo='/tmp/discover-elgato.fifo'
  rm -f "${fifo}"
  mkfifo "${fifo}"

  # Query Bonjour.
  dns-sd -L "${1}" _elg._tcp > "${fifo}" &
  local pid="${!}"

  # Find the first light.
  while read line; do
    # Find the light name.
    [[ -z "${line}" ]] && continue
    local hit;
    hit="$(grep 'can be reached at' <<< "${line}")" || continue

    # Extract the information.
    sed -e 's/.* can be reached at \([^ ]*\) .*/\1/g' <<< "${hit}"
    break
  done < "${fifo}"

  kill "${pid}"
}

# Linux: Return information about name / host and post about the first detected
# ELgato Key Light, by way of generating variable assignments (to be evaluated
# by the caller).
function linux_get_elgato_details() {
  # FIFO to interact with avahi-browse.
  local fifo='/tmp/discover-elgato.fifo'
  rm -f "${fifo}"
  mkfifo "${fifo}"

  # Query Bonjour.
  avahi-browse -p --resolve _elg._tcp > "${fifo}" 2>/dev/null &
  local pid="${!}"

  # Find the first light.
  while read line; do
    # Find the light name.
    [[ -z "${line}" ]] && continue
    local hit;
    hit="$(grep '^=;' <<< "${line}")" || continue

    # Output variables and break out.
    awk -F ';' '{
      print "name='"'"'" $4 "'"'"';host_port='"'"'" $7 ":" $9 "'"'"'"
    }' <<< "${line}" | sed -e "s@\\032@ @g"
    break
  done < "${fifo}"

  kill "${pid}"
}

# curl(1) against a given host / port ($1) to interact with the Elgato Key
# Light at that network location. Optionally allows for other parameters ($2+)
# to be passed to curl(1).
function elgato_curl() {
  # Save host / port, allow the rest to go to curl.
  local host_port="${1}"
  shift 1

  # This endpoint always gives values back, format them nicely in a column.
  curl -s "${@}" "http://${host_port}/elgato/lights" \
    | jq -r '.lights[0] | keys[] as $l | "\($l): \(.[$l])"' \
    | column -t
}

# Given a number's current value ($1), the acceptable range ($2 to $3,
# inclusive), and a string to update the current value with ($4), output either
# the replacement value or modify the current value, keeping the result within
# the specified range.
function parse_number_maybe_increment() {
  local current_value="${1}"
  local min="${2}"
  local max="${3}"

  # Check for number.
  ! [[ "${4}" =~ ^[+-]?[0-9]+$ ]] \
    && return 1

  # Handle increments.
  local out="${1}"
  [[ "${4}" =~ ^[+-][0-9]+$ ]] \
    && out="$(($out $4))" \
    || out="$4"

  # Restrain the value.
  out="$(( $out > $max ? $max : $out ))"
  out="$(( $out < $min ? $min : $out ))"
  echo "${out}"
}

# Given text, underline it with "=" on a following line
underline() {
  echo "${1}"
  echo "${1//?/${2:-=}}"
}

# Documentation for usage.
function usage() {
  echo "usage: ${0} <on|off|brightness number|temperature number>"
}

function main() {
  # Get details
  local name
  local host_port

  local uname="$(uname)"
  if [[ "${uname}" =~ ^Darwin ]]; then
    ! name="$(macos_get_elgato_name)" \
      && usage \
      && return 1

    ! host_port="$(macos_get_elgato_host_port "${name}")" \
      && usage \
      && return 1
  else
    ! eval "$(linux_get_elgato_details)" \
      && usage \
      && return 1
  fi

  # Just print current settings if no changes are asked for.
  if [[ "${#}" -eq 0 ]]; then
    underline "${name} (${host_port})"
    elgato_curl "${host_port}"
    return 0
  fi

  # Evals local variables $on, $brightness, and $temperature from current
  # settings.
  eval "$(curl -s "http://${host_port}/elgato/lights" \
      | jq -r '.lights[0] | keys[] as $l | "local \($l)=\(.[$l] | @sh)"')"

  # Override those values
  while [[ "${#}" -gt 0 ]]; do
    case "${1}" in
      on)
        on=1
        ;;
      off)
        on=0
        ;;

      brightness)
        ! brightness="$(parse_number_maybe_increment \
                          "${brightness}" "0" "100" "${2}")" \
          && usage \
          && return 1
        shift 1
        ;;

      temperature)
        ! temperature="$(parse_number_maybe_increment \
                            "${temperature}" "143" "344" "${2}")" \
          && usage \
          && return 1
        shift 1
        ;;

      *)
        usage
        return 1
        ;;
    esac

    shift 1
  done

  underline "${name} (${host_port})"
  elgato_curl "${host_port}" \
    --header 'Content-Type: application/json' \
    --request PUT \
    -d "{\"numberOfLights\":1,\"lights\":[{"`
          `"\"on\":$on,"`
          `"\"brightness\":$brightness,"`
          `"\"temperature\":$temperature"`
        `"}]}"
}

main "${@}"
