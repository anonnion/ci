#!/bin/bash

# Function to process .env file into variables
process_env() {
  while IFS= read -r line; do
    if [[ $line =~ ^([^=]+)=(.*)$ ]]; then
      key="${BASH_REMATCH[1]}"
      value="${BASH_REMATCH[2]}"
      eval "env_$key=$value"
    fi
  done < .env
}

# Function to retrieve the value of an environment variable
getenv() {
  local var_name="env_$1"
  echo "${!var_name}"
}
