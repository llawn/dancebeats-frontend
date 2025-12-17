ARG FLUTTER_VER
ARG FLUTTER_CH=stable

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Flutter SDK environment
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin:$PATH"
ENV PUB_CACHE=/opt/pub-cache

# Install basic system dependencies required for Flutter setup and package management:
# - bash: shell for running scripts
# - curl & wget: download files from the web
# - git: clone Flutter SDK and other repositories
# - ca-certificates: ensure HTTPS connections work
# - gnupg: verify GPG keys (used for adding Google Chrome repository)
# - unzip & zip: extract and create zip archives (used by Flutter SDK and packages)
# - xz-utils: handle .xz compressed files (used in some SDK downloads)
# - libglu1-mesa: OpenGL utility library required for rendering and Flutter desktop builds
RUN apt-get update && apt-get install -y --no-install-recommends\
    bash \
    curl \
    git \
    ca-certificates \
    wget \
    gnupg \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Install Linux build tools required for Flutter desktop
# - clang: C/C++ compiler for building Flutter native code
# - cmake: build system generator for compiling C/C++ projects
# - ninja-build: fast build system used by Flutter
# - pkg-config: manage compile and link flags for libraries
# - libgtk-3-dev: GTK3 development files for building Linux desktop apps
# - libstdc++-12-dev: standard C++ library headers
# - mesa-utils: OpenGL utilities, required for rendering and testing graphics
RUN apt-get update && apt-get install -y --no-install-recommends\
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    libstdc++-12-dev \
    mesa-utils \
    && rm -rf /var/lib/apt/lists/*

# Install Google Chrome
# - wget & gnupg: download and verify Google signing key
# - Add Google Chrome repository and install google-chrome-stable
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /usr/share/keyrings/google-linux-signing-key.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-linux-signing-key.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
    > /etc/apt/sources.list.d/google-chrome.list

RUN apt-get update && apt-get install -y --no-install-recommends google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
# 1. Create non-root user for Flutter
RUN useradd -m flutter \
    && mkdir -p $FLUTTER_HOME \
    && mkdir -p $PUB_CACHE \
    && chown -R flutter:flutter $FLUTTER_HOME $PUB_CACHE

# 2. Switch to non-root user
USER flutter

# 3. Install Flutter and pin version
RUN git clone https://github.com/flutter/flutter.git $FLUTTER_HOME
RUN cd $FLUTTER_HOME \
    && git remote set-url origin https://github.com/flutter/flutter.git
RUN cd $FLUTTER_HOME \
    && flutter channel ${FLUTTER_CH} --disable-analytics
RUN cd $FLUTTER_HOME \
    && git checkout ${FLUTTER_VER}
RUN cd $FLUTTER_HOME \
    && flutter config --no-analytics
RUN cd $FLUTTER_HOME \
    && flutter precache --linux --web
RUN cd $FLUTTER_HOME \
    && flutter doctor

USER root
RUN git config --global --add safe.directory /opt/flutter

# Set working directory inside container
WORKDIR /workspace

# Default command
CMD ["bash"]