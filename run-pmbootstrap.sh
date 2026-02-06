#!/bin/bash
# Run pmbootstrap in Docker container interactively
# This script mounts volumes for persistence and runs in privileged mode

docker run -it --rm \
    --privileged \
    -v pmbootstrap-work:/home/pmuser/.local/var/pmbootstrap \
    -v pmbootstrap-config:/home/pmuser/.config \
    -v "$(pwd)/output:/home/pmuser/output" \
    pmbootstrap-builder \
    /bin/bash -c "
    echo '=== PostmarketOS Build Environment ==='
    echo 'pmbootstrap version:' && /home/pmuser/pmbootstrap/pmbootstrap.py --version
    echo ''
    echo 'To initialize: /home/pmuser/pmbootstrap/pmbootstrap.py init'
    echo 'To build:      /home/pmuser/pmbootstrap/pmbootstrap.py install --no-fde'
    echo 'To export:     /home/pmuser/pmbootstrap/pmbootstrap.py export /home/pmuser/output'
    echo ''
    exec /bin/bash
    "
