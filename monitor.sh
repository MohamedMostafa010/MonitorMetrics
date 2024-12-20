#!/bin/bash

LOG_DIR="/app/monitoring_logs"
mkdir -p "$LOG_DIR"

function check_critical_conditions {
  CRITICAL_MEMORY_THRESHOLD=1  # Memory usage over 1%
  CRITICAL_CPU_THRESHOLD=0     # CPU usage over 0%
  CRITICAL_TEMP_THRESHOLD=80    # Temperature over 80°C
  CRITICAL_DISK_THRESHOLD=1    # Disk usage over 1%

  MEM_USAGE=$(free | awk '/Mem:/ {printf "%.0f", $3/$2 * 100}')
  if [ "$MEM_USAGE" -gt "$CRITICAL_MEMORY_THRESHOLD" ]; then
    zenity --error --text="ALERT: High Memory Usage ($MEM_USAGE%)" &
  fi

  CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')  # User + System CPU usage
  echo "CPU Usage: $CPU_USAGE"
  if echo "$CPU_USAGE >= $CRITICAL_CPU_THRESHOLD" | bc -l | grep -q 1; then
    zenity --error --text="ALERT: High CPU Usage ($CPU_USAGE%)" &
  fi

  DISK_USAGE=$(df / -h | awk 'NR==2 {gsub("%", "", $5); print $5}')
  if [ "$DISK_USAGE" -gt "$CRITICAL_DISK_THRESHOLD" ]; then
    zenity --error --text="ALERT: High Disk Usage ($DISK_USAGE%)" &
  fi

  ################################################################################################ Temperature Check (if sensors is available)
  if command -v sensors >/dev/null 2>&1; then
    TEMP=$(sensors | awk '/^Package id 0:/ {print $4}' | tr -d '+°C')
    if [ "$TEMP" ] && [ "$(echo "$TEMP > $CRITICAL_TEMP_THRESHOLD" | bc -l)" -eq 1 ]; then
      zenity --error --text="ALERT: High Temperature ($TEMP°C)" &
    fi
  fi
  ################################################################################################

  sleep 1
}

