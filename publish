#!/bin/bash
if [ -z "$VERSION"]; then 
    echo "You cannot use this script alone"
    exit 0
fi


php_script_file="temp.php"
archive_file="../.ci/releases/$app_version.tar.gz"
client_ip=$(getenv "PRODUCTION_IP")
server_port=8801

# Generate the release candidate



# Make sure to be in the right folder
cd $app_path

# Archive the folder content, minding the instructions in .deployignore
tar --exclude-ignore=../.ci/.deployignore v$app_version.tar.gz . > $ci_app_version_logs_path/tar_generate.log 2>& 1
rc=$?
check_error "Archive release code"

# Generate PHP script
cat > "$php_script_file" <<EOF
<?php
\$client_ip = \$_SERVER['REMOTE_ADDR'];

// Check if client IP matches
if (\$client_ip === "$client_ip") {
  // Send file as response
  \$file_path = "$archive_file";
  
  // Check if file exists
  if (file_exists(\$file_path)) {
    // Set appropriate headers
    header("Content-Type: application/octet-stream");
    header("Content-Disposition: attachment; filename=\"" . basename(\$file_path) . "\"");
    header("Content-Length: " . filesize(\$file_path));
  
    // Read and output the file content
    readfile(\$file_path);
    // Execute shell command to get the process IDs of the processes containing "php -S" followed by the port
    exec("pgrep -f 'php -S.*:$server_port'", \$processIDs);

    // Kill the processes
    foreach (\$processIDs as \$pid) {
        // Use the appropriate signal to terminate the process gracefully (or forcefully if needed)
        posix_kill(\$pid, SIGTERM);
    }

    echo "$app_name v$app_version published successfully, connection closed.";
    exit;
  } else {
    // File not found
    http_response_code(404);
    echo "File not found.";
    exit;
  }
} else {
  // IP mismatch
  http_response_code(403);
  echo "Access forbidden.";
  exit;
}
?>
EOF

# Start PHP development server in the background
php -S "localhost:$server_port" "$php_script_file" >/dev/null 2>&1 &
server_pid=$!

# Wait for a client to connect
log_echo "Waiting for connection at http://localhost:$server_port"
