#!/bin/bash
# Function to process .env file into variables
process_env() {
  if [ ! -f $ci_dir/.env ]; then
    echo "CI_PATH=\"$(pwd)\"" > $ci_dir/.env
    echo >> $ci_dir/.env
  fi
  while IFS= read -r line; do
    if [[ $line =~ ^([^=]+)=(.*)$ ]]; then
      env____confirmed=1
      env____key="${BASH_REMATCH[1]}"
      env____value="${BASH_REMATCH[2]}"
      eval "env_$env____key=$env____value"
    fi
  done < $ci_dir/.env

  if [ ! $env____confirmed ] && [ -z $env____empty ] && [ $env____empty ! 1 ]; then
    $env____empty = 1
    echo >> $ci_dir/.env
    process_env
  fi
}

# Function to process project specific .env file into variables
process_project_env() {
  if [ ! -f "$1" ]; then
    echo "Env file: \`$1\` does not exist"
  else
    while IFS= read -r line; do
      if [[ $line =~ ^([^=]+)=(.*)$ ]]; then
        env____confirmed=1
        env____key="${BASH_REMATCH[1]}"
        env____value="${BASH_REMATCH[2]}"
        eval "env_$env____key=$env____value"
      fi
    done < "$1"


    if [ ! $env____confirmed ] && [ -z $env____empty ] && [ $env____empty ! 1 ]; then
      $env____empty = 1
      echo >> "$1"
      process_env
    fi
  fi
}

# Function to retrieve the value of an environment variable
getenv() {
  local var_name="env_$1"
  echo "${!var_name}"
}


# Process the .env file into variables
process_env

# Process project .env file into variables
process_project_env $1

# echo $(getenv "CI_PATH")