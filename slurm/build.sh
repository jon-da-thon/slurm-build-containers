#!/bin/bash

set -eo pipefail

DOCKER_BUILDKIT=1 docker build -t slurmbuilder .
id=$(docker create slurmbuilder)
src_filenames=$(docker export $id | tar -t  | grep -E '^out/.*deb')
for src_filename in $src_filenames; do
  dst_filename=$(basename $src_filename)
  docker cp $id:$src_filename $dst_filename
done
docker rm $id
