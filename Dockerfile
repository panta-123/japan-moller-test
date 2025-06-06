FROM almalinux:9 AS build

# Install JLab CA cert
ADD http://pki.jlab.org/JLabCA.crt /etc/pki/ca-trust/source/anchors/
RUN update-ca-trust

# Install build tools and dependencies
RUN dnf update -y && \
    dnf -y install epel-release dnf-plugins-core 'dnf-command(config-manager)' && \
    dnf config-manager --set-enabled crb && \
    dnf install -y --setopt=install_weak_deps=False \
    wget cmake gcc gcc-c++ git binutils make \
    openssl-devel libX11-devel libXt-devel libXpm-devel \
    boost-devel mariadb-server mariadb-connector-c-devel \
    python3 python3-pip tbb-devel libuv-devel giflib-devel \
    root root-python3 root-mathcore root-montecarlo-eg \
    root-mathmore root-gui root-hist root-physics root-genvector && \
    dnf clean all && rm -rf /var/cache/yum/*

# Environment variables
ENV JAPAN_MOLLER_HOME=/opt/japan-moller
ENV QW_PRMINPUT=$JAPAN_MOLLER_HOME/Parity/prminput
ENV PATH=$JAPAN_MOLLER_HOME/bin:$PATH
ENV LD_LIBRARY_PATH=$JAPAN_MOLLER_HOME/lib:$JAPAN_MOLLER_HOME/lib64:$LD_LIBRARY_PATH
ENV QWANALYSIS=/japan-MOLLER

# Copy and build the software in image
COPY . /japan-MOLLER
ENV JAPAN_MOLLER=/japan-MOLLER
RUN mkdir -p /japan-MOLLER/build && \
    cd /japan-MOLLER/build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=$JAPAN_MOLLER_HOME && \
    make -j$(nproc) && \
    make install

# Optional: keep build artifacts for debugging
# Comment this out when we are ready for maturity
# RUN rm -rf /japan-MOLLER

# Entrypoint: allow override via volumes
RUN echo '#!/bin/bash' > /usr/local/bin/entrypoint.sh && \
    echo 'unset OSRELEASE' >> /usr/local/bin/entrypoint.sh && \
    echo 'export PATH=$JAPAN_MOLLER_HOME/bin:$PATH' >> /usr/local/bin/entrypoint.sh && \
    echo 'export LD_LIBRARY_PATH=$JAPAN_MOLLER_HOME/lib64:$JAPAN_MOLLER_HOME/lib:$LD_LIBRARY_PATH' >> /usr/local/bin/entrypoint.sh && \
    echo 'export QW_PRMINPUT=$JAPAN_MOLLER_HOME/Parity/prminput' && \
    echo 'export QWANALYSIS=$JAPAN_MOLLER'>> /usr/local/bin/entrypoint.sh && \
    echo 'exec "$@"' >> /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
WORKDIR /work
CMD ["/bin/bash"]
