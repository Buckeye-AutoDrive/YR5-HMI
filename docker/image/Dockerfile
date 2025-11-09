FROM nvcr.io/nvidia/l4t-jetpack:r36.4.0

#Minimal apt setup
RUN echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/00-docker \
&& echo 'APT::Install-Recommends "0";' >> /etc/apt/apt.conf.d/00-docker

# Add QT binaries
ADD Qt-6.10.0.tar /opt/

RUN apt-get update && apt-get install -y \
build-essential cmake git libgl1-mesa-glx libxkbcommon-x11-0 \
libx11-xcb1 libxcb1 libxext6 libxcb-icccm4 libxcb-image0 \
libxcb-keysyms1 libxcb-render-util0 libxcb-render0 libxcb-shape0 \
libxcb-shm0 libxcb-sync1 libxcb-util1 libxcb-xfixes0 \
x11-apps libgl1-mesa-dev libglu1-mesa-dev libicu-dev libpcre2-dev libxcb-cursor-dev && \
rm -rf /var/lib/apt/lists/*

RUN useradd -ms /bin/bash apprunner
USER apprunner

ENV PATH="/opt/Qt-6.10.0/bin:${PATH}"

WORKDIR /hmi
