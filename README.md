build FPM as a pre-req, then it will use the fpm container to package munge and 
slurm for ubuntu

```
cd fpm
make docker-release-everything
docker tag fpm ghcr.io/solocation/ghcr.io:1.15.1
```

do the munge and slurm build and packaging, build.sh will make a build container, build those from source, and copy the named files out of the build container afterwards

```
cd slurm
./build.sh munge_0.5.16_amd64.deb slurm_24.05.3_amd64.deb
```
