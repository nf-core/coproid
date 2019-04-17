FROM nfcore/base

ENV env_file environment.yml
ENV env_name coproid

LABEL description="Docker image containing all requirements for coproID pipeline"
COPY ${env_file} /
RUN conda env create -f ${env_file} && conda clean -a
ENV PATH /opt/conda/envs/${env_name}/bin:$PATH