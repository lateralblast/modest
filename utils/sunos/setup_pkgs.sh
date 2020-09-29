#!/usr/bin/bash

packages=(ruby instaladm gcc lftp imagemagick pkg-config)

for package in "${packages[@]}"; do
  echo "Installing Package $package"
  pkg install $package
done
