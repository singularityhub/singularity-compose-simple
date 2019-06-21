#!/bin/bash

# This script is run in the singularity-compose.yml "post" section to
# create folders on the host. We only should run this once.

if [ ! -d "images/_upload" ]; then
    echo "Creating directories..."
    mkdir -p images/_upload/{0..9}
    echo "Changing permissions for web server to write..."
    chmod 755 -R images
fi
