#!/bin/bash

arg1=$1
arg2=$2
arg3=$3
arg4=$4

# Read and parse environment file
source env.sh

create_new_project() {
    if [ -z $arg2 ]; then
        read -p "Enter project name: " project_alias
        read -p "Enter path to .env file or press enter to skip: " env_file
        read -p "Enter path to .deployignore or press enter to use default value (.deployignore): " deploy_ignore
    else
        project_alias=$arg2
        env_file=$arg3
        deploy_ignore=${arg4:-".deployignore"}
    fi

    # Define paths
    ci_path=$(getenv "CI_PATH")
    ci_logs_path="$ci_path/logs"
    ci_project_path="$ci_path/$project_alias"
    ci_project_logs_path="$ci_path/$project_alias/logs"
    ci_project_releases_path="$ci_path/$project_alias/releases"
    ci_project_changelogs_path="$ci_path/$project_alias/changelogs"
    ci_project_installers_path="$ci_path/$project_alias/installers"

    log_file="$ci_logs_path/$(date '+%Y-%m-%d').log"


    # Create needed folders
    mkdir -p $ci_logs_path
    mkdir -p $ci_project_path
    mkdir -p $ci_project_logs_path
    mkdir -p $ci_project_releases_path
    mkdir -p $ci_project_changelogs_path
    mkdir -p $ci_project_installers_path


    # project_alias=$1
    # env_file=$2
    # deploy_ignore=${3:-".deployignore"}
    mkdir "$ci_path/$project_alias"

    # Create or copy config files for the project
    if ! [ -f $env_file ]; then
        touch "$ci_path/$project_alias/.env"
    else
        cp $env_file "$ci_path/$project_alias/.env"
    fi
    
    if ! [ -f $deploy_ignore ]; then
        touch "$ci_path/$project_alias/.deployignore"
    else
        cp $deploy_ignore "$ci_path/$project_alias/.deployignore"
    fi
    
    touch "$ci_path/$project_alias/deploy.json"
    
}

publish() {
    project_alias=$arg2
    deploy_type=$arg3
    push_to_prod=$arg4
    source $ci_path/publisher.sh
}


# Check input and act accordingly

if [ -z $arg1 ]; then
    # Print help message
    echo "CI v0.0.1"
    echo "Usage: ci [init [project_name, path_to_env, path_to_deployignore], publish [project_alias, deploy_type, push_to_prod]]"
    echo "Arguments to init or publish are optional, they will be asked if not provided."
    echo "Examples:"
    echo "    ci init "
    echo "    ci publish "
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
