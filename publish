#!/bin/bash
if [ -z "$VERSION" ]; then 
    echo "You cannot use this script alone"
    exit 0
fi


php_script_file="$ci_project_path/temp.php"
archive_file="$ci_project_releases_path/$project_version.tar.gz"
client_ip=$(getenv "PRODUCTION_IP")
server_port=8801

# Generate PHP script
cat > "$php_script_file" <<EOF
<?php
\$client_ip = \$_SERVER['REMOTE_ADDR'];

// Check if client IP matches
if (\$client_ip === "$client_ip") {
  // Send file as response
  // Check if the current request is for getting latest project version
  if(strstr(\$_SERVER['REQUEST_URI'], '/latest')) {
    die("$project_version");
  }
  if(strstr(\$_SERVER['REQUEST_URI'], '.tar.gz')) {
  \$file_path = "$ci_project_releases_path/\$_SERVER[REQUEST_URI]";

  }
  else {
    \$file_path = "$archive_file";
  }
  
  // Check if file exists
  if (file_exists(\$file_path)) {
    // Set projectropriate headers
    header("Content-Type: projectlication/octet-stream");
    header("Content-Disposition: attachment; filename=\"" . basename(\$file_path) . "\"");
    header("Content-Length: " . filesize(\$file_path));
  
    // Read and output the file content
    readfile(\$file_path);
    // Execute shell command to get the process IDs of the processes containing "php -S" followed by the port
    exec("pgrep -f 'php -S.*:$server_port'", \$processIDs);

    // Kill the processes
    foreach (\$processIDs as \$pid) {
        // Use the projectropriate signal to terminate the process gracefully (or forcefully if needed)
        posix_kill(\$pid, SIGTERM);
    }

    echo "$project_name v$project_version published successfully, connection closed.";
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
function is_port_available() {
    local port=$1
    timeout 1 bash -c "echo >/dev/tcp/localhost/$port" >/dev/null 2>&1
    return $?
}

function wait_for_port() {
    local port=$1
    local n=$2
    local retries=$3
    local count=0
    while is_port_available "$port"; do
        echo "Waiting..."
        if [ "$retries" -gt 0 ]; then
            count=$((count+1))
            echo "Port $server_port is still in use. Waiting for $wait_time seconds at retry #$count..."
            sleep "$n"
        fi
        retries=$((retries - 1))
    done
    log_echo "Waited for $(($count*5)) seconds before port $server_port became available."
}

wait_time=5
if ! is_port_available "$server_port"; then
    echo "Port $server_port is available."
    # Wait for a client to connect
    log_echo "Waiting for connection at http://localhost:$server_port"
    # Start PHP development server in the background
    php -S "localhost:$server_port" "$php_script_file" >/dev/null 2>&1
    server_pid=$!
else
    echo "Port $server_port is in use. Waiting for $wait_time seconds..."
    wait_for_port "$server_port" "$wait_time" 100
    echo "Port $server_port is now available."
    # Wait for a client to connect
    log_echo "Waiting for connection at http://localhost:$server_port"
    # Start PHP development server in the background
    php -S "localhost:$server_port" "$php_script_file" >/dev/null 2>&1
    server_pid=$!
fi

