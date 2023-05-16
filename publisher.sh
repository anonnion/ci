#!/bin/bash

deploy_type=$1
push_to_prod=$2
# Read and parse configuration file
config_file=".deploy.conf"
app_name=$(jq -r '.name' "$config_file")
app_version=$(jq -r '.version' "$config_file")
app_path=$(jq -r '.path' "$config_file")

# Source the env_processing.sh script
source env.sh

# Process the .env file into variables
process_env

ci_path=$(getenv "CI_PATH")

cd $app_path


# Check if first argument is a command to check for the SemVer code 
# of the current version
if [ "$deploy_type" = "current" ]; then
    echo "Current version is $app_version"
    exit 0
fi
# Check if first argument is a command to check for the SemVer code 
# of the next version, then swap values if true
if [ "$deploy_type" = "next" ]; then
    action=$deploy_type
    deploy_type=$push_to_prod
fi


# Increment app_version based on deploy_type
case $deploy_type in
    major)
        semver=( ${app_version//./ } )
        ((semver[0]++))
        app_version="${semver[0]}.0.0"
        ;;
    minor)
        semver=( ${app_version//./ } )
        ((semver[1]++))
        app_version="${semver[0]}.${semver[1]}.0"
        ;;
    patch)
        semver=( ${app_version//./ } )
        ((semver[2]++))
        app_version="${semver[0]}.${semver[1]}.${semver[2]}"
        ;;
    *)
        echo "Invalid deploy_type. Valid values are major, minor, or patch."
        exit 1
        ;;
esac


# Define paths
ci_logs_path=../.ci/logs
ci_app_path=../.ci/$app_name
ci_app_logs_path=../.ci/$app_name/logs
ci_app_installers_path=../.ci/$app_name/installers
ci_app_releases_path=../.ci/$app_name/releases
ci_app_version_logs_path=../.ci/$app_name/logs/$app_version
ci_app_changelogs_path=../.ci/$app_name/changelogs
log_file="$ci_logs_path/$(date '+%Y-%m-%d').log"

# Function to print and log echo statements
log_echo() {
  local message="$1"
  echo "$message"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$log_file"
}

# Function to exit on error
check_error() {
    if [ $rc -eq 0 ]; then
        log_echo "!!---! Finished $1 successfully !!---!"
    else
        log_echo "$1 Failed. Return Code: $rc"
        exit 1
    fi
}

# Create needed folders
mkdir -p $ci_logs_path
mkdir -p $ci_app_path
mkdir -p $ci_app_logs_path
mkdir -p $ci_app_installers_path
mkdir -p $ci_app_releases_path
mkdir -p $ci_app_changelogs_path

# Send the value of the next version
if [ "$action" = "next" ]; then
    if [ "$deploy_type" != "patch" ]; then
        deploy_type="$deploy_type update"
    fi
    echo "The next $deploy_type will be named $app_version"
    exit 0
fi

# Check if second argument is a command to create changelog, rather than to publish the code.
# This is useful to both check the next version, and also create the changelog file programmatically.
if [ "$push_to_prod" = "create-changelog" ]; then
    touch $ci_app_changelogs_path/$app_version.md
    echo "Changelog for version $app_version installed at $ci_app_changelogs_path/$app_version.md successfully!"
    exit 0
fi


# Check if second argument is a command to create installer, rather than to publish the code.
# This is useful to both check the next version, and also create the installer file programmatically.
if [ "$push_to_prod" = "create-installer" ]; then

    touch $app_version.sh && chmod +x $app_version.sh
    echo "Installation file for version $app_version created successfully!"
    exit 0
fi


# Update configuration file with new app_version
jq --arg new_version "$app_version" '.version = $new_version' "$config_file" > temp.json && mv temp.json "$config_file"

# Remove new lines from the configuration file
config_content=$(tr -d '\n' < "$config_file")

# Create deploy_log.json if it doesn't exist
if ! [ -f "$ci_app_logs_path/deploy_log.json"]; then
    cat > "$php_script_file" <<EOF
[

]
EOF
fi

# Append content to the second line of deploy_log.json
log_file="$ci_app_logs_path/deploy_log.json"
tmp_file="$ci_app_logs_path/deploy_log_tmp.json"

# Create a temporary file and append the updated config_content to it
echo "[" > "$tmp_file"
echo "$config_content" >> "$tmp_file"
echo "," >> "$tmp_file"

# Append the existing content of deploy_log.json to the temporary file
tail -n +2 "$log_file" >> "$tmp_file"

# Replace deploy_log.json with the temporary file
mv "$tmp_file" "$log_file"


rollback() {
  log_echo "An error occurred. Rolling back changes..."
  git checkout "$main_branch"
  git branch -D "$app_version"
  log_echo "Rolled back to $main_branch branch."
  exit 1
}


# Push to production if push_to_prod is 1
if [ "$push_to_prod" = "push" ]; then
    #Move previous versions' installer script to the ci directory
    log_echo "Moving former versions' install scripts into .ci directory"
    for file in *.sh; do
        # Check if the file matches the SemVer naming pattern and is not equal to the app version
        if [[ $file =~ ^[0-9]+\.[0-9]+\.[0-9]+\.sh$ ]] && [ "$file" != "$app_version.sh" ]; then
            # Move the file to the .ci directory
            mv "$file" "$ci_app_installers_path/"
            log_echo "Moved $file to .ci directory."
        fi
    done
    #Copy current version's installer to the ci directory
    log_echo "All previous installers moved, current version's installer has been copied.."
    log_echo "Creating release branch in current repo"
    # Create and switch to the new branch
    git checkout -b "$app_version" || rollback

    # Push the codebase to the new branch
    git push -u origin "$app_version" || rollback

    # Switch back to the main branch
    git checkout "$main_branch"

    log_echo "Successfully created and pushed codebase to $app_version branch."
    log_echo "Pushing to production..."
    VERSION=$app_version
    source publish.sh
    # Add your deployment commands here
else
    echo "Skipping production push."
fi