function monitor_system {
  TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")
  REPORT_DIR="$LOG_DIR/$TIMESTAMP"
  mkdir -p "$REPORT_DIR"

  echo "=== CPU Metrics ===" > "$REPORT_DIR/cpu_$TIMESTAMP.log"
  mpstat 1 1 >> "$REPORT_DIR/cpu_$TIMESTAMP.log"

  echo "=== CPU Temperature ===" >> "$REPORT_DIR/cpu_$TIMESTAMP.log"
  sensors >> "$REPORT_DIR/cpu_$TIMESTAMP.log"

  echo "=== GPU Metrics ===" > "$REPORT_DIR/gpu_$TIMESTAMP.log"
  if command -v nvidia-smi >/dev/null 2>&1; then
    echo "NVIDIA GPU Detected:" >> "$REPORT_DIR/gpu_$TIMESTAMP.log"
    nvidia-smi --query-gpu=name,temperature.gpu,utilization.gpu,memory.used,memory.total --format=csv >> "$REPORT_DIR/gpu_$TIMESTAMP.log"
  elif command -v rocm-smi >/dev/null 2>&1; then
    echo "AMD GPU Detected:" >> "$REPORT_DIR/gpu_$TIMESTAMP.log"
    rocm-smi >> "$REPORT_DIR/gpu_$TIMESTAMP.log"
  elif command -v lshw >/dev/null 2>&1; then
    echo "Fallback to lshw for GPU info:" >> "$REPORT_DIR/gpu_$TIMESTAMP.log"
    lshw -C display >> "$REPORT_DIR/gpu_$TIMESTAMP.log"
  else
    echo "No GPU monitoring tools found. GPU metrics skipped." >> "$REPORT_DIR/gpu_$TIMESTAMP.log"
  fi

  echo "=== Memory Metrics ===" > "$REPORT_DIR/memory_$TIMESTAMP.log"
  free -h >> "$REPORT_DIR/memory_$TIMESTAMP.log"
  echo "Memory Details:" >> "$REPORT_DIR/memory_$TIMESTAMP.log"
  vmstat -s >> "$REPORT_DIR/memory_$TIMESTAMP.log"

  echo "=== Disk Usage ===" > "$REPORT_DIR/disk_$TIMESTAMP.log"
  df -h >> "$REPORT_DIR/disk_$TIMESTAMP.log"
  echo "Disk Inodes Usage:" >> "$REPORT_DIR/disk_$TIMESTAMP.log"
  df -i >> "$REPORT_DIR/disk_$TIMESTAMP.log"
  echo "=== SMART Status ===" >> "$REPORT_DIR/disk_$TIMESTAMP.log"
  smartctl -T permissive --all /dev/sda >> "$REPORT_DIR/disk_$TIMESTAMP.log" 2>/dev/null

  echo "=== Network Statistics ===" > "$REPORT_DIR/network_$TIMESTAMP.log"
  ifconfig >> "$REPORT_DIR/network_$TIMESTAMP.log"
  ip -s link >> "$REPORT_DIR/network_$TIMESTAMP.log"
  echo "Network Connections:" >> "$REPORT_DIR/network_$TIMESTAMP.log"
  netstat -tuln >> "$REPORT_DIR/network_$TIMESTAMP.log"

  echo "=== System Load Metrics ===" > "$REPORT_DIR/load_$TIMESTAMP.log"
  uptime >> "$REPORT_DIR/load_$TIMESTAMP.log"
  echo "Detailed Load Average:" >> "$REPORT_DIR/load_$TIMESTAMP.log"
  cat /proc/loadavg >> "$REPORT_DIR/load_$TIMESTAMP.log"

  check_critical_conditions

  REPORT_FILE="$REPORT_DIR/report_$TIMESTAMP.md"
  echo "# System Monitoring Report ($TIMESTAMP)" > "$REPORT_FILE"
  for file in "$REPORT_DIR"/*_"$TIMESTAMP".log; do
    SECTION=$(basename "$file" | sed "s/_$TIMESTAMP.log//")
    echo >> "$REPORT_FILE"
    echo "## $SECTION" >> "$REPORT_FILE"
    echo >> "$REPORT_FILE"
    cat "$file" >> "$REPORT_FILE"
  done

  HTML_REPORT="$REPORT_DIR/report_$TIMESTAMP.html"
  cat <<EOF > "$HTML_REPORT"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>System Monitoring Report ($TIMESTAMP)</title>
  <link rel="stylesheet" href="/usr/local/share/css/report.css"> <!-- Update with actual CSS path -->
</head>
<body>
  <header>
    <h1>System Monitoring Report</h1>
    <p>Generated on $TIMESTAMP</p>
  </header>
EOF

  for file in "$REPORT_DIR"/*_"$TIMESTAMP".log; do
    SECTION=$(basename "$file" | sed "s/_$TIMESTAMP.log//")
    echo "<section id=\"$SECTION\">" >> "$HTML_REPORT"
    echo "<h2>${SECTION^}</h2>" >> "$HTML_REPORT"
    echo "<pre>" >> "$HTML_REPORT"
    cat "$file" >> "$HTML_REPORT"
    echo "</pre>" >> "$HTML_REPORT"
    echo "</section>" >> "$HTML_REPORT"
  done

  echo "</body></html>" >> "$HTML_REPORT"

  zenity --info --text="Monitoring completed. Reports saved in $REPORT_DIR"
}

function view_reports {
  if [ ! -d "$LOG_DIR" ]; then
    zenity --error --text="No monitoring reports found. Please run the monitoring script first."
    return
  fi

  SELECTION=$(zenity --file-selection --title="Select a report or folder to view" --filename="$LOG_DIR/")
  if [ -z "$SELECTION" ]; then
    zenity --info --text="No selection made."
    return
  fi

  if [ -d "$SELECTION" ]; then
    REPORT=$(zenity --file-selection --title="Select a report to view" --filename="$SELECTION/")
  elif [ -f "$SELECTION" ]; then
    REPORT="$SELECTION"
  else
    zenity --error --text="Invalid selection. Please select a valid file or folder."
    return
  fi

  if [ -z "$REPORT" ]; then
    zenity --info --text="No report selected."
    return
  fi

  if [ -f "$REPORT" ]; then
    if [[ "$REPORT" == *.html ]]; then
      chromium --no-sandbox --disable-software-rasterizer --disable-gpu "$REPORT" &
    else
      zenity --text-info --filename="$REPORT" --title="Report Viewer"
    fi
  else
    zenity --error --text="The selected file does not exist or is not a valid file."
  fi
}

function interactive_dashboard {
  while true; do
    CHOICE=$(zenity --list --title="System Monitoring Dashboard" \
      --column="Option" --column="Description" \
      "1" "Run System Monitoring" \
      "2" "View Historical Reports" \
      "3" "Exit" \
      --height=400 --width=400)

    case $CHOICE in
      "1") monitor_system ;;
      "2") view_reports ;;
      "3") zenity --info --text="Goodbye!" ; exit ;;
      *) zenity --error --text="Invalid option. Please try again." ;;
    esac
  done
}

interactive_dashboard
