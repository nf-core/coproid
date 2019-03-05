FROM continuumio/miniconda3

LABEL description="Docker image containing all requirements for coproID pipeline"
COPY conda_env.yaml /
RUN conda env create -f /conda_env.yaml && conda clean -a
ENV PATH /opt/conda/envs/coproid/bin:$PATH