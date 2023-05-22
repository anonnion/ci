#!/bin/bash

arg1=$1
arg2=$2
arg3=$3
arg4=$4
arg5=$5

#Get current dir
$dir=$(pwd)
# Get the directory containing the script
ci_dir=$(dirname "$(readlink -f "$0")")
echo "Using OpenCide installed in $ci_dir"
# Read and parse environment file
source $ci_dir/env.sh

path=$(getenv "CI_PATH")
ci_path="$path/projects"


create_new_project() {
    if [ -z $arg2 ]; then

        valid_input=false

        while ! $valid_input; do
            read -p "Enter project name: " project_name

            # Remove leading and trailing whitespace from project_name
            project_name=$(echo "$project_name" | xargs)

            # Check if project_name contains at least one alphanumeric character
            if [[ "$project_name" =~ [[:alnum:]] ]]; then
                # Check if project_name contains only alphanumeric characters and whitespace
                if [[ "$project_name" =~ ^[[:alnum:][:space:]]+$ ]]; then
                    valid_input=true
                else
                    echo "Project name should only contain alphanumeric characters and whitespace."
                fi
            else
                echo "Project name should contain at least one alphanumeric character."
            fi
        done


        valid_input=false

        while ! $valid_input; do
            read -p "Enter project alias: " project_alias

            # Check if project_alias contains at least one alphanumeric character
            if [[ "$project_alias" =~ [[:alnum:]] ]]; then
                # Check if project_alias contains only alphanumeric characters
                if [[ "$project_alias" =~ ^[[:alnum:]]+$ ]]; then
                    valid_input=true
                else
                    echo "Project alias should only contain alphanumeric characters."
                fi
            else
                echo "Project alias should contain at least one alphanumeric character."
            fi
        done
        
        read -p "Enter path to .env file or press enter to skip: " env_file
        read -p "Enter path to .deployignore or press enter to use default value (.deployignore): " deploy_ignore
    else
        project_alias=$arg2
        project_name=$arg3
        env_file=$arg4
        deploy_ignore=${arg5:-".deployignore"}
    fi

    # Define paths
    ci_logs_path="$path/logs"
    ci_project_path="$ci_path/$project_alias"
    ci_project_logs_path="$ci_path/$project_alias/logs"
    ci_project_releases_path="$ci_path/$project_alias/releases"
    ci_project_changelogs_path="$ci_path/$project_alias/changelogs"
    ci_project_installers_path="$ci_path/$project_alias/installers"

    log_file="$ci_logs_path/$(date '+%Y-%m-%d').log"


    # Create needed folders
    mkdir -p $ci_path
    mkdir -p $ci_logs_path
    mkdir -p $ci_project_path
    mkdir -p $ci_project_logs_path
    mkdir -p $ci_project_releases_path
    mkdir -p $ci_project_changelogs_path
    mkdir -p $ci_project_installers_path


    # project_alias=$1
    # env_file=$2
    # deploy_ignore=${3:-".deployignore"}

    # Create or copy config files for the project
    if [ ! -f "$env_file" ]; then
        touch "$ci_path/$project_alias/.env"
        echo "PROJECT_NAME=\"$project_name\"" > "$env_file"
        echo "PRODUCTION_IP=\"x.x.x.x\"" >> "$env_file"
        echo "PROJECT_PATH=\"$dir\"" >> "$env_file"
        echo "GIT_REMOTE_URL=\"\"" >> "$env_file"
        echo "GIT_MAIN_BRANCH=\"\"" >> "$env_file"
        echo "GIT_PUSH=false" >> "$env_file"
        echo "Environment file installed at $env_file."
    else
        cp "$env_file" "$ci_path/$project_alias/.env"
    fi
    
    if [ ! -f "$deploy_ignore" ]; then
        touch "$ci_path/$project_alias/.deployignore"
    else
        cp "$deploy_ignore" "$ci_path/$project_alias/.deployignore"
    fi
    
    cat > "$ci_path/$project_alias/deploy.json" <<EOF
{
  "name": "$project_name",
  "version": "0.0.0",
  "path": "$(pwd)",
  "changelog": ""
}
EOF
    echo "~~~  Project $project_name created successfully  ~~~"
}

publish() {
    project_alias=$arg2
    deploy_type=$arg3
    push_to_prod=$arg4
    source "$path/publisher.sh"
}


# Check input and act accordingly

if [ -z $arg1 ] || [ "$arg1" == "help" ]; then
    # Print help message
    echo "CI v0.0.1"
    echo "Usage: ci [init [project_name, path_to_env, path_to_deployignore], publish [project_alias, deploy_type, push_to_prod]]"
    echo "Arguments to init or publish are optional, they will be asked if not provided."
    echo "Examples:"
    echo "    ci init  - create a new project"
    echo "    ci publish  - publish a project to a defined server"
    echo "    ci init \"Demo App\" /path/to/.env /path/to/.deployignore"
    echo "    ci publish \"Demo App\" major push"
    echo "    ci publish \"Demo App\" minor push"
    echo "    ci publish \"Demo App\" patch push"
fi


if [ "$arg1" == "init" ]; then
    create_new_project
fi

if [ "$arg1" == "publish" ]; then
    publish
fi
