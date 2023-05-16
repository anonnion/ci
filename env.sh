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

# Function to process app specific .env file into variables
process_app_env() {
  while IFS= read -r line; do
    if [[ $line =~ ^([^=]+)=(.*)$ ]]; then
      key="${BASH_REMATCH[1]}"
      value="${BASH_REMATCH[2]}"
      eval "env_$key=$value"
    fi
  done < ".$1.env"
}

# Function to retrieve the value of an environment variable
getenv() {
  local var_name="env_$1"
  echo "${!var_name}"
}


# Process the .env file into variables
process_env

# Process app .env file into variables
# process_app_env $1

# echo $(getenv $2)