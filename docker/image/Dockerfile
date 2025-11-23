FROM nvcr.io/nvidia/l4t-jetpack:r36.4.0

#Minimal apt setup
RUN echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/00-docker \
&& echo 'APT::Install-Recommends "0";' >> /etc/apt/apt.conf.d/00-docker

RUN apt-get update && apt-get install -y \
    build-essential cmake git libgl1-mesa-glx libxkbcommon-x11-0 libx11-xcb1 libxcb1 libxcb1-dev libxext6 libxcb-icccm4 libxcb-image0 \
    libxcb-keysyms1 libxcb-render-util0 libxcb-render0 libxcb-shape0 libxcb-shm0 libxcb-sync1 libxcb-util1 libxcb-xfixes0 \
    x11-apps libgl1-mesa-dev libglu1-mesa-dev libicu-dev libpcre2-dev libxcb-cursor-dev bison gperf flex python2 \
    libasound2-dev libcups2-dev libdrm-dev libegl1-mesa-dev libnss3-dev libpci-dev libpulse-dev libudev-dev libxtst-dev \
    gyp ninja-build libssl-dev libxcursor-dev libxcomposite-dev libxdamage-dev libxrandr-dev libfontconfig1-dev libxss-dev \
    libwebp-dev libjsoncpp-dev libopus-dev libminizip-dev libavutil-dev libavformat-dev libavcodec-dev libevent-dev libvpx-dev \
    libsnappy-dev libre2-dev libprotobuf-dev protobuf-compiler wget libdbus-glib-1-dev libgirepository1.0-dev \
    libfontconfig1-dev libfreetype-dev libgtk-3-dev libx11-dev libx11-xcb-dev libxcb-cursor-dev libxcb-glx0-dev \
    libxcb-icccm4-dev libxcb-image0-dev libxcb-keysyms1-dev libxcb-randr0-dev libxcb-render-util0-dev libxcb-shape0-dev \
    libxcb-shm0-dev libxcb-sync-dev libxcb-util-dev libxcb-xfixes0-dev libxcb-xkb-dev libxext-dev libxfixes-dev \
    libxi-dev libxkbcommon-dev libxkbcommon-x11-dev libxrender-dev \
&& rm -rf /var/lib/apt/lists/*


RUN useradd -ms /bin/bash hmi
USER hmi
WORKDIR /home/hmi

RUN git clone https://github.com/abseil/abseil-cpp.git
WORKDIR ./abseil-cpp
RUN mkdir build
WORKDIR ./build

RUN cmake -GNinja ..
RUN ninja
USER root
RUN ninja install
USER hmi
WORKDIR /home/hmi

RUN git clone --recursive --branch v3.21.12 https://github.com/protocolbuffers/protobuf.git
WORKDIR ./protobuf
RUN mkdir build
WORKDIR ./build

RUN cmake -GNinja ..
RUN ninja
USER root
RUN ninja install
USER hmi
WORKDIR /home/hmi

RUN wget https://download.qt.io/archive/qt/6.10/6.10.1/single/qt-everywhere-src-6.10.1.tar.xz
RUN tar xf qt-everywhere-src-6.10.1.tar.xz
RUN rm qt-everywhere-src-6.10.1.tar.xz
WORKDIR ./qt-everywhere-src-6.10.1
RUN ./configure -release 
RUN cmake -GNinja .
RUN ninja
USER root
RUN ninja install
USER hmi
WORKDIR /home/hmi
RUN rm -rf ./qt-everywhere-src-6.10.1
