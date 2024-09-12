## Container to throw an error if called with a bare `docker build .`
FROM scratch AS error
RUN <<EOF
  printf '\n\n\n%s\n\n\n' "Hey! Use buildkit. See the Makefile or docs"
  false
EOF


## Build munge
FROM ubuntu:20.04 AS mungebuilder
ARG MUNGE_RELEASE_FILE=munge-0.5.16/munge-0.5.16.tar.xz.asc
SHELL [ "/bin/bash", "-c" ]
RUN <<EOF
set -eo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-suggests --no-install-recommends \
    ca-certificates \
    wget \
    build-essential \
    gnupg2
wget https://github.com/dun/munge/releases/download/${MUNGE_RELEASE_FILE}
if [[ "${MUNGE_RELEASE_FILE}" == *.asc ]]; then
    OTHER_FILE=${MUNGE_RELEASE_FILE}
    OTHER_FILE=${OTHER_FILE%.asc}
    wget https://github.com/dun/munge/releases/download/${OTHER_FILE}
    gpg --fetch-keys https://github.com/dun.gpg
    gpg --verify ${MUNGE_RELEASE_FILE##*/} ${OTHER_FILE##*/}
    MUNGE_RELEASE_FILE=${OTHER_FILE}
fi
apt-get install -y --no-install-suggests --no-install-recommends \
    libssl-dev \
    libbz2-dev \
    bzip2 \
    pkg-config \
    zlib1g-dev
MUNGE_RELEASE_FILE=${MUNGE_RELEASE_FILE##*/}
MUNGE_RELEASE_FILE=${MUNGE_RELEASE_FILE%.asc}
mkdir src/
tar -C src/ -xaf $MUNGE_RELEASE_FILE
cd src/*/
./configure --prefix=''
make
# make check        # TODO munge tests way broken :C
make install DESTDIR=/tmp/munge-install
EOF


## Package up the munge and slurm contents
FROM ghcr.io/solocation/fpm:1.15.1 AS mungepackager
ARG MUNGE_VERSION=0.5.16
USER root
SHELL [ "/bin/bash", "-c" ]
COPY --from=mungebuilder /tmp/munge-install /tmp/munge-install
RUN <<EOF
set -eo pipefail
id
mkdir /out
cd /out
munge_0ver=${MUNGE_VERSION#*.} 
munge_0ver=${munge_0ver%%.*}
fpm -s dir -t deb -v ${MUNGE_VERSION} -n munge${munge_0ver} -d 'munge authentication utility' --prefix=/tmp/munge-install -C /tmp/munge-install .
EOF


## Build slurm
FROM ubuntu:20.04 AS slurmbuilder
ARG SLURM_RELEASE_URL=https://download.schedmd.com/slurm/slurm-24.05.3.tar.bz2
ARG SLURM_RELEASE_SHA1=8eee47b2517ee3a31d4f281de179d6a60fbdcb14
SHELL [ "/bin/bash", "-c" ]
COPY --from=mungepackager /out/ /out/
RUN <<EOF
set -eo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-suggests --no-install-recommends \
    ca-certificates \
    wget \
    build-essential \
    coreutils
wget ${SLURM_RELEASE_URL}
slurm_filename=$(basename ${SLURM_RELEASE_URL})
apt-get install -y --no-install-suggests --no-install-recommends \
    libssl-dev \
    libbz2-dev \
    bzip2 \
    pkg-config \
    zlib1g-dev \
    python3
dpkg -i /out/*.deb
mkdir src/
tar -C src/ -xaf $slurm_filename
cd src/*/
./configure --prefix=''
make
# make check        # TODO munge tests way broken :C
make install DESTDIR=/tmp/slurm-install
EOF


## Package up the installed contents
FROM ghcr.io/solocation/fpm:1.15.1 AS slurmpackager
ARG SLURM_VERSION=24.05.3
USER root
SHELL [ "/bin/bash", "-c" ]
COPY --from=slurmbuilder /tmp/slurm-install /tmp/slurm-install
RUN <<EOF
set -eo pipefail
id
mkdir /out
cd /out
fpm -s dir -t deb -v ${SLURM_VERSION} -n slurm${SLURM_VERSION%%.*} -d 'slurm HPC workload manager and scheduler' -C /tmp/slurm-install .
EOF


FROM alpine AS output
COPY --from=mungepackager /out/ /out/
COPY --from=slurmpackager /out/ /out/
RUN <<EOF
ls /out/
EOF
