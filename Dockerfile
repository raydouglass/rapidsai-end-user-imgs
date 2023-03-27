# syntax=docker/dockerfile:1

ARG CUDA_VER=11.8.0
ARG PYTHON_VER=3.10
ARG LINUX_VER=ubuntu22.04

ARG RAPIDS_VER=23.04
ARG DASK_SQL_VER=2023.2.0

ARG BASE_FROM_IMAGE=rapidsai/mambaforge-cuda

# Gather dependency information
FROM rapidsai/ci:latest AS dependencies
ARG CUDA_VER
ARG PYTHON_VER

ARG RAPIDS_VER

ARG RAPIDS_BRANCH="branch-${RAPIDS_VER}"

RUN pip install --upgrade conda-merge rapids-dependency-file-generator

COPY notebooks.sh /notebooks.sh

RUN /notebooks.sh


# Base image
FROM ${BASE_FROM_IMAGE}:cuda${CUDA_VER}-base-${LINUX_VER}-py${PYTHON_VER} as base
ARG CUDA_VER
ARG PYTHON_VER

ARG RAPIDS_VER
ARG DASK_SQL_VER

USER rapids

WORKDIR /home/rapids

COPY condarc /opt/conda/.condarc

# CI should handle modifying this file instead of the dockerfile
# RUN if [ "${RAPIDS_BRANCH}" = "main" ]; then sed -i '/nightly/d;/dask\/label\/dev/d' /opt/conda/.condarc; fi

RUN --mount=type=cache,target=/opt/conda/pkgs \
    mamba install -y -n base \
        "rapids=${RAPIDS_VER}.*" \
        "dask-sql=${DASK_SQL_VER%.*}.*" \
        "python=${PYTHON_VER}.*" \
        # Strip the patch version of CUDA_VER
        "cudatoolkit=${CUDA_VER%.*}.*" \
        ipython

CMD ["ipython"]


# Runtime image
FROM base as runtime

USER rapids

WORKDIR /home/rapids

COPY --from=dependencies --chown=rapids /test_notebooks_dependencies.yaml test_notebooks_dependencies.yaml

RUN --mount=type=cache,target=/opt/conda/pkgs \
    mamba env update -n base -f test_notebooks_dependencies.yaml

RUN --mount=type=cache,target=/opt/conda/pkgs \
    mamba install -y -n base \
        jupyterlab \
        dask-labextension \
        jupyterlab-nvdashboard

COPY --from=dependencies --chown=rapids /notebooks /home/rapids/notebooks

ENV DASK_LABEXTENSION__FACTORY__MODULE="dask_cuda"
ENV DASK_LABEXTENSION__FACTORY__CLASS="LocalCUDACluster"

EXPOSE 8888

CMD ["jupyter-lab", "--allow-root", "--notebook-dir=/home/rapids/notebooks", "--ip=0.0.0.0", "--no-browser", "--NotebookApp.token=''", "--NotebookApp.allow_origin='*'"]