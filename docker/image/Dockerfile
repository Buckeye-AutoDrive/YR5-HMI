# Qt 6.10.1 + Multimedia + xcb + Location/Positioning/Charts/Graphs on Jetson
FROM nvcr.io/nvidia/l4t-jetpack:r36.4.0

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# Make apt a bit leaner
RUN echo 'APT::Install-Suggests "0";'  >> /etc/apt/apt.conf.d/00-docker && \
    echo 'APT::Install-Recommends "0";' >> /etc/apt/apt.conf.d/00-docker

# -------------------------------------------------------------------
# System / build deps: X11, xcb, GL, GStreamer, FFmpeg, audio, etc.
# -------------------------------------------------------------------
RUN apt-get update && apt-get install -y \
    build-essential cmake ninja-build g++ git wget pkg-config \
    # --- GL / EGL / X11 base ---
    libgl1-mesa-glx \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libegl1-mesa-dev \
    libdrm-dev \
    libx11-dev \
    libx11-xcb-dev \
    libxext-dev \
    libxfixes-dev \
    libxi-dev \
    libxrender-dev \
    libxcursor-dev \
    libxcomposite-dev \
    libxdamage-dev \
    libxrandr-dev \
    libxss-dev \
    # --- XCB stack ---
    libxcb1 \
    libxcb1-dev \
    libxcb-render0 \
    libxcb-render0-dev \
    libxcb-render-util0 \
    libxcb-render-util0-dev \
    libxcb-shm0 \
    libxcb-shm0-dev \
    libxcb-icccm4 \
    libxcb-icccm4-dev \
    libxcb-image0 \
    libxcb-image0-dev \
    libxcb-keysyms1 \
    libxcb-keysyms1-dev \
    libxcb-xfixes0 \
    libxcb-xfixes0-dev \
    libxcb-shape0 \
    libxcb-shape0-dev \
    libxcb-sync1 \
    libxcb-sync-dev \
    libxcb-util1 \
    libxcb-util-dev \
    libxcb-xkb1 \
    libxcb-xkb-dev \
    libxcb-randr0 \
    libxcb-randr0-dev \
    libxcb-glx0 \
    libxcb-glx0-dev \
    libxcb-xinput0 \
    libxcb-cursor0 \
    libxcb-cursor-dev \
    libxcb-dri3-0 \
    libxcb-dri3-dev \
    libxkbfile1 \
    libxkbfile-dev \
    libxshmfence1 \
    libxshmfence-dev \
    # --- input / keyboard / fonts ---
    libxkbcommon-dev \
    libxkbcommon-x11-dev \
    libinput-dev \
    libmtdev-dev \
    libfontconfig1-dev \
    libfreetype-dev \
    # --- ICU / PCRE2 etc ---
    libicu-dev \
    libpcre2-dev \
    # --- Location / Charts / Graphs deps ---
    libproj-dev \
    libgeos-dev \
    libgeos++-dev \
    libglib2.0-dev \
    libglm-dev \
    # --- GStreamer (for QtMultimedia GStreamer backend) ---
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libgstreamer-plugins-bad1.0-dev \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    gstreamer1.0-tools \
    gstreamer1.0-plugins-base-apps \
    # --- FFmpeg (for QtMultimedia FFmpeg backend) ---
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libswscale-dev \
    libswresample-dev \
    # --- Audio / misc ---
    libasound2-dev \
    libpulse-dev \
    libcups2-dev \
    libdbus-1-dev \
    libnss3-dev \
    libpci-dev \
    libudev-dev \
    libxtst-dev \
    libssl-dev \
    libjsoncpp-dev \
    libopus-dev \
    libminizip-dev \
    libevent-dev \
    libvpx-dev \
    libsnappy-dev \
    libre2-dev \
    libwebp-dev \
    # --- Protobuf base (we still build our own) ---
    libprotobuf-dev \
    protobuf-compiler \
    # --- tools used by Qt build ---
    bison \
    flex \
    gperf \
    python2 \
 && rm -rf /var/lib/apt/lists/*

# -------------------------------------------------------------------
# Non-root build user
# -------------------------------------------------------------------
RUN useradd -ms /bin/bash hmi
USER hmi
WORKDIR /home/hmi

# -------------------------------------------------------------------
# Abseil
# -------------------------------------------------------------------
RUN git clone --depth 1 https://github.com/abseil/abseil-cpp.git && \
    cmake -S abseil-cpp -B abseil-cpp/build -GNinja -DCMAKE_BUILD_TYPE=Release && \
    ninja -C abseil-cpp/build

USER root
RUN ninja -C /home/hmi/abseil-cpp/build install && \
    rm -rf /home/hmi/abseil-cpp
USER hmi
WORKDIR /home/hmi

# -------------------------------------------------------------------
# Protobuf v3.21.12
# -------------------------------------------------------------------
RUN wget -O protobuf.tar.gz \
        https://github.com/protocolbuffers/protobuf/archive/refs/tags/v3.21.12.tar.gz && \
    mkdir protobuf && \
    tar -xzf protobuf.tar.gz -C protobuf --strip-components=1 && \
    rm protobuf.tar.gz && \
    cmake -S protobuf -B protobuf/build -GNinja \
          -DCMAKE_BUILD_TYPE=Release \
          -Dprotobuf_BUILD_TESTS=OFF && \
    ninja -C protobuf/build

USER root
RUN ninja -C /home/hmi/protobuf/build install && ldconfig && \
    rm -rf /home/hmi/protobuf
USER hmi
WORKDIR /home/hmi

# -------------------------------------------------------------------
# Qt 6.10.1 (with Multimedia + xcb, Location/Positioning/Charts/Graphs, no WebEngine)
# -------------------------------------------------------------------
RUN wget -O qt-everywhere-src-6.10.1.tar.xz \
        https://download.qt.io/archive/qt/6.10/6.10.1/single/qt-everywhere-src-6.10.1.tar.xz && \
    tar xf qt-everywhere-src-6.10.1.tar.xz && \
    rm qt-everywhere-src-6.10.1.tar.xz

WORKDIR /home/hmi/qt-everywhere-src-6.10.1

RUN ./configure \
      -prefix /usr/local/Qt-6.10.1 \
      -release \
      -opensource \
      -confirm-license \
      -nomake tests \
      -nomake examples \
      -skip qtwebengine \
      -qt-doubleconversion \
      -qt-pcre \
      -system-zlib \
      -glib \
      -icu \
      -openssl-runtime \
      -opengl desktop \
      -xcb \
      -xcb-xlib \
      -qpa xcb \
      -gstreamer \
      -pulseaudio \
      -- \
      -DFEATURE_ffmpeg=ON \
      -DFEATURE_gstreamer=ON \
      -DCMAKE_BUILD_TYPE=Release && \
    cmake --build . --parallel

USER root
RUN cmake --install . && \
    echo "/usr/local/Qt-6.10.1/lib" > /etc/ld.so.conf.d/qt6.conf && \
    ldconfig && \
    rm -rf /home/hmi/qt-everywhere-src-6.10.1

USER hmi
WORKDIR /home/hmi

ENV PATH="/usr/local/Qt-6.10.1/bin:${PATH}"
ENV CMAKE_PREFIX_PATH="/usr/local/Qt-6.10.1/lib/cmake"
ENV QT_QPA_PLATFORM=xcb
