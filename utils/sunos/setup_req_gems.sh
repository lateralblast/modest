#!/usr/bin/bash

gems=(getopt builder netaddr parseconfig unix-crypt netaddr json fileutils)

for gem in "${gems[@]}"; do
  echo "Installing Gem $gem"
  gem install $gem
done
