# OS_Project_12th

# Monitoring Project

This project delivers a comprehensive system monitoring solution using a Zenity-based graphical user interface (GUI), designed for ease of use and adaptability. It enables users to monitor system performance, hardware health, and generate detailed reports with a user-friendly dashboard. To ensure portability and compatibility across various platforms, the project is fully containerized with Docker, simplifying deployment and usage on diverse operating systems and hardware configurations.
## Features
- Monitor system performance and generate reports.
- Interactive GUI using Zenity.
- Fully containerized for compatibility with any OS or hardware.

## Requirements
- **Operating System**: The host machine should have Docker installed and, optionally, Docker Compose for orchestration.

### Installed Software and Tools (for non-Docker setups)
If you plan to run the project outside of Docker, ensure the following packages are installed:

```bash
sudo apt-get install sysstat lm-sensors smartmontools zenity pandoc
