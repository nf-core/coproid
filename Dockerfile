FROM nfcore/base

LABEL description="Docker image containing all requirements for coproID pipeline"
COPY environment.yml /
RUN apt-get update && apt-get -y install procps
RUN conda env create -f /environment.yml && conda clean -a
ENV PATH /opt/conda/envs/nf-core-coproid-1.0dev/bin:$PATH