FROM nfcore/base
LABEL authors="Maxime Borry" \
    description="Docker image containing all requirements for nf-core/coproid pipeline"

COPY environment.yml /
RUN conda env create -f /environment.yml && conda clean -a
ENV PATH /opt/conda/envs/nf-core-coproid-1.1dev/bin:$PATH
