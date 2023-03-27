# RAPIDS end-user images overhaul

See https://github.com/rapidsai/docker/issues/539

## Building

First, checkout and build this PR: https://github.com/rapidsai/mambaforge-cuda/pull/26

```
docker buildx build -f Dockerfile -t rapidsai/mambaforge-cuda-pr26:cuda11.8.0-base-ubuntu22.04-py3.10 --build-arg CUDA_VER=11.8.0 --build-arg LINUX_VER=ubuntu22.04 --build-arg PYTHON_VER=3.10 .
```

Then you can build the Dockerfile in this repo:
```
docker buildx build -f Dockerfile -t rapidsai/end-user-img-runtime --progress plain --build-arg BASE_FROM_IMAGE=rapidsai/mambaforge-cuda-pr26 context/
```