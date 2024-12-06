# Use Debian as the base image
FROM debian:latest

# Set environment variables to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update the system and install necessary tools, including a browser
RUN apt-get update && apt-get install -y \
    sysstat \
    lm-sensors \
    smartmontools \
    zenity \
    pandoc \
    curl \
    net-tools \
    iproute2 \
    x11-utils \
    lshw \
    xdg-utils \
    chromium \
    dbus-x11 \
    && rm -rf /var/lib/apt/lists/*  # Clean up the apt cache to reduce image size

# Copy the monitoring script into the container
COPY monitor.sh /usr/local/bin/monitor.sh

# Make the script executable
RUN chmod +x /usr/local/bin/monitor.sh

# Set working directory (optional, depending on your structure)
WORKDIR /app

# Set the default command to execute the monitoring script
CMD ["/usr/local/bin/monitor.sh"]
