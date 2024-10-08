#!/bin/bash

project_alias=${project_alias:- $1}
deploy_type=${deploy_type:- $2}
push_to_prod=${push_to_prod:- $3}
# Read and parse configuration file
# Prepare environment variables

if [ ! $ci_path ] || [ -z $ci_path ]; then
    # Get the directory containing the script
    ci_dir=$(dirname "$(readlink -f "$0")")

    # Read and parse environment file
    source $ci_dir/env.sh
    path=$(getenv "CI_PATH")
    ci_path="$path/projects"

fi

if [ ! -f "$ci_path/$project_alias/.env" ]; then 
    echo "Project \"$project_alias\" does not exist, use \`ci init\` to create a new project"
    exit 1
fi
process_project_env "$ci_path/$project_alias/.env"
config_file="$ci_path/$project_alias/deploy.json"
if [ ! -f $config_file ]; then
    cat >"$config_file" <<EOF
{
  "name": "App Name",
  "version": "0.0.0",
  "path": "$(pwd)",
  "changelog": ""
}
EOF
fi
project_name=$(jq -r '.name' "$config_file")
project_version=$(jq -r '.version' "$config_file")
project_path=$(jq -r '.path' "$config_file")
changelog=$(jq -r '.changelog' "$config_file")
changelog="${changelog/".git"/}"

cd "$project_path"

# Check if first argument is a command to check for the SemVer code
# of the current version
if [ "$deploy_type" = "current" ]; then
    echo "Current version is $project_version"
    exit 0
fi
# Check if first argument is a command to check for the SemVer code
# of the next version, then swap values if true
if [ "$deploy_type" = "next" ]; then
    action=$deploy_type
    deploy_type=$push_to_prod
fi

