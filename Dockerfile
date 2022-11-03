FROM condaforge/mambaforge
LABEL authors="Maxime Borry" \
    description="Docker image containing all software requirements for the nf-core/coproid pipeline"

# Install the conda environment
COPY environment.yml /
RUN mamba env create -f /environment.yml && mamba clean -a
RUN mamba env export --name nf-core-coproid-1.1.1 > nf-core-coproid-1.1.1.yml
ENV PATH /opt/conda/envs/nf-core-coproid-1.1.1/bin:$PATH

# Numba cache dir patch
ENV NUMBA_CACHE_DIR /tmp
ENV HOME /tmp
