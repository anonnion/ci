#!/bin/bash

arg1=$1
arg2=$2
arg3=$3
arg4=$4
arg5=$5

#Get current dir
dir=$(pwd)
# Get the directory containing the script
ci_dir=$(dirname "$(readlink -f "$0")")
echo "Using OpenCide installed in $ci_dir"
echo
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
            # Check if a project with the alias already exists
            if [ -d "$ci_path/$project_alias" ]; then
                echo "A project already exists with this alias"
                read -p "Do you want to overwrite $project_alias? [Enter y/n]: " yesorno
                if [[ "$yesorno" == "y" ]]; then
                    valid_input=true
                else
                    valid_input=false
                    echo "Please use another alias for your new project"
                    continue
                fi
            fi
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
    echo $project_alias > "$dir/.ci"
    # Create or copy config files for the project
    if [ ! -f "$env_file" ]; then
        env_file="$ci_path/$project_alias/.env"
        touch $env_file
        echo "PROJECT_NAME=\"$project_name\"" > "$env_file"
        echo "PRODUCTION_IP=\"x.x.x.x\"" >> "$env_file"
        echo "PROJECT_PATH=\"$dir\"" >> "$env_file"
        echo "GIT_REMOTE_URL=\"\"" >> "$env_file"
        echo "GIT_MAIN_BRANCH=\"\"" >> "$env_file"
        echo "GIT_PUSH=false" >> "$env_file"
        echo "Environment file installed at $env_file"
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

get_alias() {
    if [ -f "$dir/.ci" ]; then
        echo "Current Project alias: $(<"$dir/.ci")"
    else
        echo "No OpenCide project found in the current directory"
    fi
}

# Check input and act accordingly

if [ -z $arg1 ] || [ "$arg1" == "help" ]; then
    # Print help message
    echo "CI v0.0.1"
    get_alias
    echo "Usage: ci [init [project_name, path_to_env, path_to_deployignore], publish [project_alias, deploy_type, push_to_prod]]"
    echo "Arguments to init is optional, they will be asked if not provided."
    echo "Examples:"
    echo "    ci init  - create a new project"
    echo "    ci publish  - publish a project to a defined server"
    echo "Examples of arguments to ci init"
    echo "    ci init PROJECT_ALIAS /path/to/.env /path/to/.deployignore"
    echo "Other functions of ci publish: "
    echo "    ci publish PROJECT_NAME DEPLOY_TYPE create-changelog  - creates a PROJECT_VERSION.md file in the project's root directory, which will be added to your deploy log."
    echo "    ci publish PROJECT_NAME DEPLOY_TYPE create-installer - creates an installer: PROJECT_VERSION.sh file in the project's root directory, which will run after the production server has fetched the published version."
    echo "Further publish examples of ci publish: "
    echo "    ci publish PROJECT_ALIAS major PUSH_OR_STORE_OR_GIT"
    echo "    ci publish PROJECT_ALIAS minor PUSH_OR_STORE_OR_GIT"
    echo "    ci publish PROJECT_ALIAS patch PUSH_OR_STORE_OR_GIT"
    echo "Where: "
    echo "    DEPLOY_TYPE can be either major, minor or patch"
    echo "    PROJECT_ALIAS is the alias supplied to ci init"
    echo "and: "
    echo "    PUSH_OR_STORE_OR_GIT can be either \`push\` or \`store\` or \`git\`"
    echo "    store: creates the release file only."
    echo "    git: creates the release file and push to git release branch."
    echo "    push: creates the release file, pushes to git, and also creates a one-time, IP restricted access to download the release file. See the .env file of your project to configure access to the release file." 
    echo "    "
    echo "    Note that the one-time server may not work on your local environment."
fi


if [ "$arg1" == "init" ]; then
    create_new_project
fi

if [ "$arg1" == "publish" ]; then
    publish
fi

if [ "$arg1" == "alias" ]; then
    get_alias
fi