# Increment project_version based on deploy_type
case $deploy_type in
major)
    semver=(${project_version//./ })
    ((semver[0]++))
    project_version="${semver[0]}.0.0"
    ;;
minor)
    semver=(${project_version//./ })
    ((semver[1]++))
    project_version="${semver[0]}.${semver[1]}.0"
    ;;
patch)
    semver=(${project_version//./ })
    ((semver[2]++))
    project_version="${semver[0]}.${semver[1]}.${semver[2]}"
    ;;
*)
    echo "Invalid deploy_type. Valid values are major, minor, or patch."
    exit 1
    ;;
esac

# Define paths
ci_logs_path="$path/logs"
ci_project_path="$ci_path/$project_alias"
log_file="$ci_logs_path/$(date '+%Y-%m-%d').log"
ci_project_logs_path="$ci_path/$project_alias/logs"
ci_project_releases_path="$ci_path/$project_alias/releases"
ci_project_changelogs_path="$ci_path/$project_alias/changelogs"
ci_project_installers_path="$ci_path/$project_alias/installers"
ci_project_version_logs_path="$ci_path/$project_alias/logs/$project_version"

# Function to print and log echo statements
log_echo() {
    local message="$1"
    echo "$message"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >>"$log_file"
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
mkdir -p $ci_project_path
mkdir -p $ci_project_logs_path
mkdir -p $ci_project_releases_path
mkdir -p $ci_project_changelogs_path
mkdir -p $ci_project_installers_path
mkdir -p $ci_project_version_logs_path

# Send the value of the next version
if [ "$action" = "next" ]; then
    if [ "$deploy_type" != "patch" ]; then
        deploy_type="$deploy_type update"
    fi
    echo "The next $deploy_type will be named $project_version"
    exit 0
fi

# Check if second argument is a command to create changelog, rather than to publish the code.
# This is useful to both check the next version, and also create the changelog file programmatically.
if [ "$push_to_prod" = "create-changelog" ]; then
    changelog_file="$ci_project_changelogs_path/$project_version.md"
    if [ -f $changelog_file ]; then
        echo "No changes: Changelog for version $project_version already installed at $changelog_file!"
        exit 0
    fi
    touch $changelog_file
    echo "# Changes in v$project_version" > $changelog_file
    echo >> $changelog_file
    echo "## Deployment type: $deploy_type" >> $changelog_file
    echo >> $changelog_file
    echo "### [Added]:" >> $changelog_file
    echo >> $changelog_file
    echo "<ul>" >> $changelog_file
    echo "  <li>No items</li>" >> $changelog_file
    echo "</ul>" >> $changelog_file
    echo >> $changelog_file
    echo "### [Fixed]:" >> $changelog_file
    echo >> $changelog_file
    echo "<ul>" >> $changelog_file
    echo "  <li>No items</li>" >> $changelog_file
    echo "</ul>" >> $changelog_file
    echo >> $changelog_file
    echo "### [Removed]:" >> $changelog_file
    echo >> $changelog_file
    echo "<ul>" >> $changelog_file
    echo "  <li>No items</li>" >> $changelog_file
    echo "</ul>" >> $changelog_file
    echo >> $changelog_file
    echo "### [Notes]:" >> $changelog_file
    echo >> $changelog_file
    echo "<ul>" >> $changelog_file
    echo "  <li>No items</li>" >> $changelog_file
    echo "</ul>" >> $changelog_file
    echo >> $changelog_file
    echo "Changelog for version $project_version installed at $changelog_file successfully!"
    exit 0
fi

# Check if second argument is a command to create installer, rather than to publish the code.
# This is useful to both check the next version, and also create the installer file programmatically.
if [ "$push_to_prod" = "create-installer" ]; then

    touch $project_version.sh && chmod +x $project_version.sh
    echo "Installation file for version $project_version created successfully!"
    exit 0
fi

# Update configuration file with new project_version
jq --arg new_version "$project_version" '.version = $new_version' "$config_file" >temp.json && mv temp.json "$config_file"


push_to_git=$(getenv "GIT_PUSH")
git_remote_url=$(getenv "GIT_REMOTE_URL")
git_main_branch=$(getenv "GIT_MAIN_BRANCH")

# Check if changelog file exists for current version, and add it to the deploy_log
if [ -f "$ci_project_changelogs_path/$project_version.md" ]; then
    cp "$ci_project_changelogs_path/$project_version.md" "$project_path/"
    if [ $push_to_git eq 1 ]; then
        git_remote_changelog="${git_remote_url/".git"/}"
        changelog_url="$git_remote_changelog/tree/$project_version/$project_version.md"
        jq --arg new_changelog "$changelog_url" '.changelog = $new_changelog' "$config_file" >temp.json && mv temp.json "$config_file"
    else
        jq --arg new_changelog "$ci_project_changelogs_path/$project_version.md" '.changelog = $new_changelog' "$config_file" >temp.json && mv temp.json "$config_file"
    fi
fi

# Remove new lines from the configuration file
config_content=$(tr -d '\n' <"$config_file")

# Create deploy_log.json if it doesn't exist
if ! [ -f "$ci_project_logs_path/deploy_log.json" ]; then
    cat >"$ci_project_logs_path/deploy_log.json" <<EOF
[

]
EOF
fi

# append content to the second line of deploy_log.json
log_file="$ci_project_logs_path/deploy_log.json"
tmp_file="$ci_project_logs_path/deploy_log_tmp.json"

# Create a temporary file and append the updated config_content to it
echo "[" >"$tmp_file"
echo "$config_content" >>"$tmp_file"
echo "," >>"$tmp_file"

# append the existing content of deploy_log.json to the temporary file
tail -n +2 "$log_file" >>"$tmp_file"

# Replace deploy_log.json with the temporary file
mv "$tmp_file" "$log_file"

rollback() {
    log_echo "An error occurred. Rolling back changes..."
    git checkout "$git_main_branch"
    git branch -D "$project_version"
    log_echo "Rolled back to $git_main_branch branch."
    exit 1
}

# Make sure to be in the right folder
cd $project_path

# Store the version codebase in a tarball, minding the instructions in .deployignore
touch $ci_project_version_logs_path/tar_generate_error.log

if [ "$push_to_prod" != "git" ]; then
    tar --exclude-ignore="$ci_project_path/.deployignore" -cf "$ci_project_releases_path/v$project_version.tar.gz" . >$ci_project_version_logs_path/tar_generate.log 2>$ci_project_version_logs_path/tar_generate_error.log
    rc=$?
    check_error "Creating release tarball" $(cat $ci_project_version_logs_path/tar_generate_error.log)
fi

# Push to production if push_to_prod is "push"
if [ "$push_to_prod" = "push" ] || [ "$push_to_prod" = "git" ]; then
    #Move previous versions' installer script to the ci directory
    log_echo "Moving former versions' install scripts into .ci directory"
    for file in *.sh; do
        # Check if the file matches the SemVer naming pattern and is not equal to the project version
        if [[ $file =~ ^[0-9]+\.[0-9]+\.[0-9]+\.sh$ ]] && [ "$file" != "$project_version.sh" ]; then
            # Move the file to the .ci directory
            mv "$file" "$ci_project_installers_path/"
            log_echo "Moved $file to $project_alias's installers directory."
        fi
        if [ "$file" = "$project_version.sh" ]; then
            # Copy the file to the .ci directory
            cp "$file" "$ci_project_installers_path/"
            log_echo "Copied $file to $project_alias's installers directory."
        fi
    done

    #Copy current version's installer to the ci directory
    log_echo "All previous installers moved, current version's installer has been copied.."
    log_echo "Creating release branch in current repo"
    

    # Check if $git_push is true
    if [ $push_to_git = 1 ]; then
        if [ -f "$project_path/.gitignore" ]; then
            mv "$project_path/.gitignore" "$project_path/.temp_ignore"
        fi
        cp "$ci_project_path/.deployignore" "$project_path/.gitignore"
        echo "Branching.."
        cd "$project_path"
        # Check if git is already initialized
        if ! [ -d .git ]; then
            git init
        fi

        # Check if $git_remote_url is already added as a remote URL
        if ! git remote get-url "$project_alias" &>/dev/null; then
            git remote add "$project_alias" "$git_remote_url"
        fi

        # Check if git user and email are set
        if ! git config --get user.name &>/dev/null || ! git config --get user.email &>/dev/null; then
            echo "Git user or email is not set. Please configure them using 'git config --global user.name' and 'git config --global user.email'."
            exit 1
        else
            # Perform the git push
            # git push "$project_alias"
            # Create and switch to the new branch
            echo "Creating new release branch: $project_version"
            git checkout -b "$project_version" || rollback
            echo "Adding files"
            git add *
            if [ -f "$project_path/$project_version.md" ]; then
                git add "$project_path/$project_version.md"
            fi
            echo "Committing"
            git commit -m"Release v$project_version"
            echo "Pushing release code to branch $project_version"
            # Push the codebase to the new branch
            git push "$project_alias" -u "$project_version" || rollback

            # Switch back to the main branch
            git checkout "$git_main_branch"

            log_echo "Successfully created and pushed codebase to $project_version branch."
        fi
    if [ -f "$project_path/.temp_ignore" ]; then
        mv "$project_path/.temp_ignore" "$project_path/.gitignore"
    fi
    # rm "$ci_project_path/.deployignore" "$project_path/.gitignore"
    fi
    if [ -f "$project_path/$project_version.md" ]; then
        rm "$project_path/$project_version.md"
    fi
    if [ "$push_to_prod" = "push" ]; then
        log_echo "Pushing to production..."
        VERSION=$project_version
        source "$path/publish.sh"
    else
        log_echo "Pushed to git, skipping production push."
    fi
else
    if [ -f "$project_path/$project_version.md" ]; then
        rm "$project_path/$project_version.md"
    fi
    echo "Cleaning up and skipping production push successful."
fi