#!/bin/bash

# Function to process .env file into variables
process_env() {
  while IFS= read -r line; do
    if [[ $line =~ ^([^=]+)=(.*)$ ]]; then
      env____confirmed=1
      env____key="${BASH_REMATCH[1]}"
      env____value="${BASH_REMATCH[2]}"
      eval "env_$env____key=$env____value"
    fi
  done < $ci_dir/.env

  if [ -z $env____confirmed ] && [ -z $env____empty ]; then
    $env____empty = 1
    echo >> $ci_dir/.env
    process_env
  fi
}

# Function to process project specific .env file into variables
process_project_env() {
  while IFS= read -r line; do
    if [[ $line =~ ^([^=]+)=(.*)$ ]]; then
      env____key="${BASH_REMATCH[1]}"
      env____value="${BASH_REMATCH[2]}"
      eval "env_$env____key=$env____value"
    fi
  done < "$1"
}

# Function to retrieve the value of an environment variable
getenv() {
  local var_name="env_$1"
  echo "${!var_name}"
}


# Process the .env file into variables
process_env

# Process project .env file into variables
# process_project_env $1

# echo $(getenv "CI_PATH")