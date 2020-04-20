FROM nfcore/base:1.9
LABEL authors="Maxime Borry" \
    description="Docker image containing all software requirements for the nf-core/coproid pipeline"

# Install the conda environment
COPY environment.yml /
RUN conda env create -f /environment.yml && conda clean -a
RUN conda env export --name nf-core-coproid-1.1dev > nf-core-coproid-1.1dev.yml
ENV PATH /opt/conda/envs/nf-core-coproid-1.1dev/bin:$PATH

# Dump the details of the installed packages to a file for posterity
RUN conda env export --name nf-core-coproid-1.1dev > nf-core-coproid-1.1dev.yml

# Numba cache dir patch
ENV NUMBA_CACHE_DIR /tmp
ENV HOME /tmp
