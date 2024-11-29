#!/bin/bash

# Directory to store logs and reports
LOG_DIR="./monitoring_logs"
mkdir -p "$LOG_DIR"

# Function to check for critical conditions and trigger alerts
function check_critical_conditions {
  # Define alert thresholds
  CRITICAL_MEMORY_THRESHOLD=80  # Memory usage over 80%
  CRITICAL_CPU_THRESHOLD=90     # CPU usage over 90%
  CRITICAL_TEMP_THRESHOLD=80    # Temperature over 80°C
  CRITICAL_DISK_THRESHOLD=90    # Disk usage over 90%

  # Memory Usage Check
MEM_USAGE=$(free | grep Mem | while read _ total used _; do echo "$((100 * used / total))"; done)
  if [ "$MEM_USAGE" -gt "$CRITICAL_MEMORY_THRESHOLD" ]; then
    zenity --error --text="ALERT: High Memory Usage ($MEM_USAGE%)"
  fi

  # CPU Usage Check (using mpstat to check CPU utilization)
CPU_USAGE=$(mpstat 1 1 | grep "Average" | sed 's/.*\s\([0-9.]*\)$/\1/' | while read -r idle; do echo $((100 - idle)); done)
if [ "$CPU_USAGE" -gt "$CRITICAL_CPU_THRESHOLD" ]; then
  zenity --error --text="ALERT: High CPU Usage ($CPU_USAGE%)"
fi

# If you are running on a virtual machine (VM) (which it seems you are based on the output System: VMware, Inc. VMware Virtual Platform), virtual machines typically do not expose hardware sensors such as temperature, fan speed, or voltage, as these resources are abstracted away by the hypervisor.

  # Disk Usage Check
DISK_USAGE=$(df / -h | tail -n 1 | sed -E 's/.* ([0-9]+)%/\1/')
if [ "$DISK_USAGE" -gt "$CRITICAL_DISK_THRESHOLD" ]; then
  zenity --error --text="ALERT: High Disk Usage ($DISK_USAGE%)"
fi
}

# Function: Monitor System Metrics
function monitor_system {
  TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")
  REPORT_DIR="$LOG_DIR/$TIMESTAMP"
  mkdir -p "$REPORT_DIR"  # Create a directory for the specific report

  # CPU Metrics
  echo "=== CPU Metrics ===" > "$REPORT_DIR/cpu_$TIMESTAMP.log"
  mpstat 1 1 >> "$REPORT_DIR/cpu_$TIMESTAMP.log"

  # CPU Temperature (requires lm-sensors)
  echo "=== CPU Temperature ===" >> "$REPORT_DIR/cpu_$TIMESTAMP.log"
  sensors >> "$REPORT_DIR/cpu_$TIMESTAMP.log"

  # GPU Metrics (using lshw for basic information)
  echo "=== GPU Metrics ===" > "$REPORT_DIR/gpu_$TIMESTAMP.log"
  if command -v lshw >/dev/null 2>&1; then
    lshw -C display >> "$REPORT_DIR/gpu_$TIMESTAMP.log"
  else
    echo "lshw not found. GPU metrics skipped." >> "$REPORT_DIR/gpu_$TIMESTAMP.log"
  fi

  # Memory Metrics
  echo "=== Memory Metrics ===" > "$REPORT_DIR/memory_$TIMESTAMP.log"
  free -h >> "$REPORT_DIR/memory_$TIMESTAMP.log"

  # Disk Usage
  echo "=== Disk Usage ===" > "$REPORT_DIR/disk_$TIMESTAMP.log"
  df -h >> "$REPORT_DIR/disk_$TIMESTAMP.log"
  # Disk SMART Status (requires smartctl)
  echo "=== SMART Status ===" >> "$REPORT_DIR/disk_$TIMESTAMP.log"
  smartctl --all /dev/sda >> "$REPORT_DIR/disk_$TIMESTAMP.log" 2>/dev/null

  # Network Statistics
  echo "=== Network Statistics ===" > "$REPORT_DIR/network_$TIMESTAMP.log"
  ifconfig >> "$REPORT_DIR/network_$TIMESTAMP.log"
  ip -s link >> "$REPORT_DIR/network_$TIMESTAMP.log"

  # System Load Metrics
  echo "=== System Load Metrics ===" > "$REPORT_DIR/load_$TIMESTAMP.log"
  uptime >> "$REPORT_DIR/load_$TIMESTAMP.log"

  # Check for critical conditions
  check_critical_conditions

  # Markdown Report
  REPORT_FILE="$REPORT_DIR/report_$TIMESTAMP.md"
  echo "# System Monitoring Report ($TIMESTAMP)" > "$REPORT_FILE"
  for file in $REPORT_DIR/*_$TIMESTAMP.log; do
    SECTION=$(basename "$file" | sed "s/_$TIMESTAMP.log//")
    echo "## $SECTION" >> "$REPORT_FILE"
    cat "$file" >> "$REPORT_FILE"
  done

  # Convert Markdown to HTML (requires pandoc)
  if command -v pandoc >/dev/null 2>&1; then
    pandoc "$REPORT_FILE" -o "${REPORT_FILE%.md}.html"
  else
    echo "Pandoc not installed. HTML report not generated." >> "$LOG_DIR/monitoring.log"
  fi

  zenity --info --text="Monitoring completed. Report saved: $REPORT_FILE"
}

# Function: View Reports
function view_reports {
  if [ ! -d "$LOG_DIR" ]; then
    zenity --error --text="No monitoring reports found. Please run the monitoring script first."
    return
  fi

  REPORT_DIR=$(zenity --file-selection --title="Select a report folder to view" --directory --filename="$LOG_DIR/")

  if [ -n "$REPORT_DIR" ]; then
    REPORT=$(zenity --file-selection --title="Select a report to view" --filename="$REPORT_DIR/")
    if [ -n "$REPORT" ]; then
      zenity --text-info --filename="$REPORT" --title="Report Viewer"
    else
      zenity --info --text="No report selected."
    fi
  else
    zenity --info --text="No folder selected."
  fi
}

# Interactive Dashboard Menu
function interactive_dashboard {
  while true; do
    CHOICE=$(zenity --list --title="System Monitoring Dashboard" \
      --column="Option" --column="Description" \
      "1" "Run System Monitoring" \
      "2" "View Historical Reports" \
      "3" "Exit" \
      --height=600 --width=600)

    case $CHOICE in
      "1") monitor_system ;;
      "2") view_reports ;;
      "3") zenity --info --text="Goodbye!" ; exit ;;
      *) zenity --error --text="Invalid option. Please try again." ;;
    esac
  done
}

# Run Interactive Dashboard
interactive_dashboard
