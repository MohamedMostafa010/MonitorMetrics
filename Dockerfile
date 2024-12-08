# Use Debian as the base image
FROM debian:latest

# Set environment variables to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Add NVIDIA repository and install CUDA manually
RUN apt-get update && apt-get install -y wget gnupg2 && \
    wget https://developer.download.nvidia.com/compute/cuda/repos/debian11/x86_64/cuda-keyring_1.0-1_all.deb && \
    dpkg -i cuda-keyring_1.0-1_all.deb && \
    apt-get update && apt-get install -y \
    cuda-toolkit-11-8

# Install other necessary packages
RUN apt-get update && apt-get install -y \
    wget \
    liburcu-dev \
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
    mesa-utils \
    && rm -rf /var/lib/apt/lists/*  # Clean up the apt cache to reduce image size

# Copy the monitoring script into the container
COPY monitor.sh /usr/local/bin/monitor.sh

# Copy the CSS file into the container
COPY report.css /usr/local/share/css/report.css

# Make the script executable
RUN chmod +x /usr/local/bin/monitor.sh

# Set working directory (optional, depending on your structure)
WORKDIR /app

# Set the default command to execute the monitoring script
CMD ["/usr/local/bin/monitor.sh"]
