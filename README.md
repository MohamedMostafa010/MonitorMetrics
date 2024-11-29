# OS 12th Project

# System Monitoring Project 

This project delivers a comprehensive system monitoring solution using a Zenity-based graphical user interface (GUI), designed for ease of use and adaptability. It enables users to monitor system performance, hardware health, and generate detailed reports with a user-friendly dashboard. To ensure portability and compatibility across various platforms, the project is fully containerized with Docker, simplifying deployment and usage on diverse operating systems and hardware configurations.

## Features
- Real-time monitoring of CPU, memory, disk, and network metrics.
- Alerts for critical conditions like high CPU/memory usage or low disk space.
- User-friendly GUI powered by Zenity for report viewing and system monitoring.
- Generates detailed reports in Markdown and HTML formats.
- Dockerized for portability and reproducibility.

## Requirements

### For Direct Execution (Without Docker)
Ensure the following packages are installed:
- `sysstat`: For CPU and memory metrics.
- `lm-sensors`: For temperature monitoring.
- `smartmontools`: For disk health checks.
- `zenity`: For GUI support.
- `pandoc`: For generating HTML reports.

Install these packages on Debian/Ubuntu-based systems with:
```bash
sudo apt-get update
sudo apt-get install sysstat lm-sensors smartmontools zenity pandoc
```

### For Docker Execution
- Visit **https://www.docker.com/** to build and run containers.
- Docker Compose (optional, for orchestration).

## Installation and Setup

### Running Locally (Without Docker)

1- Clone the repository:
```bash
git clone https://github.com/yourusername/system-monitoring.git
cd system-monitoring
```
2- Make the script executable:
```bash
chmod +x monitor.sh
```
3- Run the script:
```bash
./monitor.sh
```

### Running with Docker
1- Build the Docker image:
```bash
docker build -t system-monitor .
```
2- Run the container:
```bash
docker run --rm -it --name system_monitor system-monitor
```
3- Running with Docker Compose
- Start the service:
```bash
docker-compose up
```
- Stop the service:
```bash
docker-compose down
```

## How to Use

### Launch the Dashboard
- The script opens a Zenity-based GUI with three options:
**1- Run System Monitoring: Collects metrics and generates a report.
2- View Historical Reports: Browse and view saved reports.
3- Exit: Closes the application.**

- View Alerts:
**Real-time alerts for critical conditions are displayed as Zenity notifications.**

- View Reports:
**Reports are saved in the monitoring_logs directory. Select a report through the GUI to view details.**
