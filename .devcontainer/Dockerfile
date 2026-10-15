# IIC-OSIC-TOOLS image with a named user for VS Code Dev Containers.
# The base image runs as UID/GID 1000 but has no passwd entry, which the
# VS Code server needs. Same idea as the upstream devcontainer image
# (IIC-OSIC-TOOLS/_build/devcontainer/image), but keeping /headless as home
# so the image's tool configs (.bashrc, .magicrc, .klayout, ...) still apply.
FROM hpretl/iic-osic-tools:latest
USER root
RUN groupadd -g 1000 designer && \
    useradd -u 1000 -g 1000 -d /headless -M -s /bin/bash designer
USER designer
