FROM ubuntu:22.04

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    gcc-arm-none-eabi \
    binutils-arm-none-eabi \
    pkg-config \
    libpng-dev \
    python3 \
    file \
    && rm -rf /var/lib/apt/lists/*

# Copy repository from host
COPY . /workspace

# Set working directory
WORKDIR /workspace

# Default command - can be overridden
CMD ["/bin/bash"]
