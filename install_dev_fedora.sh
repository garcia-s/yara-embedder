#!/bin/bash

if ! command -v "flutter" >/dev/null 2>&1; then
    echo 'You need to have flutter installed';
    exit 1;
fi


echo 'Installing dependencies........'

sudo dnf install -y wget \
    zig \
    make \
    wayland-devel \
    libglvnd-devel \
    mesa-libGLU \
    mesa-libGLU-devel \
    mesa-libGL \
    libxkbcommon-devel


# Extract Flutter engine hash

flutter_hash=$(flutter --version --machine | jq -r '.engineContentHash')

curl "https://storage.googleapis.com/flutter_infra_release/flutter/$flutter_hash/linux-x64/linux-x64-embedder.zip" -o  /tmp/linux-x64-embedder.zip

unzip /tmp/linux-x64-embedder.zip -d /tmp

mkdir ./engine
mv /tmp/flutter_embedder.h ./engine
mv /tmp/libflutter_engine.so ./engine




